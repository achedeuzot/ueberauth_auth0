defmodule Ueberauth.Strategy.Auth0Test do
  # Test resources:
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  use Plug.Test

  # Custom data:
  import Ueberauth.Strategy.Auth0, only: [info: 1, extra: 1]
  alias Ueberauth.Auth.{Extra, Info}

  # Initializing utils:
  doctest Ueberauth.Strategy.Auth0

  @router SpecRouter.init([])
  @test_email "janedoe@example.com"
  @session_options Plug.Session.init(
                     store: Plug.Session.COOKIE,
                     key: "_my_key",
                     signing_salt: "CXlmrshG"
                   )

  @user_id "auth0|lyy5v452u345tbn943qf"

  @user_info %{
    "sub" => @user_id,
    "name" => "Jane Josephine Doe",
    "given_name" => "Jane",
    "family_name" => "Doe",
    "middle_name" => "Josephine",
    "nickname" => "JJ",
    "preferred_username" => "j.doe",
    "profile" => "http://example.com/janedoe",
    "picture" => "http://example.com/janedoe/me.jpg",
    "website" => "http://example.com",
    "email" => "janedoe@example.com",
    "email_verified" => true,
    "gender" => "female",
    "birthdate" => "1972-03-31",
    "zoneinfo" => "America/Los_Angeles",
    "locale" => "en-US",
    "phone_number" => "+1 (111) 222-3434",
    "phone_number_verified" => false,
    "address" => %{
      "country" => "us"
    },
    "updated_at" => "1556845729"
  }

  # Setups:
  setup_all do
    signer = SpecSignerModule.get()

    {:ok, id_token, _} = Joken.encode_and_sign(@user_info, signer)
    # Creating token:
    token = %OAuth2.AccessToken{
      access_token: "eyJz93alolk4laUWw",
      expires_at: 1_592_551_369,
      other_params: %{"id_token" => id_token},
      refresh_token: "GEbRxBNkitedjnXbL",
      token_type: "Bearer"
    }

    {:ok,
     %{
       id_token: id_token,
       token: token
     }}
  end

  # Tests:
  describe "handle_request!" do
    test "simple oauth2 /authorize request" do
      conn =
        :get
        |> conn("/auth/auth0")
        |> SpecRouter.call(@router)

      assert conn.resp_body =~ ~s|<html><body>You are being <a href=|
      assert conn.resp_body =~ ~s|>redirected</a>.</body></html>|
      assert conn.resp_body =~ ~s|href="https://example-app.auth0.com/authorize?|
      assert conn.resp_body =~ ~s|client_id=clientidsomethingrandom|

      assert conn.resp_body =~
               ~s|redirect_uri=http%3A%2F%2Fwww.example.com%2Fauth%2Fauth0%2Fcallback|

      assert conn.resp_body =~ ~s|response_type=code|
      assert conn.resp_body =~ ~s|scope=openid+profile+email|
      assert conn.resp_body =~ ~s|state=#{conn.private[:ueberauth_state_param]}|
    end

    test "advanced oauth2 /authorize request" do
      conn =
        :get
        |> conn(
          "/auth/auth0?scope=profile%20address%20phone&audience=https%3A%2F%2Fexample-app.auth0.com%2Fmfa%2F" <>
            "&connection=facebook&unknown_param=should_be_ignored" <>
            "&prompt=login&screen_hint=signup&login_hint=user%40example.com" <>
            "&organization=org_abc123&invitation=INVITE2022"
        )
        |> SpecRouter.call(@router)

      assert conn.resp_body =~ ~s|<html><body>You are being <a href=|
      assert conn.resp_body =~ ~s|>redirected</a>.</body></html>|
      assert conn.resp_body =~ ~s|href="https://example-app.auth0.com/authorize?|
      assert conn.resp_body =~ ~s|client_id=clientidsomethingrandom|
      assert conn.resp_body =~ ~s|connection=facebook|
      assert conn.resp_body =~ ~s|login_hint=user|
      assert conn.resp_body =~ ~s|screen_hint=signup|

      assert conn.resp_body =~
               ~s|redirect_uri=http%3A%2F%2Fwww.example.com%2Fauth%2Fauth0%2Fcallback|

      assert conn.resp_body =~ ~s|response_type=code|
      assert conn.resp_body =~ ~s|scope=profile+address+phone|
      assert conn.resp_body =~ ~s|state=#{conn.private[:ueberauth_state_param]}|
      assert conn.resp_body =~ ~s|organization=org_abc123|
      assert conn.resp_body =~ ~s|invitation=INVITE2022|
    end
  end

  describe "handle_callback!" do
    test "nominal callback from auth0", %{id_token: id_token} do
      request_conn =
        :get
        |> conn("/auth/auth0", id: "foo")
        |> SpecRouter.call(@router)
        |> Plug.Conn.fetch_cookies()

      state = request_conn.private[:ueberauth_state_param]
      code = "some_code"
      body = id_token |> response_body() |> Jason.encode!()

      use_cassette :stub,
        method: :post,
        headers: response_headers(),
        body: body,
        status_code: 200 do
        conn =
          :get
          |> conn("/auth/auth0/callback",
            id: "foo",
            code: code,
            state: state
          )
          |> Map.put(:cookies, request_conn.cookies)
          |> Map.put(:req_cookies, request_conn.req_cookies)
          |> Plug.Session.call(@session_options)
          |> SpecRouter.call(@router)

        assert conn.resp_body == "auth0 callback"

        auth = conn.assigns.ueberauth_auth

        assert auth.provider == :auth0
        assert auth.strategy == Ueberauth.Strategy.Auth0
        assert auth.uid == @user_id
        assert conn.private.auth0_state == state

        ## Tokens have expiration time (see other test below)
        assert auth.credentials.expires == true
        assert is_integer(auth.credentials.expires_at)
      end
    end

    test "nominal callback from auth0 but without state: potential CSRF attack", %{
      id_token: id_token
    } do
      request_conn =
        :get
        |> conn("/auth/auth0", id: "foo")
        |> SpecRouter.call(@router)
        |> Plug.Conn.fetch_cookies()

      code = "some_code"
      body = id_token |> response_body() |> Jason.encode!()

      use_cassette :stub,
        method: :post,
        headers: response_headers(),
        body: body,
        status_code: 200 do
        conn =
          :get
          |> conn("/auth/auth0/callback",
            id: "foo",
            code: code
          )
          |> Map.put(:cookies, request_conn.cookies)
          |> Map.put(:req_cookies, request_conn.req_cookies)
          |> Plug.Session.call(@session_options)
          |> SpecRouter.call(@router)

        assert conn.resp_body == "auth0 callback"

        auth = conn.assigns.ueberauth_failure
        assert conn.private[:auth0_state] == nil

        csrf_attack = %Ueberauth.Failure.Error{
          message: "Cross-Site Request Forgery attack",
          message_key: "csrf_attack"
        }

        assert auth.provider == :auth0
        assert auth.strategy == Ueberauth.Strategy.Auth0
        assert auth.errors == [csrf_attack]
      end
    end

    test "cannot verify id_token" do
      request_conn =
        :get
        |> conn("/auth/auth0", id: "foo")
        |> SpecRouter.call(@router)
        |> Plug.Conn.fetch_cookies()

      state = request_conn.private[:ueberauth_state_param]
      code = "some_code"

      signer = Joken.Signer.create("HS256", "the-wrong-secret")
      {:ok, id_token, _} = Joken.encode_and_sign(@user_info, signer)
      body = id_token |> response_body() |> Jason.encode!()

      use_cassette :stub,
        method: :post,
        headers: response_headers(),
        body: body,
        status_code: 200 do
        conn =
          :get
          |> conn("/auth/auth0/callback",
            id: "foo",
            code: code,
            state: state
          )
          |> Map.put(:cookies, request_conn.cookies)
          |> Map.put(:req_cookies, request_conn.req_cookies)
          |> Plug.Session.call(@session_options)
          |> SpecRouter.call(@router)

        assert conn.resp_body == "auth0 callback"

        auth = conn.assigns.ueberauth_failure

        csrf_attack = %Ueberauth.Failure.Error{
          message: "Could not validate token",
          message_key: "failed_token_verification"
        }

        assert auth.provider == :auth0
        assert auth.strategy == Ueberauth.Strategy.Auth0
        assert auth.errors == [csrf_attack]
      end
    end

    test "invalid callback from auth0 without code", %{id_token: id_token} do
      request_conn =
        :get
        |> conn("/auth/auth0", id: "foo")
        |> SpecRouter.call(@router)
        |> Plug.Conn.fetch_cookies()

      state = request_conn.private[:ueberauth_state_param]
      body = id_token |> response_body() |> Jason.encode!()

      use_cassette :stub,
        method: :post,
        headers: response_headers(),
        body: body,
        status_code: 200 do
        conn =
          :get
          |> conn("/auth/auth0/callback",
            id: "foo",
            state: state
          )
          |> Map.put(:cookies, request_conn.cookies)
          |> Map.put(:req_cookies, request_conn.req_cookies)
          |> Plug.Session.call(@session_options)
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

    test "invalid callback from auth0 with invalid code" do
      request_conn =
        :get
        |> conn("/auth/auth0", id: "foo")
        |> SpecRouter.call(@router)
        |> Plug.Conn.fetch_cookies()

      state = request_conn.private[:ueberauth_state_param]

      use_cassette "auth0-invalid-code", match_requests_on: [:query] do
        conn =
          :get
          |> conn("/auth/auth0/callback", id: "foo", code: "invalid_code", state: state)
          |> Map.put(:cookies, request_conn.cookies)
          |> Map.put(:req_cookies, request_conn.req_cookies)
          |> Plug.Session.call(@session_options)
          |> SpecRouter.call(@router)

        auth = conn.assigns.ueberauth_failure

        invalid_grant_error = %Ueberauth.Failure.Error{
          message: "Invalid authorization code",
          message_key: "invalid_grant"
        }

        assert auth.provider == :auth0
        assert auth.strategy == Ueberauth.Strategy.Auth0
        assert auth.errors == [invalid_grant_error]
      end
    end

    test "invalid callback from auth0 with no token in response" do
      request_conn =
        :get
        |> conn("/auth/auth0", id: "foo")
        |> SpecRouter.call(@router)
        |> Plug.Conn.fetch_cookies()

      state = request_conn.private[:ueberauth_state_param]

      use_cassette "auth0-no-access-token", match_requests_on: [:query] do
        conn =
          :get
          |> conn("/auth/auth0/callback",
            id: "foo",
            code: "some_code",
            state: state
          )
          |> Map.put(:cookies, request_conn.cookies)
          |> Map.put(:req_cookies, request_conn.req_cookies)
          |> Plug.Session.call(@session_options)
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

    test "callback from auth0 with no expiration time of tokens", %{id_token: id_token} do
      request_conn =
        :get
        |> conn("/auth/auth0", id: "foo")
        |> SpecRouter.call(@router)
        |> Plug.Conn.fetch_cookies()

      state = request_conn.private[:ueberauth_state_param]

      body = id_token |> response_body() |> Map.delete("expires_in") |> Jason.encode!()

      use_cassette :stub, method: :post, headers: response_headers(), body: body, status_code: 200 do
        conn =
          :get
          |> conn("/auth/auth0/callback",
            id: "foo",
            code: "some_code",
            state: state
          )
          |> Map.put(:cookies, request_conn.cookies)
          |> Map.put(:req_cookies, request_conn.req_cookies)
          |> Plug.Session.call(@session_options)
          |> SpecRouter.call(@router)

        assert conn.resp_body == "auth0 callback"

        auth = conn.assigns.ueberauth_auth

        # Same information as default token
        assert auth.provider == :auth0
        assert auth.strategy == Ueberauth.Strategy.Auth0
        assert auth.uid == @user_id
        assert conn.private.auth0_state == state

        ## Difference here
        assert auth.credentials.expires == false
        assert auth.credentials.expires_at == nil
      end
    end
  end

  describe "info/1" do
    test "user information parsing", fixtures do
      token = fixtures.token

      conn = %Plug.Conn{
        private: %{
          auth0_user: @user_info,
          auth0_token: token
        }
      }

      assert info(conn) == %Info{
               birthday: "1972-03-31",
               description: nil,
               email: @test_email,
               first_name: "Jane",
               image: "http://example.com/janedoe/me.jpg",
               last_name: "Doe",
               location: nil,
               name: "Jane Josephine Doe",
               nickname: "JJ",
               phone: "+1 (111) 222-3434",
               urls: %{
                 profile: "http://example.com/janedoe",
                 website: "http://example.com"
               }
             }
    end
  end

  describe "extra/1" do
    test "user extra information parsing", fixtures do
      token = fixtures.token
      id_token = fixtures.id_token

      conn = %Plug.Conn{
        private: %{
          auth0_user: @user_info,
          auth0_token: token
        }
      }

      assert extra(conn) == %Extra{
               raw_info: %{
                 token: %OAuth2.AccessToken{
                   access_token: "eyJz93alolk4laUWw",
                   expires_at: 1_592_551_369,
                   other_params: %{"id_token" => id_token},
                   refresh_token: "GEbRxBNkitedjnXbL",
                   token_type: "Bearer"
                 },
                 user: %{
                   "address" => %{"country" => "us"},
                   "birthdate" => "1972-03-31",
                   "email" => "janedoe@example.com",
                   "email_verified" => true,
                   "family_name" => "Doe",
                   "gender" => "female",
                   "given_name" => "Jane",
                   "locale" => "en-US",
                   "middle_name" => "Josephine",
                   "name" => "Jane Josephine Doe",
                   "nickname" => "JJ",
                   "phone_number" => "+1 (111) 222-3434",
                   "phone_number_verified" => false,
                   "picture" => "http://example.com/janedoe/me.jpg",
                   "preferred_username" => "j.doe",
                   "profile" => "http://example.com/janedoe",
                   "sub" => @user_id,
                   "updated_at" => "1556845729",
                   "website" => "http://example.com",
                   "zoneinfo" => "America/Los_Angeles"
                 }
               }
             }
    end
  end

  defp response_headers do
    [{"Content-Type", "application/json"}]
  end

  defp response_body(id_token) do
    %{
      "access_token" => "eyJz93alolk4laUWw",
      "scope" => "openid profile email",
      "id_token" => id_token,
      "token_type" => "Bearer",
      "expires_in" => 86400
    }
  end
end
