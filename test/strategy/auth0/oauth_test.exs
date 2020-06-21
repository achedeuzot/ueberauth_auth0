defmodule Ueberauth.Strategy.Auth0.OAuthTest do
  use ExUnit.Case

  import Ueberauth.Strategy.Auth0.OAuth, only: [client: 0]

  @test_domain "example-app.auth0.com"

  setup do
    {:ok, %{client: client()}}
  end

  test "creates correct client", %{client: client} do
    assert client.client_id == "clientidsomethingrandom"
    assert client.client_secret == "clientsecret-somethingsecret"
    assert client.redirect_uri == ""
    assert client.strategy == Ueberauth.Strategy.Auth0.OAuth
    assert client.authorize_url == "https://#{@test_domain}/authorize"
    assert client.token_url == "https://#{@test_domain}/oauth/token"
    assert client.site == "https://#{@test_domain}"
  end
end
