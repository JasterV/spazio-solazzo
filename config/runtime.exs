import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/spazio_solazzo start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :spazio_solazzo, SpazioSolazzoWeb.Endpoint, server: true
end

port = String.to_integer(System.get_env("PORT", "8080"))

if config_env() != :prod do
  config :spazio_solazzo, SpazioSolazzoWeb.Endpoint, http: [port: port]
else
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: [:inet]

  config :spazio_solazzo, SpazioSolazzo.Repo,
    url: database_url,
    ssl: true,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "4"),
    # For machines with several cores, consider starting multiple pools of `pool_size`
    # pool_count: 4,
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host =
    System.get_env("PHX_HOST") ||
      raise "Missing environment variable `PHX_HOST`!"

  config :spazio_solazzo, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :spazio_solazzo, SpazioSolazzoWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0},
      port: port
    ],
    server: true,
    secret_key_base: secret_key_base

  config :spazio_solazzo, SpazioSolazzo.Mailer,
    adapter: Resend.Swoosh.Adapter,
    api_key:
      System.get_env("RESEND_API_KEY") ||
        raise("""
          Missing environment variable `RESEND_API_KEY`!.
        """)

  config :spazio_solazzo,
    token_signing_secret:
      System.get_env("TOKEN_SIGNING_SECRET") ||
        raise("Missing environment variable `TOKEN_SIGNING_SECRET`!"),
    booking_token_signing_secret:
      System.get_env("TOKEN_SIGNING_SECRET") ||
        raise("Missing environment variable `TOKEN_SIGNING_SECRET`!"),
    admin_email:
      System.get_env("ADMIN_EMAIL") ||
        raise("Missing environment variable `ADMIN_EMAIL`!"),
    spazio_solazzo_email:
      System.get_env("SPAZIO_SOLAZZO_EMAIL") ||
        raise("Missing environment variable `SPAZIO_SOLAZZO_EMAIL`!"),
    front_office_phone_number:
      System.get_env("FRONT_OFFICE_PHONE_NUMBER") ||
        raise("Missing environment variable `FRONT_OFFICE_PHONE_NUMBER`!"),
    base_url: "https://#{host}:#{port}"

  # Most non-SMTP adapters require an API client. Swoosh supports Req, Hackney,
  # and Finch out-of-the-box. This configuration is typically done at
  # compile-time in your config/prod.exs:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Req
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :spazio_solazzo, SpazioSolazzoWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :spazio_solazzo, SpazioSolazzoWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.
end
