defmodule ExFirebaseAuth.KeyStore do
  @moduledoc false

  use GenServer, restart: :transient

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: ExFirebaseAuth.KeyStore)
  end

  def init(_) do
    find_or_create_ets_table()

    case ExFirebaseAuth.KeySource.fetch_certificates() do
      # when we could not fetch certs initially the application cannot run because all Auth will fail
      :error ->
        {:stop, "Initial certificate fetch failed"}

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
        Logger.warn("Fetching firebase auth certificates failed, using old state and retrying...")
        schedule_refresh(10)

      # if everything went okay, refresh at the regular interval and store the returned keys in state
      {:ok, keys} ->
        store_data_to_ets(keys)

        Logger.debug("Fetched new firebase auth certificates.")
        schedule_refresh()
    end

    {:noreply, state}
  end

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
