use Mix.Config

config :herenow, HerenowWeb.Endpoint,
  load_from_system_env: true,
  url: [scheme: "https", host: System.get_env("HOST_NAME"), port: 443],
  force_ssl: [rewrite_on: [:x_forwarded_proto]]

config :logger, level: :info

config :herenow, Herenow.Repo,
  adapter: Ecto.Adapters.Postgres,
  hostname: System.get_env("DATABASE_HOSTNAME"),
  username: System.get_env("DATABASE_USERNAME"),
  password: System.get_env("DATABASE_PASSWORD"),
  database: System.get_env("DATABASE_NAME"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  ssl: true

config :herenow,
  login_secret: System.get_env("LOGIN_SECRET"),
  account_activation_secret: System.get_env("ACCOUNT_ACTIVATION_SECRET"),
  captcha: Herenow.Captcha.HTTPAdapter,
  elastic_url: System.get_env("ELASTIC_URL")

config :recaptcha,
  public_key: System.get_env("RECAPTCHA_PUBLIC_KEY"),
  secret: System.get_env("RECAPTCHA_PRIVATE_KEY")

config :herenow, Herenow.Mailer,
  adapter: Bamboo.SendgridAdapter,
  api_key: System.get_env("SENDGRID_API_KEY")
