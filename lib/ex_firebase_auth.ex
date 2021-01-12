defmodule ExFirebaseAuth do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      {Finch, name: ExFirebaseAuthFinch},
      {ExFirebaseAuth.KeyStore, name: ExFirebaseAuth.KeyStore}
    ]

    if ExFirebaseAuth.Mock.is_enabled?() do
      ExFirebaseAuth.Mock.generate_and_store_key_pair()
    end

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExFirebaseAuth.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
