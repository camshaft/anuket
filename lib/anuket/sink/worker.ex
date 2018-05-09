defmodule Anuket.Sink.Worker do
  require Logger

  def start_link(sink, {params, receipt}) do
    Task.start_link(fn ->
      try do
        Anuket.Sink.run(sink[:sink], params)
      rescue
        error ->
          error = Exception.format(:error, error, System.stacktrace())
          Logger.error(error)
          {:error, error}
      catch
        kind, payload ->
          error = Exception.format(kind, payload, System.stacktrace())
          Logger.error(error)
          {:error, error}
      end
      |> receipt.()
    end)
  end
end
