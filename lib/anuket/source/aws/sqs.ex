defmodule Anuket.Source.AWS.SQS do
  def new(opts) do
    Anuket.Queue.SQS.new(opts)
  end
end

defimpl Anuket.Source, for: Anuket.Queue.SQS do
  def init(queue) do
    queue
  end

  def handle_demand(queue, demand) do
    Anuket.Queue.handle_demand(queue, demand)
  end

  def handle_info(queue, message) do
    Anuket.Queue.handle_info(queue, message)
  end
end
