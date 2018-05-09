defmodule Anuket.Job.Consumer do
  use ConsumerSupervisor
  alias Anuket.{Job, Sink}

  def start_link(name, job) do
    ConsumerSupervisor.start_link(__MODULE__, {name, job}, name: name)
  end

  def init({name, job}) do
    children = [
      worker(Sink.Worker, [job], restart: :temporary)
    ]

    concurrency = job[:concurrency] || 50

    {:ok, children,
     strategy: :one_for_one,
     subscribe_to: [
       {Job.Queue, max_demand: concurrency, partition: name}
     ]}
  end
end
