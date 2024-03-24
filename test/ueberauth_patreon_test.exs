defmodule UeberauthPatreonTest do
  @moduledoc false

  use ExUnit.Case, async: false
  use Plug.Test

  import Plug.Conn

  doctest UeberauthPatreon

  def set_options(routes, conn, opt) do
    case Enum.find_index(routes, &(elem(&1, 0) == {conn.request_path, conn.method})) do
      nil ->
        routes

      idx ->
        update_in(routes, [Access.at(idx), Access.elem(1), Access.elem(2)], &%{&1 | options: opt})
    end
  end

  test "calls handle_request! using settings in the config" do
    conn =
      conn(:get, "/auth/patreon", %{
        client_id: "12345",
        client_secret: "98765",
        redirect_uri: "http://localhost:4000/auth/patreon/callback"
      })

    routes =
      Ueberauth.init()

    resp = Ueberauth.call(conn, routes)

    assert resp.status == 302
    assert [location] = get_resp_header(resp, "location")

    redirect_uri = URI.parse(location)
    assert redirect_uri.host == "www.patreon.com"
    assert redirect_uri.path == "/oauth2/authorize"

    assert %{
             "client_id" => "test_client_id",
             "response_type" => "code",
             "scope" => "identity[email] identity",
           } = Plug.Conn.Query.decode(redirect_uri.query)
  end

  describe "handle_callback!" do
    test "with no code" do
      conn = %Plug.Conn{}
      result = Ueberauth.Strategy.Patreon.handle_callback!(conn)
      failure = result.assigns.ueberauth_failure
      assert length(failure.errors) == 1
      [no_code_error] = failure.errors

      assert no_code_error.message_key == "missing_code"
      assert no_code_error.message == "No code received"
    end
  end

  describe "handle_cleanup!" do
    test "clears twitch_user from conn" do
      conn =
        %Plug.Conn{}
        |> Plug.Conn.put_private(:patreon_user, %{username: "talk2megooseman"})
        |> Plug.Conn.put_private(:patreon_token, "test-token")

      result = Ueberauth.Strategy.Patreon.handle_cleanup!(conn)
      assert result.private.patreon_user == nil
      assert result.private.patreon_token == nil
    end
  end

  describe "uid" do
    test "field not found" do
      conn =
        %Plug.Conn{}
        |> Plug.Conn.put_private(:patreon_user, %{
          "data" => %{}
        })

      assert Ueberauth.Strategy.Patreon.uid(conn) == nil
    end

    test "uid_field returned" do
      uid = "abcd1234abcd1234"

      conn =
        %Plug.Conn{}
        |> Plug.Conn.put_private(:patreon_user, %{
          "data" => %{
            "id" => uid
          }
        })

      assert Ueberauth.Strategy.Patreon.uid(conn) == uid
    end
  end

  describe "credentials" do
    test "are returned" do
      expires_at = Time.utc_now()

      conn =
        %Plug.Conn{}
        |> Plug.Conn.put_private(:patreon_token, %{
          access_token: "access-token",
          refresh_token: "refresh-token",
          expires_in: expires_at,
          token_type: "bearer",
          scope: ["blah"]
        })

      creds = Ueberauth.Strategy.Patreon.credentials(conn)
      assert creds.token == "access-token"
      assert creds.refresh_token == "refresh-token"
      assert creds.scopes == ["blah"]
      assert creds.token_type == "bearer"
      assert creds.expires_at == expires_at
    end
  end

  describe "info" do
    test "is returned" do
      conn =
        %Plug.Conn{}
        |> Plug.Conn.put_private(:patreon_user, %{
          "data" => %{
            "attributes" => %{
              "full_name" => "JohnDoe",
              "first_name" => "John",
              "last_name" => "Doe",
              "about" => "My channel.",
              "image_url" => "http://the.image.url",
              "url" => "http://the.url",
              "email" => "johndoe@example.com"
            }
          }
        })

      info = Ueberauth.Strategy.Patreon.info(conn)
      assert info.name == "JohnDoe"
      assert info.first_name == "John"
      assert info.last_name == "Doe"
      assert info.email == "johndoe@example.com"
      assert info.description == "My channel."
      assert info.image == "http://the.image.url"
      assert info.urls.profile == "http://the.url"
    end
  end
end
