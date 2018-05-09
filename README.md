# anuket

Simple data processing pipeline

## Installation

```elixir
def deps do
  [
    {:anuket, "~> 0.1.0"}
  ]
end
```

## Usage

```elixir
use Anuket.Config

job :enrich,
  params: [:in, :out],
  target: Anuket.Target.Heroku.OneOff.new(%{
    app: "my-app",
    command: "./enrich %in %out"
  })

watch "collector/**",
  invoke: :enrich,
  params: %{
    in: &Map.get(&1, :file),
    out: fn(%{file: "collector/" <> file}) -> "enrich/#{file}" end
  }
```
