defmodule ZidolinkWeb.TimeHelpers do
  @doc "Formats a UTC datetime as East Africa Time (UTC+3, no DST), for display anywhere in the app."
  def format_eat(datetime) do
    datetime
    |> DateTime.add(3, :hour)
    |> Calendar.strftime("%d %b %Y, %H:%M")
  end
end
