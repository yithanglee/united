defmodule UnitedWeb.PageVisitorController do
  use UnitedWeb, :controller

  alias United.Settings
  alias United.Settings.PageVisitor

  def index(conn, _params) do
    page_visitors = Settings.list_page_visitors()
    render(conn, "index.html", page_visitors: page_visitors)
  end

  def new(conn, _params) do
    changeset = Settings.change_page_visitor(%PageVisitor{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"page_visitor" => page_visitor_params}) do
    case Settings.create_page_visitor(page_visitor_params) do
      {:ok, page_visitor} ->
        conn
        |> put_flash(:info, "Page visitor created successfully.")
        |> redirect(to: Routes.page_visitor_path(conn, :show, page_visitor))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    page_visitor = Settings.get_page_visitor!(id)
    render(conn, "show.html", page_visitor: page_visitor)
  end

  def edit(conn, %{"id" => id}) do
    page_visitor = Settings.get_page_visitor!(id)
    changeset = Settings.change_page_visitor(page_visitor)
    render(conn, "edit.html", page_visitor: page_visitor, changeset: changeset)
  end

  def update(conn, %{"id" => id, "page_visitor" => page_visitor_params}) do
    page_visitor = Settings.get_page_visitor!(id)

    case Settings.update_page_visitor(page_visitor, page_visitor_params) do
      {:ok, page_visitor} ->
        conn
        |> put_flash(:info, "Page visitor updated successfully.")
        |> redirect(to: Routes.page_visitor_path(conn, :show, page_visitor))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", page_visitor: page_visitor, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    page_visitor = Settings.get_page_visitor!(id)
    {:ok, _page_visitor} = Settings.delete_page_visitor(page_visitor)

    conn
    |> put_flash(:info, "Page visitor deleted successfully.")
    |> redirect(to: Routes.page_visitor_path(conn, :index))
  end
end
