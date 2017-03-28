# Überauth Auth0

> Auth0 OAuth2 strategy for Überauth.

## Installation

  1. Set up your Auth0 application at [Auth0 dashboard](https://manage.auth0.com/#/applications)

  2. Add `ueberauth_auth0` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [{:ueberauth_auth0, "~> 0.1"}]
  end
  ```

  3. Ensure `ueberauth_auth0` is started before your application:

  ```elixir
  def application do
    [applications: [:ueberauth_auth0]]
  end
  ```

  4. Add Auth0 to your Überauth configuration:

  ```elixir
  config :ueberauth, Ueberauth,
  providers: [
    auth0: {Ueberauth.Strategy.Auth0, []}
  ]
  ```

  5. Update your provider configuration:

  ```elixir
  config :ueberauth, Ueberauth.Strategy.Auth0.OAuth,
    domain: System.get_env("AUTH0_DOMAIN"),
    client_id: System.get_env("AUTH0_CLIENT_ID"),
    client_secret: System.get_env("AUTH0_CLIENT_SECRET")
  ```

  6. Include the Überauth plug in your controller:

  ```elixir
  defmodule MyApp.AuthController do
    use MyApp.Web, :controller
    plug Ueberauth
    ...
  end
  ```

  7. Create the request and callback routes if you haven't already:

  ```elixir
  scope "/auth", MyApp do
    pipe_through :browser

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end
  ```
  
  8. Create the controller to handle request and callback:

  ```elixir
  def request(conn, _params) do
    render(conn, "login.html", callback_url: Ueberauth.Strategy.Helpers.callback_url(conn))
  end

  def callback(%Plug.Conn{assigns: %{ueberauth_failure: fails}} = conn, _params) do
    conn
    |> put_flash(:error, hd(fails.errors).message)
    |> render("login.html", callback_url: Ueberauth.Strategy.Helpers.callback_url(conn))
  end

  def callback(%Plug.Conn{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    # auth = %Ueberauth.Auth{
    #   credentials: %Ueberauth.Auth.Credentials{
    #     token: token,
    #     token_type: token_type,
    #     other: %{"id_token" => id_token}
    #   }
    # }
    redirect(conn, to: private_page_path(conn, :index))
  end
  ```

## License

Please see [LICENSE](https://github.com/sntran/ueberauth_auth0/blob/master/LICENSE) for licensing details.
