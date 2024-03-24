import Config

if Mix.env() == :test do
  config :ueberauth, Ueberauth,
    providers: [
      patreon: {Ueberauth.Strategy.Patreon, [default_scope: "identity[email] identity"]}
    ]

  config :ueberauth, Ueberauth.Strategy.Patreon.OAuth,
    client_id: "test_client_id",
    client_secret: "test_client_secret",
    redirect_uri: "http://localhost:4000/auth/patreon/callback"
end
