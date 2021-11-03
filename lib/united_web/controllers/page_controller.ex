defmodule UnitedWeb.PageController do
  use UnitedWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
