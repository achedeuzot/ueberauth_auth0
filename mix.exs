defmodule UeberauthAuth0.Mixfile do
  use Mix.Project

  @version "0.8.1"

  def project do
    [
      app: :ueberauth_auth0,
      version: @version,
      name: "Ueberauth Auth0",
      description: description(),
      source_url: "https://github.com/achedeuzot/ueberauth_auth0",
      homepage_url: "http://hexdocs.pm/ueberauth_auth0",
      package: package(),
      elixir: "~> 1.7",
      deps: deps(),
      docs: docs(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,

      # Test coverage:
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        vcr: :test,
        "vcr.delete": :test,
        "vcr.check": :test,
        "vcr.show": :test
      ],

      # Type checking
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ]
    ]
  end

  def application do
    [applications: [:logger, :ueberauth, :oauth2]]
  end

  defp deps do
    [
      {:ueberauth, "~> 0.6"},
      {:oauth2, "~> 2.0"},

      # Docs:
      {:ex_doc, "~> 0.21", only: :dev},
      {:earmark, "~> 1.3", only: :dev},

      # Testing:
      {:exvcr, "~> 0.10", only: :test},
      {:excoveralls, "~> 0.11", only: :test},

      # Type checking
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev, :test], runtime: false},

      # Lint:
      {:credo, "~> 1.1", only: [:dev, :test]}
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
      maintainers: ["Son Tran-Nguyen", "Nikita Sobolev", "Klemen Sever"],
      licenses: ["MIT"],
      links: %{GitHub: "https://github.com/achedeuzot/ueberauth_auth0"}
    ]
  end
end
