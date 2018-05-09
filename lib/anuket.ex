defmodule Anuket do
  def child_spec(file) do
    import Supervisor.Spec

    config = Anuket.Config.read!(file)

    sinks = config[:sinks]
    sources = config[:sources]
    pipes = config[:pipes]
    job_queue = config[:job_queue]

    Enum.concat([
      [worker(Anuket.Job.Queue, [sinks, job_queue])],
      for {name, source} <- sources do
        worker(Anuket.Source.Producer, [name, source], id: name)
      end,
      for {name, pipe} <- pipes do
        worker(Anuket.Pipe, [name, pipe], id: name)
      end,
      for {name, sink} <- sinks do
        worker(Anuket.Job.Consumer, [name, sink], id: name)
      end
    ])
  end

  def start_link(file) do
    file
    |> child_spec()
    |> Supervisor.start_link(strategy: :one_for_one)
  end
end
