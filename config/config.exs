# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :fly,
  ecto_repos: [Fly.Repo]

# Configures the endpoint
config :fly, FlyWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: FlyWeb.ErrorHTML, json: FlyWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Fly.PubSub,
  live_view: [signing_salt: "AwM9jJSB"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :fly, Fly.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :fly, Fly.Scheduler,
  jobs: [
    # fetch and queue due invoices every day
    {"@daily", {Fly, :fetch_and_queue_due_invoices, []}},
    # Compile usage data and generate invoices every 30 days
    {"@monthly", {Fly, :compile_and_generate_invoices, []}}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
