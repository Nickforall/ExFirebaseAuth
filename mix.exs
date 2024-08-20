defmodule ExFirebaseAuth.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_firebase_auth,
      version: "0.5.2",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      aliases: [test: "test"],
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
      {:jose, "~> 1.10.0"},
      {:finch, "~> 0.16.0"},
      {:jason, "~> 1.4.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      description: "Handle ID Tokens from the Firebase Authentication service",
      links: %{
        "GitHub" => "https://github.com/Nickforall/ExFirebaseAuth"
      },
      licenses: ["MIT"]
    ]
  end
end
