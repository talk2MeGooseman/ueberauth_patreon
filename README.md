# Überauth Patreon

[![Hex Version](https://img.shields.io/hexpm/v/ueberauth_patreon.svg)](https://hex.pm/packages/ueberauth_patreon)

> Patreon OAuth2 strategy for Überauth.

## Installation

1. Setup your application in Patreon Development Dashboard https://www.patreon.com/portal/registration/register-clients

1. Add `:ueberauth_patreon` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_patreon, "~> 1.0"}]
    end
    ```

1. Add Patreon to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        patreon: {Ueberauth.Strategy.Patreon, , [default_scope: "users pledges-to-me my-campaigns identity[email] identity"]},
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Patreon.OAuth,
      client_id: System.get_env("PATREON_CLIENT_ID"),
      client_secret: System.get_env("PATREON_CLIENT_SECRET"),
      redirect_uri: System.get_env("PATREON_REDIRECT_URI")
    ```

1.  Include the Überauth plug in your router pipeline:

    ```elixir
    defmodule TestPatreonWeb.Router do
      use TestPatreonWeb, :router

      pipeline :browser do
        plug Ueberauth
        ...
       end
    end
    ```

1.  Add the request and callback routes:

    ```elixir
    scope "/auth", TestPatreonWeb do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. Create a new controller or use an existing controller that implements callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses from Patreon.

    ```elixir
      defmodule TestPatreonWeb.AuthController do
        use TestPatreonWeb, :controller

        def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
          Logger.debug(_fails)
          conn
          |> put_flash(:error, "Failed to authenticate.")
          |> redirect(to: "/")
        end

        def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
          case UserFromAuth.find_or_create(auth) do
            {:ok, user} ->
              conn
              |> put_flash(:info, "Successfully authenticated.")
              |> put_session(:current_user, user)
              |> configure_session(renew: true)
              |> redirect(to: "/")

            {:error, reason} ->
              conn
              |> put_flash(:error, reason)
              |> redirect(to: "/")
          end
        end
      end
    ```

## Calling

Once your setup, you can initiate auth using the following URL, unless you changed the routes from the guide:

    /auth/patreon

## Documentation

The docs can be found at [ueberauth_patreon][package-docs] on [Hex Docs][hex-docs].

[hex-docs]: https://hexdocs.pm
[package-docs]: https://hexdocs.pm/ueberauth_patreon
