defmodule Anuket.Job.Queue do
  use GenStage
  require Logger

  def start_link(sinks, config) do
    GenStage.start_link(__MODULE__, {sinks, config}, name: __MODULE__)
  end

  def invoke(name, params, timeout \\ :infinity) do
    Logger.debug("JOB invoke: #{inspect(name)} #{inspect(params)}")
    GenStage.call(__MODULE__, {:invoke, name, params}, timeout)
  end

  def init({sinks, config}) do
    backend = init_config(config)

    mapping =
      Stream.map(sinks, fn {name, sink} ->
        {name,
         %{
           name: name,
           params: sink[:params]
         }}
      end)

    mapping =
      Stream.concat(
        mapping,
        Stream.map(mapping, fn {name, sink} ->
          {to_string(name), sink}
        end)
      )

    {:producer, {Enum.into(mapping, %{}), backend},
     dispatcher: {
       GenStage.PartitionDispatcher,
       partitions: Keyword.keys(sinks), hash: & &1
     }}
  end

  defp init_config(config) do
    backend = Keyword.fetch!(config, :backend)

    config
    |> Keyword.delete(:backend)
    |> backend.new()
  end

  def handle_demand(demand, {sinks, backend}) do
    {events, backend} = Anuket.Queue.handle_demand(backend, demand)
    events = Enum.map(events, &process_event(&1, sinks))
    {:noreply, events, {sinks, backend}}
  end

  def handle_info(message, {sinks, backend}) do
    {events, backend} = Anuket.Queue.handle_info(backend, message)
    events = Enum.map(events, &process_event(&1, sinks))
    {:noreply, events, {sinks, backend}}
  end

  def handle_call({:invoke, name, params}, _from, {sinks, backend}) do
    case Map.fetch(sinks, name) do
      {:ok, sink} ->
        params = validate_params(params, sink[:params])
        {events, backend} = Anuket.Queue.push(backend, %{"name" => name, "params" => params})
        events = Enum.map(events, &process_event(&1, sinks))

        {:reply, :ok, events, {sinks, backend}}

      _ ->
        {:reply, {:error, :invalid_name}, [], {sinks, backend}}
    end
  rescue
    KeyError ->
      {:reply, {:error, :invalid_params}, [], {sinks, backend}}
  end

  defp validate_params(params, validations) do
    Enum.reduce(validations, %{}, fn {from, to}, acc ->
      value = Map.get_lazy(params, to, fn -> Map.fetch!(params, from) end)
      Map.put(acc, to, value)
    end)
  end

  defp process_event({%{"name" => name, "params" => params}, receipt}, sinks) do
    %{name: name, params: validations} = Map.fetch!(sinks, name)
    params = validate_params(params, validations)
    {{params, receipt}, name}
  end
end
