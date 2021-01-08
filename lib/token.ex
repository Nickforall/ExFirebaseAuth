defmodule ExFirebaseAuth.Token do
  defp get_public_key(keyid) do
    GenServer.call(ExFirebaseAuth.KeyStore, {:get, keyid})
  end

  @spec verify_token(binary) ::
          {:error, binary} | {:ok, binary(), JOSE.JWT.t()}
  @doc """
  Verifies a token agains google's public keys. Returns {:ok, user_id, claims} if successful. {:error, _} otherwise.

  ## Examples
    iex> ExFirebaseAuth.Token.verify_token("ey.some.token")
    {:ok, "user id", %{}}

    iex> ExFirebaseAuth.Token.verify_token("ey.some.token")
    {:error, "Invalid JWT header, `kid` missing"}
  """
  def verify_token(token_string) do
    issuer = Application.fetch_env!(:ex_firebase_auth, :issuer)

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
        {:error, "Public key retrieved from google could not be parsed"}

      {:verify, _} ->
        {:error, "None of public keys matched auth token's key ids"}
    end
  end
end
