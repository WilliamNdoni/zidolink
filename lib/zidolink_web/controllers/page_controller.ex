defmodule ZidolinkWeb.PageController do
  use ZidolinkWeb, :controller

  def home(conn, _params) do
    conn |> put_layout(false) |> render(:home)
  end
end
