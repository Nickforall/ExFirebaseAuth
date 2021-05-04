defmodule ExFirebaseAuth.KeySource.Google do
  @moduledoc false

  @endpoint_url "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"

  @behaviour ExFirebaseAuth.KeySource

  def fetch_certificates do
    with {:ok, %Finch.Response{body: body, headers: headers}} <-
           Finch.build(:get, @endpoint_url) |> Finch.request(ExFirebaseAuthFinch),
         {:ok, json_data} <- Jason.decode(body) do
      {:ok, convert_to_jose_keys(json_data), get_max_age(headers)}
    else
      _ ->
        :error
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

  defp get_max_age(headers) do
    headers |> get_cache_control_header() |> get_get_max_age_from_cache_control()
  end

  defp get_cache_control_header(headers) do
    Enum.find(headers, fn {k, _v} -> k == "cache-control" end)
  end

  defp get_get_max_age_from_cache_control(nil) do
    300
  end

  defp get_get_max_age_from_cache_control({"cache-control", value}) do
    values = String.split(value, ",")

    Enum.find_value(values, fn x ->
      if x |> String.trim() |> String.starts_with?("max-age="), do: parse_max_age(x)
    end)
  end

  defp parse_max_age(x) do
    {integer, _rem} = x |> String.split("=") |> Enum.at(1) |> Integer.parse()
    integer
  end
end
