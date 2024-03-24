defmodule UeberauthPatreon.MixProject do
  use Mix.Project

  @source_url "https://github.com/talk2MeGooseman/ueberauth_patreon"
  @version "1.0.1"

  def project do
    [
      app: :ueberauth_patreon,
      description: "Ueberauth strategy for Patreon OAuth.",
      version: @version,
      elixir: "~> 1.13",
      source_url: @source_url,
      homepage_url: @source_url,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: [
        links: %{"GitHub" => "https://github.com/talk2MeGooseman/ueberauth_patreon"},
        licenses: ["MIT"]
      ],
      docs: docs(),
      aliases: aliases()
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
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:credo, "~> 1.0", only: [:dev, :test]}
    ]
  end

  defp docs do
    [
      extras: [
        "README.md": [title: "Overview"],
        "CHANGELOG.md": [title: "Changelog"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "#v{@version}"
    ]
  end

  defp aliases do
    [
      lint: ["format", "credo"]
    ]
  end
end
