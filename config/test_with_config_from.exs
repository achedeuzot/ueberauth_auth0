use Mix.Config

import_config "test.exs"

config :ueberauth, Ueberauth.Strategy.Auth0.OAuth,
  config_from: Ueberauth.Support.ConfigFrom
