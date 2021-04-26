defmodule UeberauthAuth0.Mixfile do
  use Mix.Project

  @source_url "https://github.com/achedeuzot/ueberauth_auth0"
  @version "2.1.0"

  def project do
    [
      app: :ueberauth_auth0,
      version: @version,
      name: "Ueberauth Auth0",
      package: package(),
      elixir: "~> 1.10",
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
        plt_core_path: "_build/#{Mix.env()}"
      ],

      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env)
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ueberauth, "~> 0.10"},
      {:oauth2, "~> 2.0"},

      # Docs:
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},

      # Testing:
      {:exvcr, "~> 0.10", only: [:test, :test_with_config_from]},
      {:excoveralls, "~> 0.11", only: [:test, :test_with_config_from]},

      # Type checking
      {:dialyxir, "~> 1.2.0", only: [:dev, :test], runtime: false},

      # Lint:
      {:credo, "~> 1.1", only: [:dev, :test]}
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md",
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      source_url: @source_url,
      source_ref: "v#{@version}",
      main: "readme",
      formatters: ["html"]
    ]
  end

  defp package do
    [
      name: :ueberauth_auth0,
      description: "An Ueberauth strategy for using Auth0 to authenticate your users.",
      files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
      maintainers: ["Son Tran-Nguyen", "Nikita Sobolev", "Klemen Sever"],
      licenses: ["MIT"],
      links: %{
        Changelog: "https://hexdocs.pm/ueberauth_auth0/changelog.html",
        GitHub: @source_url
      }
    ]
  end

  defp aliases do
    [
      {:"test.all", [&run_tests/1, &run_tests_with_config_from/1]}
    ]
  end

  defp run_tests(_) do
    IO.puts("""
    \n#
    # Running tests with DEFAULT configurations.
    #\n
    """)

    Mix.shell.cmd(
      "mix test --color",
      env: [{"MIX_ENV", "test"}]
    )
  end

  defp run_tests_with_config_from(_) do
    IO.puts("""
    \n#
    # Running tests with COMPUTED configurations.
    #\n
    """)

    Mix.shell.cmd(
      "mix test --color",
      env: [{"MIX_ENV", "test_with_config_from"}]
    )
  end

  defp elixirc_paths(:test_with_config_from), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
