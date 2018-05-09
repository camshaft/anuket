defmodule Anuket.Sink.Heroku.OneOff do
  defstruct [:app, :command, :size, :time_to_live, :type]

  def new(config) do
    config = Enum.into(config, %{})

    %__MODULE__{
      app: Map.fetch!(config, :app),
      command: Map.fetch!(config, :command),
      size: Map.get(config, :size, "standard-1X"),
      time_to_live: Map.get(config, :time_to_live, 1800),
      type: Map.get(config, :type, "run")
    }
  end

  defimpl Anuket.Sink do
    alias Anuket.Sink.Heroku

    def run(%{command: command} = config, params) do
      run(config, command, params)
    end

    defp run(config, command, params) when is_function(command) do
      run(config, command.(params), params)
    end

    defp run(%{app: app, size: size, time_to_live: time_to_live, type: type}, command, _params) do
      %{status_code: 201, body: %{"id" => id}} =
        Heroku.post!("/apps/#{app}/dynos", %{
          "attach" => false,
          "command" => command,
          # "force_no_tty" => true,
          "size" => size,
          "time_to_live" => time_to_live,
          "type" => type
        })

      poll(app, id)
    end

    defp poll(app, id) do
      :timer.sleep(10_000)

      "/apps/#{app}/dynos/#{id}"
      |> Heroku.get!()
      |> case do
        %{body: %{"state" => "up"}} ->
          poll(app, id)

        _ ->
          :ok
      end
    end
  end
end
