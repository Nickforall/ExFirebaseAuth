defmodule ExFirebaseAuth.KeyStoreTest do
  use ExUnit.Case

  setup do
    {kid, public_key, _} = ExFirebaseAuth.Mock.generate_key()

    Application.get_env(:ex_firebase_auth, :key_source, ExFirebaseAuth.KeySource.Mock)

    Application.put_env(:ex_firebase_auth, :key_source_mock,
      keys: [
        {kid, public_key}
      ]
    )

    %{kid: kid, key: public_key}
  end

  test "Does add new key to ets on refresh", %{kid: kid, key: public_key} do
    assert :ets.lookup(ExFirebaseAuth.KeyStore, kid) == []

    Process.send(ExFirebaseAuth.KeyStore, :refresh, [])

    # TODO: there's probably a better way to test this behavior
    Process.sleep(100)

    assert :ets.lookup(ExFirebaseAuth.KeyStore, kid) == [{kid, public_key}]
  end
end
