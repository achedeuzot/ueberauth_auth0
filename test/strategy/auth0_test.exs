defmodule Ueberauth.Strategy.Auth0Test do
  # Test resources:
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  use Plug.Test

  # Custom data:
  import Ueberauth.Strategy.Auth0, only: [info: 1]
  alias Ueberauth.Auth.Info

  # Initializing utils:
  doctest Ueberauth.Strategy.Auth0

  @router SpecRouter.init([])
  @test_email "testuser@example.com"

  # Setups:
  setup_all do
    # Creating token:
    token = %OAuth2.AccessToken{
      access_token: "eyJz93alolk4laUWw",
      expires_at: 1_592_551_369,
      other_params: %{"id_token" => "eyJ0XAipop4faeEoQ"},
      refresh_token: "GEbRxBNkitedjnXbL",
      token_type: "Bearer"
    }

    # Read the fixture with the user information:
    {:ok, json} =
      "test/fixtures/auth0.json"
      |> Path.expand()
      |> File.read()

    user_info = Jason.decode!(json)

    {:ok, response} =
      "test/fixtures/auth0_response.html"
      |> Path.expand()
      |> File.read()

    response = String.replace(response, "\n", "")

    {:ok,
     %{
       user_info: user_info,
       token: token,
       response: response
     }}
  end

  # Tests:

  test "request phase", fixtures do
    conn =
      :get
      |> conn("/auth/auth0")
      |> SpecRouter.call(@router)

    assert conn.resp_body == fixtures.response
  end

  test "default callback phase" do
    query = %{code: "code_abc"} |> URI.encode_query()

    use_cassette "auth0-responses" do
      conn =
        :get
        |> conn("/auth/auth0/callback?#{query}")
        |> SpecRouter.call(@router)

      assert conn.resp_body == "auth0 callback"

      auth = conn.assigns.ueberauth_auth

      assert auth.provider == :auth0
      assert auth.strategy == Ueberauth.Strategy.Auth0
      assert auth.uid == "auth0|lyy5vutbn9qfmihil7pvpo66"
    end
  end

  test "callback without code" do
    # Empty query
    query = %{} |> URI.encode_query()

    use_cassette "auth0-responses" do
      conn =
        :get
        |> conn("/auth/auth0/callback?#{query}")
        |> SpecRouter.call(@router)

      assert conn.resp_body == "auth0 callback"

      auth = conn.assigns.ueberauth_failure

      missing_code_error = %Ueberauth.Failure.Error{
        message: "No code received",
        message_key: "missing_code"
      }

      assert auth.provider == :auth0
      assert auth.strategy == Ueberauth.Strategy.Auth0
      assert auth.errors == [missing_code_error]
    end
  end

  test "callback with invalid code" do
    # Empty query
    query = %{code: "invalid_code"} |> URI.encode_query()

    use_cassette "auth0-invalid-code" do
      assert_raise(OAuth2.Error, ~r/Server responded with status: 403.*/, fn ->
        :get
        |> conn("/auth/auth0/callback?#{query}")
        |> SpecRouter.call(@router)
      end)
    end
  end

  test "callback with no token in response" do
    # Empty query
    query = %{code: "some_code"} |> URI.encode_query()

    use_cassette "auth0-no-access-token" do
      conn =
        :get
        |> conn("/auth/auth0/callback?#{query}")
        |> SpecRouter.call(@router)

      assert conn.resp_body == "auth0 callback"

      auth = conn.assigns.ueberauth_failure

      missing_code_error = %Ueberauth.Failure.Error{
        message: "Something went wrong",
        message_key: "something_wrong"
      }

      assert auth.provider == :auth0
      assert auth.strategy == Ueberauth.Strategy.Auth0
      assert auth.errors == [missing_code_error]
    end
  end

  # This doesn't work yet, we'll add it when the feature exists
  #  test "callback phase with state" do
  #    query = %{code: "code_abc", state: "custom_state_value"} |> URI.encode_query
  #
  #    use_cassette "auth0-responses" do
  #      conn =
  #        :get
  #        |> conn("/auth/auth0/callback?#{query}")
  #        |> SpecRouter.call(@router)
  #
  #      assert conn.resp_body == "auth0 callback"
  #
  #      auth = conn.assigns.ueberauth_auth
  #
  #      assert auth.provider == :auth0
  #      assert auth.strategy == Ueberauth.Strategy.Auth0
  #      assert auth.uid == "auth0|lyy5vutbn9qfmihil7pvpo66"
  #    end
  #  end

  test "user information parsing", fixtures do
    user_info = fixtures.user_info
    token = fixtures.token

    conn = %Plug.Conn{
      private: %{
        auth0_user: user_info,
        auth0_token: token
      }
    }

    assert info(conn) == %Info{
             email: @test_email,
             name: @test_email,
             first_name: nil,
             last_name: nil,
             nickname: "testuser",
             location: nil,
             description: nil,
             image:
               "https://s.gravatar.com/avatar/7ec7606c46a14a7ef514d1f1f9038823?s=480&r=pg&d=https%3A%2F%2Fcdn.auth0.com%2Favatars%2Ftu.png",
             urls: %{}
           }
  end
end
