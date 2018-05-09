defmodule Anuket.Server do
  use Plug.Router

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["text/*"],
    json_decoder: Poison
  )

  plug(:match)
  plug(:dispatch)

  def child_spec() do
    port = Confex.fetch_env!(:anuket, :port)
    Plug.Adapters.Cowboy2.child_spec(scheme: :http, plug: __MODULE__, options: [port: port])
  end

  post "/invoke/:endpoint" do
    endpoint
    |> Anuket.Job.Queue.invoke(conn.body_params)
    |> case do
      :ok ->
        send_resp(conn, 200, "ok")

      {:error, error} ->
        send_resp(conn, 400, inspect(error))
    end
  end
end
