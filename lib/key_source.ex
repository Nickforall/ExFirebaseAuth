defmodule ExFirebaseAuth.KeySource do
  @moduledoc false

  @callback fetch_certificates() :: :error | {:ok, list(JOSE.JWK.t())}

  def fetch_certificates do
    apply(
      Application.get_env(:ex_firebase_auth, :key_source, ExFirebaseAuth.KeySource.Google),
      :fetch_certificates,
      []
    )
  end
end
