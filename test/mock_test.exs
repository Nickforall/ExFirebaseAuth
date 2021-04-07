defmodule ExFirebaseAuth.MockTest do
  use ExUnit.Case

  alias ExFirebaseAuth.Mock

  setup do
    on_exit(fn ->
      :ok = Application.delete_env(:ex_firebase_auth, :mock)
    end)
  end

  describe "Token.generate_and_store_key_pair/0" do
    test "Fails when mock is disabled" do
      assert_raise(
        RuntimeError,
        ~r/^Cannot generate mocked token, because ExFirebaseAuth.Mock is not enabled in your config./,
        fn ->
          Mock.generate_and_store_key_pair()
        end
      )
    end

    test "Creates ETS table and stores key" do
      Application.put_env(:ex_firebase_auth, :mock, enabled: true)

      assert :ets.whereis(ExFirebaseAuth.Mock) == :undefined
      Mock.generate_and_store_key_pair()

      [{_, %JOSE.JWK{} = _}] = :ets.lookup(ExFirebaseAuth.Mock, :ets.first(ExFirebaseAuth.Mock))
    end
  end
end
