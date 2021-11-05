defmodule UnitedWeb.StoredMediaController do
  use UnitedWeb, :controller

  alias United.Settings
  alias United.Settings.StoredMedia

  def index(conn, _params) do
    stored_medias = Settings.list_stored_medias()
    render(conn, "index.html", stored_medias: stored_medias)
  end

  def new(conn, _params) do
    changeset = Settings.change_stored_media(%StoredMedia{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"stored_media" => stored_media_params}) do
    case Settings.create_stored_media(stored_media_params) do
      {:ok, stored_media} ->
        conn
        |> put_flash(:info, "Stored media created successfully.")
        |> redirect(to: Routes.stored_media_path(conn, :show, stored_media))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    stored_media = Settings.get_stored_media!(id)
    render(conn, "show.html", stored_media: stored_media)
  end

  def edit(conn, %{"id" => id}) do
    stored_media = Settings.get_stored_media!(id)
    changeset = Settings.change_stored_media(stored_media)
    render(conn, "edit.html", stored_media: stored_media, changeset: changeset)
  end

  def update(conn, %{"id" => id, "stored_media" => stored_media_params}) do
    stored_media = Settings.get_stored_media!(id)

    case Settings.update_stored_media(stored_media, stored_media_params) do
      {:ok, stored_media} ->
        conn
        |> put_flash(:info, "Stored media updated successfully.")
        |> redirect(to: Routes.stored_media_path(conn, :show, stored_media))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", stored_media: stored_media, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    stored_media = Settings.get_stored_media!(id)
    {:ok, _stored_media} = Settings.delete_stored_media(stored_media)

    conn
    |> put_flash(:info, "Stored media deleted successfully.")
    |> redirect(to: Routes.stored_media_path(conn, :index))
  end
end
