defmodule Ueberauth.Strategy.Auth0.OAuthTest do
  use ExUnit.Case

  import Ueberauth.Strategy.Auth0.OAuth, only: [client: 1, client: 2]

  @test_domain "example-app.auth0.com"
  @conn %Plug.Conn{}

  describe "when default configurations are used" do
    setup do
      {:ok, %{client: client(@conn)}}
    end

    test "creates correct client", %{client: client} do
      asserts_client_creation(client)
    end

    test "raises when there is no configuration" do
      assert_raise(RuntimeError, ~r/^Expected to find settings under.*/, fn ->
        client(@conn, otp_app: :unknown_auth0_otp_app)
      end)
    end
  end

  describe "when right custom/computed configurations are used" do
    setup do
      load_configs("config_from")
      {:ok, %{client: client(@conn, conn: @conn)}}
    end

    test "creates correct client", %{client: client} do
      asserts_client_creation(client)
    end
  end

  describe "when bad custom/computed configurations are used" do
    setup do
      load_configs("bad_config_from")
    end

    test "raises when there is bad ConfigFrom module" do
      assert_raise(
        RuntimeError,
        ~r/^When using `:config_from`, the given module should export 3 functions:*/,
        fn ->
          client(@conn, conn: @conn)
        end
      )
    end
  end

  defp asserts_client_creation(client) do
    assert client.client_id == "example-client-id"
    assert client.client_secret == "example-client-secret"
    assert client.redirect_uri == ""
    assert client.strategy == Ueberauth.Strategy.Auth0.OAuth
    assert client.authorize_url == "https://#{@test_domain}/authorize"
    assert client.token_url == "https://#{@test_domain}/oauth/token"
    assert client.site == "https://#{@test_domain}"
  end

  defp load_configs(filename) do
    "test/configs/#{filename}.exs"
    |> Config.Reader.read!()
    |> Application.put_all_env()

    module =
      :ueberauth
      |> Application.get_env(Ueberauth.Strategy.Auth0.OAuth)
      |> Keyword.get(:config_from)

    {:module, _module} = Code.ensure_loaded(module)

    :ok
  end
end
