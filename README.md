# Überauth Auth0

[![Build Status](https://github.com/achedeuzot/ueberauth_auth0/workflows/tests/badge.svg)](https://github.com/achedeuzot/ueberauth_auth0/actions?query=workflow%3Atests+branch%3Amaster)
[![Coverage Status](https://coveralls.io/repos/github/achedeuzot/ueberauth_auth0/badge.svg?branch=master)](https://coveralls.io/github/achedeuzot/ueberauth_auth0?branch=master)
[![Module Version](https://img.shields.io/hexpm/v/ueberauth_auth0.svg)](https://hex.pm/packages/ueberauth_auth0)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ueberauth_auth0/)
[![Total Download](https://img.shields.io/hexpm/dt/ueberauth_auth0.svg)](https://hex.pm/packages/ueberauth_auth0)
[![License](https://img.shields.io/hexpm/l/ueberauth_auth0.svg)](https://github.com/achedeuzot/ueberauth_auth0/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/achedeuzot/ueberauth_auth0.svg)](https://github.com/achedeuzot/ueberauth_auth0/commits/master)

> Auth0 OAuth2 strategy for Überauth.

## Installation

1.  Set up your Auth0 application at [Auth0 dashboard](https://manage.auth0.com/#/applications).

2.  Add `:ueberauth_auth0` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [
        {:ueberauth_auth0, "~> 2.0"}
      ]
    end
    ```

3.  Ensure `ueberauth_auth0` is started before your application:

    ```elixir
    def application do
      [
        applications: [:ueberauth_auth0]
      ]
    end
    ```

4.  Add Auth0 to your Überauth configuration:

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

5.  Update your provider configuration:

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

    **or** with computed configurations:

    ```elixir
    defmodule MyApp.ConfigFrom do
      def get_domain(%Plug.Conn{} = conn) do
        ...
      end

      def get_client_id(%Plug.Conn{} = conn) do
        ...
      end

      def get_client_secret(%Plug.Conn{} = conn) do
        ...
      end
    end
    ```

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Auth0.OAuth,
      config_from: MyApp.ConfigFrom
    ```

    See the `Ueberauth.Strategy.Auth0` module docs for more
    configuration options.

6.  Include the Überauth plug in your controller:

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

7.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

8. You controller needs to implement callbacks to deal with Ueberauth.Auth and Ueberauth.Failure responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Learn about OAuth2
[OAuth2 explained with cute shapes](https://engineering.backmarket.com/oauth2-explained-with-cute-shapes-7eae51f20d38)

## Copyright and License

Copyright (c) 2015 Son Tran-Nguyen \
Copyright (c) 2020 Klemen Sever

This library is released under the MIT License. See the [LICENSE.md](./LICENSE.md) file
for further details.
