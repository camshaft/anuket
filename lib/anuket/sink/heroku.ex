defmodule Anuket.Sink.Heroku do
  use HTTPoison.Base

  @endpoint "https://api.heroku.com"

  def process_url(url) do
    @endpoint <> url
  end

  def process_request_headers(headers) do
    token = Confex.fetch_env!(:anuket, :heroku_api_token)

    [
      {"authorization", "Bearer #{token}"},
      {"content-type", "application/json"},
      {"accept", "application/vnd.heroku+json; version=3"}
      | headers
    ]
  end

  def process_request_body(body) when is_map(body) do
    Poison.encode!(body)
  end

  def process_request_body(body) do
    body
  end

  def process_response_body(body) do
    Poison.decode!(body)
  end
end
