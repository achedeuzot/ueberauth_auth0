defmodule Ueberauth.Strategy.Auth0.Token do

  def validation(otp_app, client) do
    # full JWT validation
    # see the following jose issue on validation
    # https://github.com/potatosalad/erlang-jose/issues/28

    configs = Application.get_env(otp_app || :ueberauth, Ueberauth.Strategy.Auth0.OAuth)

    base_url = client.site
    jwks_cache_id = Keyword.get(configs, :cachex_cache_id, nil)

    # we want the raw JWT rather than the parsed result

    jwt = Map.get(client.token.other_params, "id_token")

    with {:jwks, {:ok, jwks}} <- {:jwks, jwks(jwks_cache_id, base_url)},
      {:keys_by_alg_kid, {:ok, keys}} <- {:keys_by_alg_kid, keys_by_alg_kid(jwks)},
      {:alg_and_kid, {:ok, %{"alg" => alg, "kid" => kid}}} <- {:alg_and_kid, alg_and_kid(jwt)},
      {:jwt_verify, {true, payload, jws}} <- {:jwt_verify, jwt_verify(keys, jwt, alg, kid)}
    do
      {:ok, {payload, jws}}
    else
      {:jwks, err} -> {:error, {:jwks, err}}
      {:keys_by_alg_kid, err} -> {:error, {:keys_by_alg_kid, err}}
      {:alg_and_kid, err} -> {:error, {:alg_and_kid, err}}
      {:jwt_verify, err} -> {:error, {:jwt_verify, err}}
      err -> {:error, {:unknown, err}}
    end
  end

  defp jwt_verify(keys, token, alg, kid) do

    # perform the validation with the relevant key and algorithm
    # the payload has the exact same data as before, but now it is trustworthy.

    key = Map.get(keys, {alg, kid})

    JOSE.JWS.verify_strict(key, [alg], token)

  end

  defp alg_and_kid(token) do
    # we want the the algorithm and key ID of the signed JWT.
    # these are safe to get since they describe _how_ the JWT is signed

    token
      |> JOSE.JWS.peek_protected()
      |> Jason.decode()
  end

  defp keys_by_alg_kid(jwks) do
    keys_by_alg_kid =
      jwks
      |> Map.fetch!("keys")
      |> Enum.map(&JOSE.JWK.from/1)
      |> Enum.map(fn k = %JOSE.JWK{fields: %{"alg" => alg, "kid" => kid}} -> {{alg, kid}, k} end)
      |> Enum.into(%{})
    {:ok, keys_by_alg_kid}
  end

  defp jwks(nil, site_url) do
    # no caching JWKS data in cachex
    jwks_fetch(site_url)
  end

  defp jwks(cache_id, site_url) do

    # there should only be one JWKS data set per domain
    # so the host is an ideal cache key

    cache_key =
      site_url
      |> URI.parse()
      |> Map.get(:host)

    cache_ttl = 86400 # 24 hours

    case Cachex.get(cache_id, cache_key) do
      {:ok, nil} ->
        # cache exists, no JWKS data

        # forcing a store-fetch-decode to make sure it crashes and burns instantly
        # rather than on the second request
        with {:jwks_fetch, {:ok, jwks_data}} <- {:jwks_fetch, jwks_fetch(site_url)},
          {:jwks_encode, {:ok, jwks_json_data}} <- {:jwks_encode, Jason.encode(jwks_data)},
          {:jwks_cache_store, {:ok, true}} <- {:jwks_cache_store, Cachex.put(cache_id, cache_key, jwks_json_data, ttl: cache_ttl)},
          {:jwks_cache_fetch, {:ok, jwks_encoded}} <- {:jwks_cache_fetch, Cachex.get(cache_id, cache_key)},
          {:jwks_cache_decode, {:ok, jwks_data}} <- {:jwks_cache_decode, Jason.decode(jwks_encoded)}
        do
          {:ok, jwks_data}
        else
          {:jwks_fetch, err} -> {:error, {:jwks_fetch, err}}
          {:jwks_encode, err} -> {:error, {:jwks_encode, err}}
          {:jwks_cache_store, err} -> {:error, {:jwks_cache_store, err}}
          {:jwks_cache_fetch, err} -> {:error, {:jwks_cache_fetch, err}}
          {:jwks_cache_decode, err} -> {:error, {:jwks_cache_decode, err}}
        end

      {:ok, result} ->
        # cache and key exist
        Jason.decode(result)

      {:error, err} ->
        # something broke
        {:error, err}
      end
    end
  defp jwks_fetch(site_url) do
    # construct the JWKS URL as per auth0 documentation, then fetch the JWKS key blob.
    # https://auth0.com/docs/tokens/json-web-tokens/json-web-key-sets/locate-json-web-key-sets

    auth0_openid_url =
      site_url
      |> URI.parse()
      |> URI.merge("/.well-known/openid-configuration")
      |> to_string()

    with {:openid_fetch, {:ok, %Mojito.Response{body: openid_body, status_code: 200}}} <- {:openid_fetch, Mojito.get(auth0_openid_url)},
        {:openid_decode, {:ok, %{"jwks_uri" => auth0_jwks_url}}} <- {:openid_decode, Jason.decode(openid_body)},
        {:jwks_fetch, {:ok, %Mojito.Response{body: jwks_body, status_code: 200}}} <- {:jwks_fetch, Mojito.get(auth0_jwks_url)},
        {:jwks_decode, {:ok, jwks}} <- {:jwks_decode, Jason.decode(jwks_body)}
    do
      {:ok, jwks}
    else
      {:openid_fetch, err} -> {:error, {:openid_fetch, err}}
      {:openid_decode, err} -> {:error, {:openid_decode, err}}
      {:jwks_fetch, err} -> {:error, {:jwks_fetch, err}}
      {:jwks_decode, err} -> {:error, {:jwks_decode, err}}
      err -> {:error, {:unknown, err}}
    end
  end

end
