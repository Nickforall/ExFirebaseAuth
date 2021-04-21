# ExFirebaseAuth 🔥

[![CI](https://github.com/Nickforall/ExFirebaseAuth/actions/workflows/elixir.yml/badge.svg)](https://github.com/Nickforall/ExFirebaseAuth/actions/workflows/elixir.yml)

ExFirebaseAuth is an Elixir library to handle ID Tokens from the [Firebase Authentication service](https://firebase.google.com/products/auth).

This library:

- validates ID Tokens and unpack its user information
- keeps track of Google public keys used for signing ID Tokens
- comes with test utils to mock ID Tokens in dev/test environments
- does not aim to implement the Firebase Admin SDK endpoints

[Read more about Firebase Authentication ID Tokens here.](https://firebase.google.com/docs/auth/admin/verify-id-tokens)

## Installation

The package can be installed by adding `ex_firebase_auth` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_firebase_auth, "~> 0.4.0"}
  ]
end
```

## Configuration

Configure the ID Token issuer in your `config.exs`. This is required to ensure that only ID Tokens from your own project will be accepted:

```elixir
config :ex_firebase_auth, :issuer, "https://securetoken.google.com/project-123abc"
```

## Usage

To verify an ID Token, use `ExFirebaseAuth.Token.verify_token/1`:

```elixir

iex(1)> ExFirebaseAuth.Token.verify_token("<Some valid Firebase ID Token goes here>")
{:ok, "<User UID goes here>",
  %JOSE.JWT{
    fields: %{
      "email" => "jose@valim.com",
      "email_verified" => true,
      "name" => "<User name>",
      "picture" => "<User picture URL>",
      "user_id" => "<User UID>",
      # (...) among other fields (...)
    }
  }}
```

> _Note: be careful to not confuse User UIDs with Firebase ID Tokens. Firebase UIDs are normal unique user IDs, while Firebase ID Tokens are full-featured JSON Web Tokens, meant for cross-system user authentication._

Complete documentation can be found at [https://hexdocs.pm/ex_firebase_auth](https://hexdocs.pm/ex_firebase_auth/).

## License

[MIT](LICENSE)
