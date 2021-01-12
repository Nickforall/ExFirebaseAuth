defmodule ExFirebaseAuth.Token do
  defp get_public_key(keyid) do
    case :ets.lookup(ExFirebaseAuth.KeyStore, keyid) do
      [{_keyid, key}] ->
        key

      [] ->
        nil
    end
  end

  @spec issuer :: String.t()
  @doc ~S"""
  Returns the configured issuer

  ## Examples

      iex> ExFirebaseAuth.Token.issuer()
      "https://securetoken.google.com/project-123abc"
  """
  def issuer, do: Application.fetch_env!(:ex_firebase_auth, :issuer)

  @spec verify_token(String.t()) ::
          {:error, String.t()} | {:ok, String.t(), JOSE.JWT.t()}
  @doc ~S"""
  Verifies a token agains google's public keys. Returns {:ok, user_id, claims} if successful. {:error, _} otherwise.

  ## Examples

      iex> ExFirebaseAuth.Token.verify_token("ey.some.token")
      {:ok, "user id", %{}}

      iex> ExFirebaseAuth.Token.verify_token("ey.some.token")
      {:error, "Invalid JWT header, `kid` missing"}
  """
  def verify_token(token_string) do
    issuer = issuer()

    with {:jwtheader, %{fields: %{"kid" => kid}}} <-
           {:jwtheader, JOSE.JWT.peek_protected(token_string)},
         # read key from store
         {:key, %JOSE.JWK{} = key} <- {:key, get_public_key(kid)},
         # check if verify returns true and issuer matches
         {:verify, {true, %{fields: %{"iss" => ^issuer, "sub" => sub}} = data, _}} <-
           {:verify, JOSE.JWT.verify(key, token_string)} do
      {:ok, sub, data}
    else
      {:jwtheader, _} ->
        {:error, "Invalid JWT header, `kid` missing"}

      {:key, _} ->
        {:error, "Public key retrieved from google was not found or could not be parsed"}

      {:verify, _} ->
        {:error, "None of public keys matched auth token's key ids"}
    end
  end
end
