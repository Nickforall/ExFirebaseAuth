defmodule ExFirebaseAuth.KeySource.Google do
  @moduledoc false

  @endpoint_urls [
    "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com",
    "https://www.googleapis.com/identitytoolkit/v3/relyingparty/publicKeys"
  ]

  @behaviour ExFirebaseAuth.KeySource

  def fetch_certificates do
    results =
      @endpoint_urls
      |> Enum.map(fn endpoint_url ->
        with {:ok, %Finch.Response{body: body}} <-
               Finch.build(:get, endpoint_url) |> Finch.request(ExFirebaseAuthFinch),
             {:ok, json_data} <- Jason.decode(body) do
          {:ok, convert_to_jose_keys(json_data)}
        else
          _ -> :error
        end
      end)

    if Enum.any?(results, &(&1 == :error)) do
      :error
    else
      {:ok, Enum.reduce(results, %{}, fn {:ok, result}, acc -> Enum.into(result, acc) end)}
    end
  end

  defp convert_to_jose_keys(json_data) do
    json_data
    |> Enum.map(fn {key, value} ->
      case JOSE.JWK.from_pem(value) do
        [] -> {key, nil}
        jwk -> {key, jwk}
      end
    end)
    |> Enum.filter(fn {_, value} -> not is_nil(value) end)
  end
end
