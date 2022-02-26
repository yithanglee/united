defmodule UnitedWeb.FacebookPageController do
  use UnitedWeb, :controller

  alias United.Settings
  alias United.Settings.FacebookPage

  def index(conn, _params) do
    facebook_pages = Settings.list_facebook_pages()
    render(conn, "index.html", facebook_pages: facebook_pages)
  end

  def new(conn, _params) do
    changeset = Settings.change_facebook_page(%FacebookPage{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"facebook_page" => facebook_page_params}) do
    case Settings.create_facebook_page(facebook_page_params) do
      {:ok, facebook_page} ->
        conn
        |> put_flash(:info, "Facebook page created successfully.")
        |> redirect(to: Routes.facebook_page_path(conn, :show, facebook_page))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    facebook_page = Settings.get_facebook_page!(id)
    render(conn, "show.html", facebook_page: facebook_page)
  end

  def edit(conn, %{"id" => id}) do
    facebook_page = Settings.get_facebook_page!(id)
    changeset = Settings.change_facebook_page(facebook_page)
    render(conn, "edit.html", facebook_page: facebook_page, changeset: changeset)
  end

  def update(conn, %{"id" => id, "facebook_page" => facebook_page_params}) do
    facebook_page = Settings.get_facebook_page!(id)

    case Settings.update_facebook_page(facebook_page, facebook_page_params) do
      {:ok, facebook_page} ->
        conn
        |> put_flash(:info, "Facebook page updated successfully.")
        |> redirect(to: Routes.facebook_page_path(conn, :show, facebook_page))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", facebook_page: facebook_page, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    facebook_page = Settings.get_facebook_page!(id)
    {:ok, _facebook_page} = Settings.delete_facebook_page(facebook_page)

    conn
    |> put_flash(:info, "Facebook page deleted successfully.")
    |> redirect(to: Routes.facebook_page_path(conn, :index))
  end
end
