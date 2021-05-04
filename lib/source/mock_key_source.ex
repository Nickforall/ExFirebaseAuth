defmodule ExFirebaseAuth.KeySource.Mock do
  @moduledoc false

  @behaviour ExFirebaseAuth.KeySource

  defp config do
    Application.get_env(:ex_firebase_auth, :key_source_mock, keys: [])
  end

  def fetch_certificates do
    {:ok, config()[:keys], 300}
  end
end
