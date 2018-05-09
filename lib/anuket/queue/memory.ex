defmodule Anuket.Queue.Memory do
  defstruct queue: :queue.new(),
            demand: 0

  def new(_) do
    %__MODULE__{}
  end

  defimpl Anuket.Queue do
    def push(%{queue: queue, demand: demand}, event) do
      queue = :queue.in(event, queue)

      dispatch_events(queue, demand, [])
    end

    def handle_demand(%{queue: queue, demand: prev_demand}, demand) do
      dispatch_events(queue, prev_demand + demand, [])
    end

    def handle_info(state, _message) do
      {[], state}
    end

    defp dispatch_events(queue, 0, events) do
      {Enum.reverse(events), %@for{queue: queue, demand: 0}}
    end

    defp dispatch_events(queue, demand, events) do
      case :queue.out(queue) do
        {{:value, event}, queue} ->
          dispatch_events(queue, demand - 1, [{event, fn _ -> :ok end} | events])

        {:empty, queue} ->
          {Enum.reverse(events), %@for{queue: queue, demand: demand}}
      end
    end
  end
end
