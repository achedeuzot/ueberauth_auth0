# Changelog

## Upcoming

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
