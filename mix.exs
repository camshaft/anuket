defmodule Anuket.MixProject do
  use Mix.Project

  def project do
    [
      app: :anuket,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      env: [
        port: {:system, :integer, "PORT", 5000},
        job_queue: [backend: Anuket.Queue.Memory],
        heroku_api_token: {:system, "HEROKU_API_KEY"}
      ]
    ]
  end

  defp deps do
    [
      {:ex_aws, "~> 2.0"},
      {:ex_aws_sqs, "~> 2.0"},
      {:httpoison, "~> 1.0"},
      {:poison, "~> 3.0"},
      {:plug, "~> 1.5"},
      {:cowboy, "~> 2.0"},
      {:hackney, "~> 1.9"},
      {:sweet_xml, "~> 0.6"},
      {:gen_stage, "~> 0.13.0"},
      {:confex, "~> 3.3"},
      {:rl, ">= 0.0.0", only: :dev}
    ]
  end
end
