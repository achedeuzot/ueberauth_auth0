# Überauth Auth0

> Auth0 OAuth2 strategy for Überauth.

![Auth0 logo](https://github.com/achedeuzot/ueberauth_auth0/blob/master/media/auth0-logo.png)

[![Build Status](https://img.shields.io/travis/achedeuzot/ueberauth_auth0/master.svg)](https://travis-ci.org/achedeuzot/ueberauth_auth0) [![Coverage Status](https://coveralls.io/repos/github/achedeuzot/ueberauth_auth0/badge.svg?branch=master)](https://coveralls.io/github/achedeuzot/ueberauth_auth0?branch=master) [![Hex Version](https://img.shields.io/hexpm/v/ueberauth_auth0.svg)](https://hex.pm/packages/ueberauth_auth0) [![License](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)


## Installation

  1. Set up your Auth0 application at [Auth0 dashboard](https://manage.auth0.com/#/applications)

  2. Add `ueberauth_auth0` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [{:ueberauth_auth0, "~> 0.3"}]
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
    ],
    # If you wish to customize the OAuth serializer,
    # add the line below. Defaults to Jason.
    json_library: Poison
  ```

  **or** with per-app config:

  ```elixir
  config :my_app, Ueberauth,
    providers: [
      auth0: {Ueberauth.Strategy.Auth0, [otp_app: :my_app]}
    ]
  ```

  5. Update your provider configuration:

  ```elixir
  config :ueberauth, Ueberauth.Strategy.Auth0.OAuth,
    domain: System.get_env("AUTH0_DOMAIN"),
    client_id: System.get_env("AUTH0_CLIENT_ID"),
    client_secret: System.get_env("AUTH0_CLIENT_SECRET")
  ```

  **or** with per-app config:

  ```elixir
  config :my_app, Ueberauth.Strategy.Auth0.OAuth,
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

  **or** with per-app config:

  ```elixir
  defmodule MyApp.AuthController do
    use MyApp.Web, :controller
    plug Ueberauth, otp_app: :my_app
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

  8. You controller needs to implement callbacks to deal with Ueberauth.Auth and Ueberauth.Failure responses.

  For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.


## Changelog

`ueberauth_auth0` follows semantic versioning. See [`CHANGELOG.md`](https://github.com/achedeuzot/ueberauth_auth0/blob/master/CHANGELOG.md) for more information.


## License

MIT. Please see [LICENSE](https://github.com/achedeuzot/ueberauth_auth0/blob/master/LICENSE) for licensing details.
