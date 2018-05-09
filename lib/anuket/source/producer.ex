defmodule Anuket.Source.Producer do
  use GenStage
  require Logger

  def start_link(name, config) do
    GenStage.start_link(__MODULE__, {name, config[:source]}, name: name)
  end

  def init({name, source}) do
    state = Anuket.Source.init(source)
    Logger.debug("SOURCE init: #{inspect(name)}")
    {:producer, {name, state}, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_demand(demand, {name, state}) do
    Logger.debug("SOURCE handle_demand: #{inspect(name)} #{inspect(demand)}")
    {events, state} = Anuket.Source.handle_demand(state, demand)
    {:noreply, events, {name, state}}
  end

  def handle_info(message, {name, state}) do
    Logger.debug("SOURCE handle_info: #{inspect(name)} #{inspect(message)}")
    {events, state} = Anuket.Source.handle_info(state, message)
    {:noreply, events, {name, state}}
  end
end
