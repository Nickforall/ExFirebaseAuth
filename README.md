# ExFirebaseAuth 🔥

ExFirebaseAuth is a library that handles ID tokens from Firebase, which is useful for using Firebase's auth solution because Firebase does not have an Elixir SDK for auth themselves.

This library

- Keeps track of google's public keys used for signing ID tokens
- Verifies ID tokens
- Veries whether the issuer matches your firebase project

This library does **not**

- Aim to implement Firebase user admin SDK endpoints

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_firebase_auth` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_firebase_auth, "~> 0.1.0"}
  ]
end
```

And add the Firebase auth issuer name for your project to your `config.exs`.

```elixir
config :ex_firebase_auth, :issuer, "https://securetoken.google.com/hoody-16c66"
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_firebase_auth](https://hexdocs.pm/ex_firebase_auth).
