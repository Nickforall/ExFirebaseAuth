defmodule ExFirebaseAuth.KeyStore do
  @moduledoc false

  use GenServer, restart: :transient

  require Logger

  @endpoint_url "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: ExFirebaseAuth.KeyStore)
  end

  def init(_) do
    case fetch_certificates() do
      # when we could not fetch certs initially the application cannot run because all Auth will fail
      :error -> {:stop, "Initial certificate fetch failed"}
      {:ok, data} -> {:ok, data}
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
        Logger.debug("Fetched new firebase auth certificates")
        schedule_refresh()
        {:noreply, jsondata}
    end
  end

  # Use a {:get, id} call to get the JWK struct of the certificate with the given key id. Returns nil if not found
  # Usage: `GenServer.call(ExFirebaseAuth.KeyStore, {:get, keyid})`
  def handle_call({:get, key_id}, _from, state) do
    case Map.get(state, key_id) do
      nil -> {:reply, nil, state}
      key -> {:reply, JOSE.JWK.from_pem(key), state}
    end
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
