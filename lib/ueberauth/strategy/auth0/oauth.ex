defmodule Ueberauth.Strategy.Auth0.OAuth do
  @moduledoc """
  An implementation of OAuth2 for Auth0.
  To add your `domain`, `client_id` and `client_secret` include these values in your configuration.
      config :ueberauth, Ueberauth.Strategy.Auth0.OAuth,
        domain: System.get_env("AUTH0_DOMAIN"),
        client_id: System.get_env("AUTH0_CLIENT_ID"),
        client_secret: System.get_env("AUTH0_CLIENT_SECRET")
  """
  use OAuth2.Strategy

  def options() do
    configs = Application.get_env(:ueberauth, Ueberauth.Strategy.Auth0.OAuth)
    domain = configs[:domain]
    opts = [
      strategy: __MODULE__,
      site: "https://#{domain}",
      authorize_url: "https://#{domain}/authorize",
      token_url: "https://#{domain}/oauth/token",
      userinfo_url: "https://#{domain}/userinfo"
    ]
    Keyword.merge(configs, opts)
  end

  @doc """
  Construct a client for requests to Auth0.
  Optionally include any OAuth2 options here to be merged with the defaults.
      Ueberauth.Strategy.Auth0.OAuth.client(redirect_uri: "http://localhost:4000/auth/auth0/callback")
  This will be setup automatically for you in `Ueberauth.Strategy.Auth0`.
  These options are only useful for usage outside the normal callback phase of Ueberauth.
  """
  def client(opts \\ []) do
    opts = Keyword.merge(options(), opts)
    OAuth2.Client.new(opts)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth. No need to call this usually.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    client(opts)
    |> OAuth2.Client.authorize_url!(params)
  end

  def get_token!(params \\ [], opts \\ %{}) do
    headers = Dict.get(opts, :headers, [])
    opts = Dict.get(opts, :options, [])
    client_options = Dict.get(opts, :client_options, [])
    OAuth2.Client.get_token!(client(client_options), params, headers, opts)
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end
end