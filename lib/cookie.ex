defmodule ExFirebaseAuth.Cookie do
  @doc ~S"""
  Returns the configured issuer

  ## Examples

      iex> ExFirebaseAuth.Token.issuer()
      "https://session.firebase.google.com/project-123abc"
  """
  def issuer, do: Application.fetch_env!(:ex_firebase_auth, :cookie_issuer)

  @spec verify(String.t()) ::
          {:error, String.t()} | {:ok, String.t(), JOSE.JWT.t()}
  @doc ~S"""
  Verifies a cookie token agains Google's public keys. Returns {:ok, user_id, claims} if successful. {:error, _} otherwise.

  ## Examples

      iex> ExFirebaseAuth.Cookie.verify("ey.some.token")
      {:ok, "user id", %{}}

      iex> ExFirebaseAuth.Cookie.verify("ey.some.token")
      {:error, "Invalid JWT header, `kid` missing"}
  """
  def verify(cookie_string) do
    ExFirebaseAuth.Token.verify_token(cookie_string, issuer())
  end
end
