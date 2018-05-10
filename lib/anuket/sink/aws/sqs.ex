defmodule Anuket.Sink.AWS.SQS do
  def new(opts) do
    Anuket.Queue.SQS.new(opts)
  end
end

defimpl Anuket.Sink, for: Anuket.Queue.SQS do
  def run(queue, message) do
    Anuket.Queue.push(queue, message)
    :ok
  end
end
