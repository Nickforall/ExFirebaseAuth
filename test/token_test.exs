defmodule ExFirebaseAuth.TokenTest do
  use ExUnit.Case

  alias ExFirebaseAuth.{
    Token,
    Mock
  }

  defp generate_token(claims, jws) do
    [{_kid, jwk}] = :ets.lookup(ExFirebaseAuth.Mock, :ets.first(ExFirebaseAuth.Mock))

    {_, payload} = JOSE.JWT.sign(jwk, jws, claims) |> JOSE.JWS.compact()

    payload
  end

  setup do
    Application.put_env(:ex_firebase_auth, :mock, enabled: true)
    Mock.generate_and_store_key_pair()

    on_exit(fn ->
      :ok = Application.delete_env(:ex_firebase_auth, :mock)
      :ok = Application.delete_env(:ex_firebase_auth, :issuer)
    end)
  end

  describe "Token.verify_token/1" do
    test "Does succeed on correct token" do
      issuer = Enum.random(?a..?z)
      Application.put_env(:ex_firebase_auth, :issuer, issuer)

      sub = Enum.random(?a..?z)
      time_in_future = DateTime.utc_now() |> DateTime.add(360, :second) |> DateTime.to_unix()
      claims = %{"exp" => time_in_future}
      valid_token = Mock.generate_token(sub, claims)
      assert {:ok, ^sub, jwt} = Token.verify_token(valid_token)

      %JOSE.JWT{
        fields: %{
          "iss" => iss_claim,
          "sub" => sub_claim
        }
      } = jwt

      assert sub_claim == sub
      assert iss_claim == issuer
    end

    test "Does raise on no issuer being set" do
      Application.put_env(:ex_firebase_auth, :issuer, "issuer")
      valid_token = Mock.generate_token("subsub")
      Application.delete_env(:ex_firebase_auth, :issuer)

      assert_raise(
        ArgumentError,
        ~r/^could not fetch application environment :issuer for application :ex_firebase_auth because configuration at :issuer was not set/,
        fn ->
          Token.verify_token(valid_token)
        end
      )
    end

    test "Does fail on no `kid` being set in JWT header" do
      sub = Enum.random(?a..?z)
      Application.put_env(:ex_firebase_auth, :issuer, "issuer")

      token =
        generate_token(
          %{
            "sub" => sub,
            "iss" => "issuer"
          },
          %{
            "alg" => "RS256"
          }
        )

      assert {:error, "Invalid JWT header, `kid` missing"} = Token.verify_token(token)
    end
  end

  test "Does fail invalid kid being set" do
    sub = Enum.random(?a..?z)
    Application.put_env(:ex_firebase_auth, :issuer, "issuer")

    token =
      generate_token(
        %{
          "sub" => sub,
          "iss" => "issuer"
        },
        %{
          "alg" => "RS256",
          "kid" => "bogusbogus"
        }
      )

    assert {:error, "Public key retrieved from google was not found or could not be parsed"} =
             Token.verify_token(token)
  end

  test "Does fail on invalid signature with non-matching kid" do
    sub = Enum.random(?a..?z)
    Application.put_env(:ex_firebase_auth, :issuer, "issuer")

    {_invalid_kid, public_key, private_key} = Mock.generate_key()

    _invalid_kid = JOSE.JWK.thumbprint(:md5, public_key)
    [{valid_kid, _}] = :ets.lookup(ExFirebaseAuth.Mock, :ets.first(ExFirebaseAuth.Mock))

    {_, token} =
      JOSE.JWT.sign(
        private_key,
        %{
          "alg" => "RS256",
          "kid" => valid_kid
        },
        %{
          "sub" => sub,
          "iss" => "issuer"
        }
      )
      |> JOSE.JWS.compact()

    assert {:error, "Invalid signature"} = Token.verify_token(token)
  end

  test "Does fail on invalid issuer" do
    sub = Enum.random(?a..?z)
    Application.put_env(:ex_firebase_auth, :issuer, "issuer")

    [{kid, _}] = :ets.lookup(ExFirebaseAuth.Mock, :ets.first(ExFirebaseAuth.Mock))

    token =
      generate_token(
        %{
          "sub" => sub,
          "iss" => "bogusissuer"
        },
        %{
          "alg" => "RS256",
          "kid" => kid
        }
      )

    assert {:error, "Signed by invalid issuer"} = Token.verify_token(token)
  end

  test "Does fail on invalid JWT with raised exception handled" do
    Application.put_env(:ex_firebase_auth, :issuer, "issuer")

    invalid_token = "invalid.jwt.token"

    assert {:error, "Invalid JWT"} = Token.verify_token(invalid_token)
  end

  test "Does fail on expired JWT" do
    issuer = Enum.random(?a..?z)
    Application.put_env(:ex_firebase_auth, :issuer, issuer)

    sub = Enum.random(?a..?z)

    time_in_past = DateTime.utc_now() |> DateTime.add(-60, :second) |> DateTime.to_unix()
    claims = %{"exp" => time_in_past}

    valid_token = Mock.generate_token(sub, claims)

    assert {:error, "Expired JWT"} = Token.verify_token(valid_token)
  end
end
