defmodule UnitedWeb.PageController do
  use UnitedWeb, :controller
  require IEx

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def show_page(conn, params) do
    render(conn, "show.html", params)
  end

  def member_dashboard(conn, _params) do
    render(conn, "member_dashboard.html", layout: {UnitedWeb.LayoutView, "member.html"})
  end

  def dashboard(conn, _params) do
    render(conn, "dashboard.html")
  end
end
