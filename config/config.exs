use Mix.Config

config :anuket, :job_queue, backend: Anuket.Queue.Memory
config :anuket, :heroku_api_token, {:system, "HEROKU_API_TOKEN"}
