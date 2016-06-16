defmodule UeberauthAuth0.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :ueberauth_auth0,
      version: @version,
      name: "Ueberauth Auth0",
      description: description,
      source_url: "https://github.com/sntran/ueberauth_auth0",
      homepage_url: "http://hexdocs.pm/ueberauth_auth0",
      package: package,
      elixir: "~> 1.3-dev",
      deps: deps,
      docs: docs]
  end

  def application do
    [applications: [:logger, :ueberauth, :oauth2]]
  end

  defp deps do
    [
      {:ueberauth, "~> 0.2"},
      {:oauth2, "~> 0.6"},
      {:ex_doc, "~> 0.12", only: :dev},
      {:earmark, "~> 0.2", only: :dev}
    ]
  end

  defp docs do
    [source_ref: "v#{@version}", main: "readme", extras: docs_extras]
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
      maintainers: ["Son Tran-Nguyen"],
      licenses: ["MIT"],
      links: %{"GitHub": "https://github.com/sntran/ueberauth_auth0"}]
  end
end