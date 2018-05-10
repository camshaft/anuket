defmodule Anuket.Job.Queue do
  use GenStage
  require Logger

  def start_link(sinks, config) do
    GenStage.start_link(__MODULE__, {sinks, config}, name: __MODULE__)
  end

  def invoke(name, params) do
    Logger.debug("JOB invoke: #{inspect(name)} #{inspect(params)}")

    case :ets.lookup(__MODULE__, name) do
      [{_, sink}] ->
        params = validate_params(params, sink[:params])
        GenStage.cast(__MODULE__, {:invoke, name, params})
        :ok

      _ ->
        {:error, {:invalid_job, name}}
    end
  rescue
    err in KeyError ->
      {:error, err}
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

    table = :ets.new(__MODULE__, [:protected, :named_table, {:read_concurrency, true}])

    :ets.insert(table, Enum.to_list(mapping))

    {:producer, backend,
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

  def handle_demand(demand, backend) do
    {events, backend} = Anuket.Queue.handle_demand(backend, demand)
    events = Enum.map(events, &process_event(&1))
    {:noreply, events, backend}
  end

  def handle_info(message, backend) do
    {events, backend} = Anuket.Queue.handle_info(backend, message)
    events = Enum.map(events, &process_event(&1))
    {:noreply, events, backend}
  end

  def handle_cast({:invoke, name, params}, backend) do
    backend = Anuket.Queue.push(backend, %{"name" => name, "params" => params})

    {:reply, :ok, [], backend}
  end

  defp validate_params(params, validations) do
    Enum.reduce(validations, %{}, fn {from, to}, acc ->
      value = Map.get_lazy(params, to, fn -> Map.fetch!(params, from) end)
      Map.put(acc, to, value)
    end)
  end

  defp process_event({%{"name" => name, "params" => params}, receipt}) do
    [%{name: name, params: validations}] = :ets.lookup(__MODULE__, name)
    params = validate_params(params, validations)
    {{params, receipt}, name}
  end
end
