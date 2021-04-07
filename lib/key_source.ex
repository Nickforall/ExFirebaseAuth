defmodule ExFirebaseAuth.KeySource do
  @moduledoc false

  @callback fetch_certificates() :: :error | {:ok, list(JOSE.JWK.t())}

  @source Application.get_env(:ex_firebase_auth, :key_source, ExFirebaseAuth.KeySource.Google)

  defdelegate fetch_certificates, to: @source
end
