defmodule Zidolink.Media.Unsplash do
  @moduledoc "Fetches themed photos from Unsplash for the marketing pages."

  @base_url "https://api.unsplash.com/photos/random"

  def fetch(query) do
    access_key = System.get_env("UNSPLASH_ACCESS_KEY")

    case Req.get(@base_url,
           params: [query: query, orientation: "portrait", client_id: access_key]
         ) do
      {:ok, %{status: 200, body: body}} ->
        {:ok,
         %{
           url: body["urls"]["regular"],
           photographer: body["user"]["name"],
           profile_url: body["user"]["links"]["html"]
         }}

      {:ok, %{status: status}} ->
        {:error, "Unsplash returned status #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
