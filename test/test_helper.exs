defmodule SpecRouter do
  # Credit goes to:
  # https://github.com/he9qi/ueberauth_weibo/blob/master/test/test_helper.exs
  # and
  # https://github.com/ueberauth/ueberauth_vk/blob/master/test/test_helper.exs

  require Ueberauth
  use Plug.Router

  @session_options [
    store: :cookie,
    key: "_my_key",
    signing_salt: "CXlmrshG"
  ]

  plug(Plug.Session, @session_options)

  plug(:fetch_query_params)

  plug(Ueberauth, base_path: "/auth")

  plug(:match)
  plug(:dispatch)

  get("/auth/auth0", do: send_resp(conn, 200, "auth0 request"))

  get("/auth/auth0/callback", do: send_resp(conn, 200, "auth0 callback"))
end

defmodule SpecSignerModule do
  def get do
    Joken.Signer.create("HS256", "super-secret-secret")
  end
end

ExUnit.start()
