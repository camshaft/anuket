defmodule Anuket.Pipe do
  use ConsumerSupervisor
  alias Anuket.Job.Queue
  require Logger

  def start_link(name, pipe) do
    GenStage.start_link(__MODULE__, {name, pipe}, name: name)
  end

  def init({name, pipe}) do
    Logger.debug("PIPE init: #{inspect(name)}")
    max_demand = pipe[:max_demand] || 10
    selector = pipe[:filter] || fn _ -> true end
    selector = &selector.(elem(&1, 0))

    {:consumer, {name, pipe},
     subscribe_to: [{pipe[:source], max_demand: max_demand, selector: selector}]}
  end

  def handle_events(events, _from, {name, pipe} = state) do
    for {event, receipt} <- events do
      Logger.debug("PIPE handle_event: #{inspect(name)} #{inspect(event)}")
      params = event |> into_params(pipe[:params])

      case Queue.invoke(pipe[:sink], params) do
        :ok ->
          receipt.(:ok)
          :ok

        {:error, error} ->
          Logger.debug("PIPE error: #{inspect(name)} #{inspect(error)}")
      end
    end

    {:noreply, [], state}
  end

  defp into_params(event, params) do
    params
    |> Stream.map(fn {name, map} ->
      {name, map.(event)}
    end)
    |> Enum.into(%{})
  end
end
