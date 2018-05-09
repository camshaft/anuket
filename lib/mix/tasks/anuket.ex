defmodule Mix.Tasks.Anuket do
  use Mix.Task

  @moduledoc """
  Start the anuket server through mix
  """

  @preferred_cli_env :prod

  def run([name]) do
    Application.ensure_all_started(:anuket)
    Anuket.start_link(name)
  end
end
