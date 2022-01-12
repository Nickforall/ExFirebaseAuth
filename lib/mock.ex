defmodule ExFirebaseAuth.Mock do
  @moduledoc """
  This module will generate a public-private keypair and store it in ExFirebaseAuth's ETS tables.
  You can create ID tokens identical to Firebase's tokens for use in integrating testing your auth
  stack.

  When enabled, tokens generated from this mock will be accepted by ExFirebaseAuth.Token.verify_token/1

  ## Enabling the mock
  In order to prevent non-google tokens from being added to real-world environments, you need to
  enable the mock in your app's configuration.

  ```elixir
  config :ex_firebase_auth, :mock,
    enabled: true # defaults to false
  ```
  """

  @spec is_enabled? :: boolean()
  @doc """
  Returns whether mocking is enabled, returns false by default
  """
  def is_enabled?, do: Keyword.get(mock_config(), :enabled, false)

  @spec generate_and_store_key_pair :: any()
  @doc """
  Generates and stores a new key pair in ETS tables. **Note: this already gets called on app init,
  you probably do not need this.**
  """
  def generate_and_store_key_pair do
    unless is_enabled?() do
      raise "Cannot generate mocked token, because ExFirebaseAuth.Mock is not enabled in your config."
    end

    private_table = find_or_create_private_key_table()
    public_table = ExFirebaseAuth.KeyStore.find_or_create_ets_table()

    {kid, public_key, private_key} = generate_key()

    :ets.insert(private_table, {kid, private_key})
    :ets.insert(public_table, {kid, public_key})
  end

  @doc false
  def generate_key do
    private_key = JOSE.JWS.generate_key(%{"alg" => "RS256"})
    public_key = JOSE.JWK.to_public(private_key)

    kid = JOSE.JWK.thumbprint(:md5, public_key)

    {kid, public_key, private_key}
  end

  @spec generate_token(String.t(), map) :: String.t()
  @doc ~S"""
  Generates a firebase-like ID token with the mock's private key. Will raise when mock is not enabled.

  ## Examples

      iex> ExFirebaseAuth.Mock.generate_token("userid", %{"claim" => "value"})
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjEzMDA4MTkzODAsImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlLCJpc3MiOiJqb2UifQ.shLcxOl_HBBsOTvPnskfIlxHUibPN7Y9T4LhPB-iBwM"
  """
  def generate_token(sub, claims \\ %{}) do
    unless is_enabled?() do
      raise "Cannot generate mocked token, because ExFirebaseAuth.Mock is not enabled in your config."
    end

    {kid, jwk} = get_private_key()

    jws = %{
      "alg" => "RS256",
      "kid" => kid
    }

    # Put exp claim, unless previously specified in claims
    exp = DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.to_unix()
    claims = Map.put_new(claims, "exp", exp)

    jwt =
      Map.merge(claims, %{
        "iss" => ExFirebaseAuth.Token.issuer(),
        "sub" => sub
      })

    {_, payload} = JOSE.JWT.sign(jwk, jws, jwt) |> JOSE.JWS.compact()

    payload
  end

  defp mock_config, do: Application.get_env(:ex_firebase_auth, :mock, [])

  defp find_or_create_private_key_table do
    case :ets.whereis(ExFirebaseAuth.Mock) do
      :undefined -> :ets.new(ExFirebaseAuth.Mock, [:set, :public, :named_table])
      table -> table
    end
  end

  defp get_private_key do
    case :ets.lookup(ExFirebaseAuth.Mock, :ets.first(ExFirebaseAuth.Mock)) do
      [] -> raise "No private key set for ExFirebaseAuth.Mock, is mock enabled?"
      [{_kid, _key} = value] -> value
    end
  end
end
