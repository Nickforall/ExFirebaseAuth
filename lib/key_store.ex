defmodule ExFirebaseAuth.KeyStore do
  @moduledoc false

  use GenServer, restart: :transient

  require Logger

  @endpoint_url "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: ExFirebaseAuth.KeyStore)
  end

  def init(_) do
    find_or_create_ets_table()

    case fetch_certificates() do
      # when we could not fetch certs initially the application cannot run because all Auth will fail
      :error ->
        {:stop, "Initial certificate fetch failed"}

      {:ok, data} ->
        store_data_to_ets(data)

        {:ok, %{}}
    end
  end

  # When the refresh `info` is sent, we want to fetch the certificates
  def handle_info(:refresh, state) do
    case fetch_certificates() do
      # keep trying with a lower interval, until then keep the old state
      :error ->
        Logger.warn("Fetching firebase auth certificates failed, using old state and retrying...")
        schedule_refresh(10)

        {:noreply, state}

      # if everything went okay, refresh at the regular interval and store the returned keys in state
      {:ok, jsondata} ->
        Logger.debug("Fetched new firebase auth certificates.")
        store_data_to_ets(jsondata)
        schedule_refresh()

        {:noreply, state}
    end
  end

  def find_or_create_ets_table do
    case :ets.whereis(ExFirebaseAuth.KeyStore) do
      :undefined -> :ets.new(ExFirebaseAuth.KeyStore, [:set, :public, :named_table])
      table -> table
    end
  end

  defp store_data_to_ets(jsondata) do
    jsondata
    |> Enum.map(fn {key, value} ->
      case JOSE.JWK.from_pem(value) do
        [] -> {key, nil}
        jwk -> {key, jwk}
      end
    end)
    |> Enum.filter(fn {_, value} -> not is_nil(value) end)
    |> Enum.each(fn {key, value} ->
      :ets.insert(ExFirebaseAuth.KeyStore, {key, value})
    end)
  end

  defp schedule_refresh(after_s \\ 3600) do
    Process.send_after(self(), :refresh, after_s * 1000)
  end

  # Fetch certificates from google's endpoint
  defp fetch_certificates do
    with {:ok, %Finch.Response{body: body}} <-
           Finch.build(:get, @endpoint_url) |> Finch.request(ExFirebaseAuthFinch),
         {:ok, jsondata} <- Jason.decode(body) do
      {:ok, jsondata}
    else
      _ ->
        :error
    end
  end
end
