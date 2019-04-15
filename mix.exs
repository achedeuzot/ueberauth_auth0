defmodule UeberauthAuth0.Mixfile do
  use Mix.Project

  @version "0.3.1"

  def project do
    [
      app: :ueberauth_auth0,
      version: @version,
      name: "Ueberauth Auth0",
      description: description(),
      source_url: "https://github.com/sntran/ueberauth_auth0",
      homepage_url: "http://hexdocs.pm/ueberauth_auth0",
      package: package(),
      elixir: "~> 1.3",
      deps: deps(),
      docs: docs(),

      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,

      # Test coverage:
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
      ]
    ]
  end

  def application do
    [applications: [:logger, :ueberauth, :oauth2]]
  end

  defp deps do
    [
      {:ueberauth, "~> 0.5"},
      {:oauth2, "~> 1.0"},

      # Docs:
      {:ex_doc, "~> 0.18", only: :dev},
      {:earmark, "~> 1.2", only: :dev},

      # Testing:
      {:exvcr, "~> 0.10", only: :test},
      {:excoveralls, "~> 0.9", only: :test},

      # Lint:
      {:credo, "~> 1.0", only: [:dev, :test]}
    ]
  end

  defp docs do
    [source_ref: "v#{@version}", main: "readme", extras: docs_extras()]
  end

  defp docs_extras do
    ["README.md"]
  end

  defp description do
    "An Ueberauth strategy for using Auth0 to authenticate your users."
  end

  defp package do
    [
      name: :ueberauth_auth0,
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Son Tran-Nguyen", "Nikita Sobolev"],
      licenses: ["MIT"],
      links: %{"GitHub": "https://github.com/sntran/ueberauth_auth0"}
    ]
  end
end
