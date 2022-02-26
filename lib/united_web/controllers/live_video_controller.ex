defmodule UnitedWeb.LiveVideoController do
  use UnitedWeb, :controller

  alias United.Settings
  alias United.Settings.LiveVideo

  def index(conn, _params) do
    live_videos = Settings.list_live_videos()
    render(conn, "index.html", live_videos: live_videos)
  end

  def new(conn, _params) do
    changeset = Settings.change_live_video(%LiveVideo{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"live_video" => live_video_params}) do
    case Settings.create_live_video(live_video_params) do
      {:ok, live_video} ->
        conn
        |> put_flash(:info, "Live video created successfully.")
        |> redirect(to: Routes.live_video_path(conn, :show, live_video))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    live_video = Settings.get_live_video!(id)
    render(conn, "show.html", live_video: live_video)
  end

  def edit(conn, %{"id" => id}) do
    live_video = Settings.get_live_video!(id)
    changeset = Settings.change_live_video(live_video)
    render(conn, "edit.html", live_video: live_video, changeset: changeset)
  end

  def update(conn, %{"id" => id, "live_video" => live_video_params}) do
    live_video = Settings.get_live_video!(id)

    case Settings.update_live_video(live_video, live_video_params) do
      {:ok, live_video} ->
        conn
        |> put_flash(:info, "Live video updated successfully.")
        |> redirect(to: Routes.live_video_path(conn, :show, live_video))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", live_video: live_video, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    live_video = Settings.get_live_video!(id)
    {:ok, _live_video} = Settings.delete_live_video(live_video)

    conn
    |> put_flash(:info, "Live video deleted successfully.")
    |> redirect(to: Routes.live_video_path(conn, :index))
  end
end
