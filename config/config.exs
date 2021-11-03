# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :united,
  ecto_repos: [United.Repo]

# Configures the endpoint
config :united, UnitedWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "IdcF5HXBHZs3Vi9wXjCqqBYOJFTha3/nNYlRgtNMTtsWVZT69I/26G90KnUAqh05",
  render_errors: [view: UnitedWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: United.PubSub,
  live_view: [signing_salt: "OuHuDKgj"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"


config :blue_potion,
  otp_app: "United",
  repo: United.Repo,
  contexts: ["Settings"],
  project: %{name: "United", alias_name: "united", vsn: "0.1.0"},
  server: %{
    url: "139.162.29.108",
    db_url: "127.0.0.1",
    username: "ubuntu",
    key: System.get_env("SERVER_KEY"),
    domain_name: "localhost"
  }
