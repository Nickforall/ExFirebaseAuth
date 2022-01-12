# ExFirebaseAuth 🔥

ExFirebaseAuth is a library that handles ID tokens from Firebase, which is useful for using Firebase's auth solution because Firebase does not have an Elixir SDK for auth themselves. ExFirebaseAuth also comes with some testing utilities that mock and generate ID tokens for your integration tests.

[More information on how ID tokens work in Firebase Auth](https://firebase.google.com/docs/auth/admin/verify-id-tokens)

This library

- Keeps track of google's public keys used for signing ID tokens
- Verifies ID tokens
- Veries whether the issuer matches your firebase project

This library does **not**

- Aim to implement Firebase user admin SDK endpoints

## Installation

If [available in Hex](https://hex.pm/packages/ex_firebase_auth), the package can be installed
by adding `ex_firebase_auth` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_firebase_auth, "~> 0.5.1"}
  ]
end
```

## Usage

Add the Firebase auth issuer name for your project to your `config.exs`. This is required to make sure only your project's firebase tokens are accepted.

```elixir
config :ex_firebase_auth, :issuer, "https://securetoken.google.com/project-123abc"
```

Verifying a token

```elixir
ExFirebaseAuth.Token.verify_token("Some token string")
iex> {:ok, "userid", %{}}
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_firebase_auth](https://hexdocs.pm/ex_firebase_auth).
