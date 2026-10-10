defmodule Zidolink.Avatars do
  @moduledoc "Shared label/initials/color logic for avatar display across the app."

  @colors [
    {"#FF6F5E", "#FFFFFF"},
    {"#0E7C5D", "#FFFFFF"},
    {"#FFC93C", "#241B2F"},
    {"#8B7AB8", "#FFFFFF"},
    {"#4A90D9", "#FFFFFF"}
  ]

  def label(display_name, email) do
    case display_name do
      name when is_binary(name) and name != "" -> name
      _ -> email
    end
  end

  def initials(display_name, email) do
    case display_name do
      name when is_binary(name) and name != "" ->
        name
        |> String.split(~r/\s+/, trim: true)
        |> Enum.take(2)
        |> Enum.map(&String.first/1)
        |> Enum.join()
        |> String.upcase()

      _ ->
        email
        |> String.split("@")
        |> List.first()
        |> String.slice(0, 2)
        |> String.upcase()
    end
  end

  def color(label) do
    index = :erlang.phash2(label, length(@colors))
    Enum.at(@colors, index)
  end
end
