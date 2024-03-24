defmodule Ueberauth.Strategy.Patreon do
  @moduledoc """
  Provides an Ueberauth strategy for authenticating with Patreon.

  ### Setup

  Create an application in Patreon for you to use.

  Register a new application at: [patreon dev portal](https://www.patreon.com/portal/registration/register-clients) and get the `client_id` and `client_secret`.

  Include the provider in your configuration for Ueberauth, provide a lost of scopes you want to request from the user using the `default_scope`.

      config :ueberauth, Ueberauth,
        providers: [
          patreon: { Ueberauth.Strategy.Patreon, [default_scope: "identity[email] identity"]] }
        ]

  Then include the configuration for twitch.

      config :ueberauth, Ueberauth.Strategy.Patreon.OAuth,
        client_id: System.get_env("PATREON_CLIENT_ID"),
        client_secret: System.get_env("PATREON_CLIENT_SECRET")

  If you haven't already, create a pipeline and setup routes for the callback handler to receive the credentials.

      pipeline :browser do
        plug Ueberauth
        ...
    end

      scope "/auth", MyApp do
        pipe_through :browser

        get "/:provider", AuthController, :request
        get "/:provider/callback", AuthController, :callback
      end


  Create the controller for the callback where you will handle the `Ueberauth.Auth` struct

      defmodule MyApp.AuthController do
        use MyApp.Web, :controller

        def callback_phase(%{ assigns: %{ ueberauth_failure: fails } } = conn, _params) do
          # do things with the failure
        end

        def callback_phase(%{ assigns: %{ ueberauth_auth: auth } } = conn, params) do
          # do things with the auth, like create the user or log them in
        end
      end

  """

  use Ueberauth.Strategy,
    oauth2_module: Ueberauth.Strategy.Patreon.OAuth

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles the initial redirect to the patreon authentication page.

  To customize the scope (permissions) that are requested by patreon include
  them as part of your url:

      "https://www.patreon.com/oauth2/authorize"
  """
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)

    params =
      [scope: scopes]
      |> with_state_param(conn)

    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [params]))
  end

  @doc """
  Handles the callback from Patreon.

  When there is a failure from Patreon the failure is included in the
  `ueberauth_failure` struct. Otherwise the information returned from Patreon is
  returned in the `Ueberauth.Auth` struct.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    module = option(conn, :oauth2_module)
    token = apply(module, :get_token!, [[code: code]])

    if token.access_token == nil do
      set_errors!(conn, [
        error(token.other_params["error"], token.other_params["error_description"])
      ])
    else
      fetch_user(conn, token)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc """
  Cleans up the private area of the connection used for passing the raw Notion
  response around during the callback.
  """
  def handle_cleanup!(conn) do
    conn
    |> put_private(:patreon_token, nil)
    |> put_private(:patreon_user, nil)
  end

  @doc """
  Fetches the uid field from the Patreon response. This defaults to the option `uid_field` which in-turn defaults to `id`
  """
  def uid(conn) do
    %{"data" => user} = conn.private.patreon_user
    user["id"]
  end

  @doc """
  Includes the credentials from the Patreon response.
  """
  def credentials(conn) do
    token = conn.private.patreon_token

    %Credentials{
      token: token.access_token,
      token_type: token.token_type,
      refresh_token: token.refresh_token,
      expires_at: token.expires_in,
      scopes: token.scope
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth`
  struct.
  """
  def info(conn) do
    %{
      "data" => %{
        "attributes" => %{
          "full_name" => full_name,
          "first_name" => first_name,
          "last_name" => last_name,
          "about" => about,
          "image_url" => image_url,
          "url" => url,
          "email" => email
        }
      }
    } = conn.private.patreon_user

    %Info{
      email: email,
      name: full_name,
      first_name: first_name,
      last_name: last_name,
      description: about,
      image: image_url,
      urls: %{
        profile: url
      }
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the Patreon
  callback.
  """
  def extra(conn) do
    %Extra{
      raw_info: conn.private.patreon_user
    }
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :patreon_token, token)

    case Ueberauth.Strategy.Patreon.OAuth.get(
           token.access_token,
           "https://www.patreon.com/api/oauth2/v2/identity?fields%5Buser%5D=full_name,email,first_name,last_name,about,image_url,url"
         ) do
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])

      {:ok, %OAuth2.Response{status_code: status_code, body: user}}
      when status_code in 200..399 ->
        put_private(conn, :patreon_user, user)

      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])

      {:error, %OAuth2.Response{body: %{"message" => reason}}} ->
        set_errors!(conn, [error("OAuth2", reason)])

      {:error, _} ->
        set_errors!(conn, [error("OAuth2", "uknown error")])
    end
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end
end
