defmodule Ueberauth.Strategy.Patreon.OAuth do
  @moduledoc """
  An implementation of OAuth2 for Patreon.

  To add your `:client_id` and `:client_secret` include these values in your
  configuration:

      config :ueberauth, Ueberauth.Strategy.Patreon.OAuth,
        client_id: System.get_env("PATREON_CLIENT_ID"),
        client_secret: System.get_env("PATREON_CLIENT_SECRET")

  """
  use OAuth2.Strategy

  @defaults [
    strategy: __MODULE__,
    site: "https://www.patreon.com/",
    authorize_url: "https://www.patreon.com/oauth2/authorize",
    token_url: "https://www.patreon.com/api/oauth2/token",
    token_method: :post
  ]

  @doc """
  Construct a client for requests to Patreon.

  Optionally include any OAuth2 options here to be merged with the defaults:

      Ueberauth.Strategy.Patreon.OAuth.client(
        redirect_uri: "http://localhost:4000/auth/patreon/callback"
      )

  This will be setup automatically for you in `Ueberauth.Strategy.Patreon`.

  These options are only useful for usage outside the normal callback phase of
  Ueberauth.
  """
  def client(opts \\ []) do
    config =
      :ueberauth
      |> Application.fetch_env!(Ueberauth.Strategy.Patreon.OAuth)
      |> check_credential(:client_id)
      |> check_credential(:client_secret)

    client_opts =
      @defaults
      |> Keyword.merge(config)
      |> Keyword.merge(opts)

    json_library = Ueberauth.json_library()

    OAuth2.Client.new(client_opts)
    |> OAuth2.Client.put_serializer("application/json", json_library)
    |> OAuth2.Client.put_serializer("application/vnd.api+json", json_library)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth.

  No need to call this usually.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client
    |> OAuth2.Client.authorize_url!(params)
  end

  def get(token, url, headers \\ [], opts \\ []) do
    client()
    |> put_header("authorization", "Bearer " <> token)
    |> put_header("accept", "application/json")
    |> OAuth2.Client.get(url, headers, opts)
  end

  def get_token!(params \\ [], options \\ []) do
    headers = Keyword.get(options, :headers, [])
    options = Keyword.get(options, :options, [])

    client_options = Keyword.get(options, :client_options, [])

    client = OAuth2.Client.get_token!(client(client_options), params, headers, options)

    client.token
  end

  # Strategy Callbacks
  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client =
      client
      |> put_param("grant_type", "authorization_code")
      |> put_header("Accept", "application/json")

    OAuth2.Strategy.AuthCode.get_token(client, params, headers)
  end

  defp check_credential(config, key) do
    check_config_key_exists(config, key)

    case Keyword.get(config, key) do
      value when is_binary(value) ->
        config

      {:system, env_key} ->
        case System.get_env(env_key) do
          nil ->
            raise "#{inspect(env_key)} missing from environment, expected in config :ueberauth, Ueberauth.Strategy.Patreon"

          value ->
            Keyword.put(config, key, value)
        end
    end
  end

  defp check_config_key_exists(config, key) when is_list(config) do
    unless Keyword.has_key?(config, key) do
      raise "#{inspect(key)} missing from config :ueberauth, Ueberauth.Strategy.Patreon"
    end

    config
  end

  defp check_config_key_exists(_, _) do
    raise "Config :ueberauth, Ueberauth.Strategy.Patreon is not a keyword list, as expected"
  end
end
