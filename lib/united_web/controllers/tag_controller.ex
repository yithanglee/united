defmodule UnitedWeb.TagController do
  use UnitedWeb, :controller

  alias United.Settings
  alias United.Settings.Tag

  def index(conn, _params) do
    tags = Settings.list_tags()
    render(conn, "index.html", tags: tags)
  end

  def new(conn, _params) do
    changeset = Settings.change_tag(%Tag{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"tag" => tag_params}) do
    case Settings.create_tag(tag_params) do
      {:ok, tag} ->
        conn
        |> put_flash(:info, "Tag created successfully.")
        |> redirect(to: Routes.tag_path(conn, :show, tag))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    tag = Settings.get_tag!(id)
    render(conn, "show.html", tag: tag)
  end

  def edit(conn, %{"id" => id}) do
    tag = Settings.get_tag!(id)
    changeset = Settings.change_tag(tag)
    render(conn, "edit.html", tag: tag, changeset: changeset)
  end

  def update(conn, %{"id" => id, "tag" => tag_params}) do
    tag = Settings.get_tag!(id)

    case Settings.update_tag(tag, tag_params) do
      {:ok, tag} ->
        conn
        |> put_flash(:info, "Tag updated successfully.")
        |> redirect(to: Routes.tag_path(conn, :show, tag))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", tag: tag, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    tag = Settings.get_tag!(id)
    {:ok, _tag} = Settings.delete_tag(tag)

    conn
    |> put_flash(:info, "Tag deleted successfully.")
    |> redirect(to: Routes.tag_path(conn, :index))
  end
end
