use Mix.Config

config :herenow,
  ecto_repos: [Herenow.Repo],
  # 2 hours in seconds: 2 * 60 * 60
  account_activation_expiration_time: 7200,
  login_activation_expiration_time: 7200,
  password_recovery_expiration_time: 7200

config :herenow, HerenowWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: HerenowWeb.ErrorView, accepts: ~w(json)]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :format_encoders, json: Jason

config :ecto, json_library: Jason

config :herenow, Herenow.Repo, types: Herenow.PostgresTypes

config :elastix, json_codec: Jason

import_config "#{Mix.env()}.exs"
