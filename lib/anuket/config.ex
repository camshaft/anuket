defmodule Anuket.Config do
  defmacro __using__(_opts) do
    quote do
      use Mix.Config
      import unquote(__MODULE__), only: [source: 2, sink: 2, pipe: 2, job_queue: 1]
    end
  end

  def read!(file) do
    file
    |> Mix.Config.read!()
    |> Enum.into(%{
      job_queue: Confex.get_env(:anuket, :job_queue, backend: Anuket.Queue.Memory)
    })
  end

  defmacro sink(name, args) do
    quote do
      config :sinks, unquote(name), Anuket.Config.verify_sink(unquote(args))
    end
  end

  def verify_sink(args) do
    params = args[:params] || []

    mapping =
      params
      |> Stream.map(fn name when is_atom(name) ->
        {to_string(name), name}
      end)
      |> Enum.into(%{})

    put_in(args[:params], mapping)
  end

  defmacro pipe(name, args) do
    quote do
      config :pipes, unquote(name), Anuket.Config.verify_pipe(unquote(args))
    end
  end

  def verify_pipe(args) do
    # TODO
    args
  end

  defmacro source(name, args) do
    quote do
      config :sources, unquote(name), Anuket.Config.verify_source(unquote(args))
    end
  end

  def verify_source(args) do
    # TODO
    args
  end

  defmacro job_queue(args) do
    quote do
      config :job_queue, unquote(args)
    end
  end
end
