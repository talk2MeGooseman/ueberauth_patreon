defmodule UeberauthPatreon.MixProject do
  use Mix.Project

  def project do
    [
      app: :ueberauth_patreon,
      description: "Ueberauth strategy for Patreon OAuth.",
      version: "1.0.0",
      elixir: "~> 1.13",
      source_url: "https://github.com/talk2MeGooseman/ueberauth_patreon",
      homepage_url: "https://github.com/talk2MeGooseman/ueberauth_patreon",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: [
        links: %{"GitHub" => "https://github.com/talk2MeGooseman/ueberauth_patreon"},
        licenses: ["MIT"],
      ],
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ueberauth, "~> 0.7"},
      {:oauth2, "~> 2.0"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end
end
