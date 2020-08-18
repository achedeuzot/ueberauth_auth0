# Changelog

## Upcoming

## Version 0.8.0

- BREAKING CHANGE: the `%Extra{}` field now copies the full raw auth0 user into
  `%Extra{raw_info: %{user: auth0_user}}` instead of selected fields. This
  allows better usage with custom auth0 fields and other end-user customizations.
  (see PR #136)
- The `%Extra{}` field now also contains the raw auth0 token (if you ever
  need it) under `:token` in the `raw_info` map. This better follows other ueberauth
  strategies and can be useful in some cases.
- Bump dependencies

## Version 0.7.0

- Changes in the accepted params that can be given to the
  `:request` endpoint: `audience`, `state`, `connection` and
  `scope`. Corresponding default values have been added to the
  configuration options.
- Improved error message on missing configuration.

## Version 0.6.0

- Adds `%Extra{}` data with all fields from `/userinfo` mapped.
- BREAKING CHANGE: `locale` data is now stored in the `%Extra{}`
  field instead of the `%Info{location: ...}` field
- Bumped dependencies (earmark)

## Version 0.5.0

- Drops support for Elixir 1.4, 1.5 and 1.6
- Adds integration tests suite
- `deps` update

## Version 0.4.0

- Massive `deps` update, mainly `oauth2`.

## Version 0.3.0

Thanks @sobolevn for updating the followings:

- Changed the `uid_field` to `sub` to match with the return from Auth0.
- Included `profile` scope by default.

## Version 0.2.0

Initial semantic release
