defmodule ExFirebaseAuth.KeyStore do
  @moduledoc """
  The KeyStore handles fetching public keys from Google's servers to verify public keys with

  ## Warnings

  By default ExFirebaseAuth.KeyStore will stop when the initial fetch failed. This behavior can be
  changed by the following config key:

  ```
  config :ex_firebase_auth, :key_store_fail_strategy, :silent
  ```

  The following values are available

  - `:stop`: Stops server after initial fetch fails.
  - `:warn`: Logs a warning message with Logger. Continues retrying to fetch.
  - `:silent`: Silently retries fetching new public keys, without warning when failing.
  """

  use GenServer, restart: :transient

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: ExFirebaseAuth.KeyStore)
  end

  @spec key_store_fail_strategy :: :stop | :warn | :silent
  @doc ~S"""
  Returns the configured key_store_fail_strategy

  ## Examples

      iex> ExFirebaseAuth.Token.key_store_fail_strategy()
      :stop
  """
  def key_store_fail_strategy,
    do: Application.get_env(:ex_firebase_auth, :key_store_fail_strategy, :stop)

  def init(_) do
    find_or_create_ets_table()

    case ExFirebaseAuth.KeySource.fetch_certificates() do
      :error ->
        case key_store_fail_strategy() do
          :stop ->
            {:stop,
             """
               Initial certificate fetch failed

               If you want to run ExFirebaseAuth offline during tests or development, add the following key to your config

               ```
               config :ex_firebase_auth, :key_store_fail_strategy, :silent
               ```
             """}

          :warn ->
            unless key_store_fail_strategy() == :silent do
              Logger.warning("Fetching firebase auth certificates failed. Retrying again shortly.")
            end

            schedule_refresh(10)

            {:ok, %{}}

          :silent ->
            schedule_refresh(10)

            {:ok, %{}}
        end

      {:ok, data} ->
        store_data_to_ets(data)

        Logger.debug("Fetched initial firebase auth certificates.")

        schedule_refresh()

        {:ok, %{}}
    end
  end

  # When the refresh `info` is sent, we want to fetch the certificates
  def handle_info(:refresh, state) do
    case ExFirebaseAuth.KeySource.fetch_certificates() do
      # keep trying with a lower interval, until then keep the old state
      :error ->
        Logger.warning("Fetching firebase auth certificates failed, using old state and retrying...")
        schedule_refresh(10)

      # if everything went okay, refresh at the regular interval and store the returned keys in state
      {:ok, keys} ->
        store_data_to_ets(keys)

        Logger.debug("Fetched new firebase auth certificates.")
        schedule_refresh()
    end

    {:noreply, state}
  end

  @doc false
  def find_or_create_ets_table do
    case :ets.whereis(ExFirebaseAuth.KeyStore) do
      :undefined -> :ets.new(ExFirebaseAuth.KeyStore, [:set, :public, :named_table])
      table -> table
    end
  end

  defp store_data_to_ets(data) do
    data
    |> Enum.each(fn {key, value} ->
      :ets.insert(ExFirebaseAuth.KeyStore, {key, value})
    end)
  end

  defp schedule_refresh(after_s \\ 300) do
    Process.send_after(self(), :refresh, after_s * 1000)
  end
end
