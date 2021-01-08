defmodule ExFirebaseAuth.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_firebase_auth,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {ExFirebaseAuth, []},
      extra_applications: [:logger],
      registered: [ExFirebaseAuth.KeyStore]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jose, "~> 1.10"},
      {:finch, "~> 0.6.0"},
      {:jason, "~> 1.2.2"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      description: "Handling Firebase Auth 'ID tokens' in Elixir",
      links: %{
        "github" => "https://github.com/Nickforall/ExFirebaseAuth",
        "documentation" => "https://hexdocs.pm/ex_firebase_auth"
      },
      licenses: ["MIT"]
    ]
  end
end
