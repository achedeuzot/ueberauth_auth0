# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
## v2.1.0 - 2022-10-27
- Support for `organization` and `invitation` query parameters
- Bumped dependencies

## v2.0.0 - 2021-08-14

- BREAKING CHANGE: changed error management on wrong OAuth code.
  Instead of raising a `OAuth2.Error`, the `conn.assigns.ueberauth_failure`
  is set with the following value:
  ```elixir
  %Ueberauth.Failure.Error{
    message: "Invalid authorization code",
    message_key: "invalid_grant"
  }
  ```
- Bumped dependencies

## v1.0.0 - 2020-07-10

- BREAKING CHANGE: bump `ueberauth` to `0.7.0` which provides default CSRF protection.
  In exchange for this new default protection, the `state` field is used by `ueberauth`
  to store the CSRF token.
- Documentation improvements

## v0.8.1 - 2020-08-18

- Adds query parameters used for the Universal Login: `screen_hint`,
  `login_hint` and `prompt`.
  See https://auth0.com/docs/universal-login/new-experience#signup

## v0.8.0 - 2020-08-18

- BREAKING CHANGE: the `%Extra{}` field now copies the full raw auth0 user into
  `%Extra{raw_info: %{user: auth0_user}}` instead of selected fields. This
  allows better usage with custom auth0 fields and other end-user customizations.
  (see PR #136)
- The `%Extra{}` field now also contains the raw auth0 token (if you ever
  need it) under `:token` in the `raw_info` map. This better follows other ueberauth
  strategies and can be useful in some cases.
- Bump dependencies

## v0.7.0 - 2020-07-30

- Changes in the accepted params that can be given to the
  `:request` endpoint: `audience`, `state`, `connection` and
  `scope`. Corresponding default values have been added to the
  configuration options.
- Improved error message on missing configuration.

## v0.6.0 - 2020-07-27

- Adds `%Extra{}` data with all fields from `/userinfo` mapped.
- BREAKING CHANGE: `locale` data is now stored in the `%Extra{}`
  field instead of the `%Info{location: ...}` field
- Bumped dependencies (earmark)

## v0.5.0 - 2020-07-24

- Drops support for Elixir 1.4, 1.5 and 1.6
- Adds integration tests suite
- `deps` update

## v0.4.0 - 2019-10-05

- Massive `deps` update, mainly `oauth2`.

## v0.3.0 - 2017-09-17

Thanks @sobolevn for updating the followings:

- Changed the `uid_field` to `sub` to match with the return from Auth0.
- Included `profile` scope by default.

## v0.2.0 - 2017-05-15

- Initial semantic release
