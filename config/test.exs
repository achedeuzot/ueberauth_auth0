import Config

config :ueberauth, Ueberauth,
  json_library: Jason,
  providers: [
    auth0: {Ueberauth.Strategy.Auth0, []}
  ]

config :ueberauth, Ueberauth.Strategy.Auth0.OAuth,
  domain: "example-app.auth0.com",
  client_id: "clientidsomethingrandom",
  client_secret: "clientsecret-somethingsecret"

config :exvcr,
  vcr_cassette_library_dir: "test/fixtures/vcr_cassettes"

config :plug, :validate_header_keys_during_test, true
