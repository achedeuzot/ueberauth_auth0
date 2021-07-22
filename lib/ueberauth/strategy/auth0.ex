defmodule Ueberauth.Strategy.Auth0 do
  @moduledoc """
  Provides an Ueberauth strategy for authenticating with Auth0.

  You can edit the behaviour of the Strategy by including some options when
  you register your provider.

  To set the `uid_field`
      config :ueberauth, Ueberauth,
        providers: [
          auth0: { Ueberauth.Strategy.Auth0, [uid_field: :email] }
        ]
  Default is `:sub`

  To set the default ['scope'](https://auth0.com/docs/scopes) (permissions):
      config :ueberauth, Ueberauth,
        providers: [
          auth0: { Ueberauth.Strategy.Auth0, [default_scope: "openid profile email"] }
        ]
  Default is `"openid profile email"`.

  To set the [`cachex_cache_id`](https://auth0.com/docs/glossary#cachex_cache_id)
      config :ueberauth, Ueberauth,
        providers: [
          auth0: { Ueberauth.Strategy.Auth0, [cachex_cache_id: :example_cachex_id] }
        ]
  Not used by default (set to `""`).

  To set the [`audience`](https://auth0.com/docs/glossary#audience)
      config :ueberauth, Ueberauth,
        providers: [
          auth0: { Ueberauth.Strategy.Auth0, [default_audience: "example-audience"] }
        ]
  Not used by default (set to `""`).

  To set the [`connection`](https://auth0.com/docs/identityproviders), mostly useful if
  you want to use a social identity provider like `facebook` or `google-oauth2`. If empty
  it will redirect to Auth0's Login widget. See https://auth0.com/docs/api/authentication#social
      config :ueberauth, Ueberauth,
        providers: [
          auth0: { Ueberauth.Strategy.Auth0, [default_connection: "facebook"] }
        ]
  Not used by default (set to `""`)

  To set the [`state`](https://auth0.com/docs/protocols/oauth2/oauth-state). This is useful
  to prevent from CSRF attacks and redirect users to the state before the authentication flow
  started.
      config :ueberauth, Ueberauth,
        providers: [
          auth0: { Ueberauth.Strategy.Auth0, [default_state: "some-opaque-state"] }
        ]
  Not used by default (set to `""`)

  These 4 parameters can also be set in the request to authorization. e.g.
  You can call the `auth0` authentication endpoint with values:
  `/auth/auth0?scope="some+new+scope&audience=events:read&connection=facebook&state=opaque_value`

  ## About the `state` param
  Usually a static `state` value is not very useful so it's best to pass it to
  the request endpoint as a parameter. You can then read back the state after
  authentication in a private value set in the connection: `auth0_state`.

  ### Example

      state_signed = Phoenix.Token.sign(MyApp.Endpoint, "return_url", Phoenix.Controller.current_url(conn))
      Routes.auth_path(conn, :request, "auth0", state: state_signed)
      # authentication happens ...
      # the state ends up in `conn.private.auth0_state` after the authentication process
      {:ok, redirect_to} = Phoenix.Token.verify(MyApp.Endpoint, "return_url", conn.private.auth0_state, max_age: 900)

  """
  use Ueberauth.Strategy,
    uid_field: :sub,
    default_scope: "openid profile email",
    default_audience: "",
    default_connection: "",
    default_prompt: "",
    default_screen_hint: "",
    default_login_hint: "",
    allowed_request_params: [
      :scope,
      :state,
      :audience,
      :connection,
      :prompt,
      :screen_hint,
      :login_hint
    ],
    oauth2_module: Ueberauth.Strategy.Auth0.OAuth

  alias OAuth2.{Client, Error, Response}
  alias Plug.Conn
  alias Ueberauth.Auth.{Credentials, Extra, Info}
  alias Ueberauth.Strategy.Auth0.Token

  @doc """
  Handles the redirect to Auth0.
  """
  def handle_request!(conn) do
    allowed_params =
      conn
      |> option(:allowed_request_params)
      |> Enum.map(&to_string/1)

    opts =
      conn.params
      |> maybe_replace_param(conn, "scope", :default_scope)
      |> maybe_replace_param(conn, "audience", :default_audience)
      |> maybe_replace_param(conn, "connection", :default_connection)
      |> maybe_replace_param(conn, "prompt", :default_prompt)
      |> maybe_replace_param(conn, "screen_hint", :default_screen_hint)
      |> maybe_replace_param(conn, "login_hint", :default_login_hint)
      |> Map.put("state", conn.private[:ueberauth_state_param])
      |> Enum.filter(fn {k, _} -> Enum.member?(allowed_params, k) end)
      # Remove empty params
      |> Enum.reject(fn {_, v} -> blank?(v) end)
      |> Enum.map(fn {k, v} -> {String.to_existing_atom(k), v} end)
      |> Keyword.put(:redirect_uri, callback_url(conn))

    module = option(conn, :oauth2_module)

    callback_url =
      apply(module, :authorize_url!, [
        opts,
        [otp_app: option(conn, :otp_app)]
      ])

    redirect!(conn, callback_url)
  end

  @doc """
  Handles the callback from Auth0. When there is a failure from Auth0 the failure is included in the
  `ueberauth_failure` struct. Otherwise the information returned from Auth0 is returned in the `Ueberauth.Auth` struct.
  """
  def handle_callback!(%Conn{params: %{"code" => _}} = conn) do
    {code, state} = parse_params(conn)
    module = option(conn, :oauth2_module)
    redirect_uri = callback_url(conn)
    otp_app = option(conn, :otp_app)

    client =
      apply(module, :get_token!, [
        [code: code, redirect_uri: redirect_uri],
        [otp_app: otp_app]
      ])

    token = client.token

    with {:token_validation, {:ok, _}} <- {:token_validation, Token.maybe_validation(otp_app, client)},
      {:nil_token_check, {:ok, nil}} <- {:nil_token_check, nil_token_check(token)},
      {:auth0, {:ok, %Response{status_code: status_code, body: user}}} when status_code in 200..399 <- {:auth0, Client.get(client, "/userinfo")}
    do
      conn
      |> put_private(:auth0_user, user)
      |> put_private(:auth0_token, token)
      |> put_private(:auth0_state, state)
    else
      {:token_validation, err} ->
        error = "token_validation"

        set_errors!(conn, [error(error, err)])
      {:nil_token_check, _err} ->
        error = token.other_params["error"]
        error_description = token.other_params["error_description"]

        set_errors!(conn, [error(error, error_description)])

      {:auth0, {:ok, %Response{status_code: 401, body: _body}}} ->
        set_errors!(conn, [error("token", "unauthorized")])
      {:auth0, {:error, %Response{body: body}}} ->
        set_errors!(conn, [error("OAuth2", body)])
      {:auth0, {:error, %Error{reason: reason}}} ->
        set_errors!(conn, [error("OAuth2", reason)])

    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  defp nil_token_check(token) do
    case token.access_token do
      nil ->
        {:error, :no_token}
      _ ->
        {:ok, nil}
      end
  end

  @doc """
  Cleans up the private area of the connection used for passing the raw Auth0 response around during the callback.
  """
  def handle_cleanup!(conn) do
    conn
    |> put_private(:auth0_user, nil)
    |> put_private(:auth0_token, nil)
  end

  @doc """
  Fetches the uid field from the Auth0 response.
  """
  def uid(conn) do
    conn.private.auth0_user[to_string(option(conn, :uid_field))]
  end

  @doc """
  Includes the credentials from the Auth0 response.
  """
  def credentials(conn) do
    token = conn.private.auth0_token

    scopes =
      (token.other_params["scope"] || "")
      |> String.split(",")

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      token_type: token.token_type,
      expires_at: token.expires_at,
      expires: token_expired(token),
      scopes: scopes,
      other: token.other_params
    }
  end

  defp token_expired(%{expires_at: nil}), do: false
  defp token_expired(%{expires_at: _}), do: true

  @doc """
  Populates the extra section of the `Ueberauth.Auth` struct with auth0's
  additional information from the `/userinfo` user profile and includes the
  token received from Auth0 callback.
  """
  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.auth0_token,
        user: conn.private.auth0_user
      }
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.

  This field has been changed from 0.5.0 to 0.6.0 to better reflect
  fields of the OpenID standard claims. Extra fields provided by
  auth0 are in the `Extra` struct.
  """
  def info(conn) do
    user = conn.private.auth0_user

    %Info{
      name: user["name"],
      first_name: user["given_name"],
      last_name: user["family_name"],
      nickname: user["nickname"],
      email: user["email"],
      # The `locale` auth0 field has been moved to `Extra` to better follow OpenID standard specs.
      # The `location` field of `Ueberauth.Auth.Info` is intended for location (city, country, ...)
      # information while the `locale` information returned by auth0 is used for internationalization.
      # There is no location field in the auth0 response, only an `address`.
      location: nil,
      description: nil,
      image: user["picture"],
      phone: user["phone_number"],
      birthday: user["birthdate"],
      urls: %{
        profile: user["profile"],
        website: user["website"]
      }
    }
  end

  defp parse_params(%Plug.Conn{params: %{"code" => code, "state" => state}}) do
    {code, state}
  end

  defp parse_params(%Plug.Conn{params: %{"code" => code}}) do
    {code, nil}
  end

  defp option(conn, key) do
    default = Keyword.get(default_options(), key)

    conn
    |> options
    |> Keyword.get(key, default)
  end

  defp option(nil, conn, key), do: option(conn, key)
  defp option(value, _conn, _key), do: value

  defp maybe_replace_param(params, conn, name, config_key) do
    if params[name] do
      params
    else
      Map.put(params, name, option(params[name], conn, config_key))
    end
  end

  @compile {:inline, blank?: 1}
  def blank?(""), do: true
  def blank?([]), do: true
  def blank?(nil), do: true
  def blank?({}), do: true
  def blank?(%{} = map) when map_size(map) == 0, do: true
  def blank?(_), do: false
end
