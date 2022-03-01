defmodule UeberauthPatreon.MixProject do
  use Mix.Project

  def project do
    [
      app: :ueberauth_patreon,
      description: "Ueberauth strategy for Patreon OAuth.",
      links: %{"GitHub" => ""},
      licenses: ["MIT"],
      version: "1.0.0",
      elixir: "~> 1.13",
      source_url: "",
      homepage_url: "",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        # main: "MyApp", # The main page in the docs
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
