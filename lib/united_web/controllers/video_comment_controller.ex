defmodule UnitedWeb.VideoCommentController do
  use UnitedWeb, :controller

  alias United.Settings
  alias United.Settings.VideoComment

  def index(conn, _params) do
    video_comments = Settings.list_video_comments()
    render(conn, "index.html", video_comments: video_comments)
  end

  def new(conn, _params) do
    changeset = Settings.change_video_comment(%VideoComment{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"video_comment" => video_comment_params}) do
    case Settings.create_video_comment(video_comment_params) do
      {:ok, video_comment} ->
        conn
        |> put_flash(:info, "Video comment created successfully.")
        |> redirect(to: Routes.video_comment_path(conn, :show, video_comment))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    video_comment = Settings.get_video_comment!(id)
    render(conn, "show.html", video_comment: video_comment)
  end

  def edit(conn, %{"id" => id}) do
    video_comment = Settings.get_video_comment!(id)
    changeset = Settings.change_video_comment(video_comment)
    render(conn, "edit.html", video_comment: video_comment, changeset: changeset)
  end

  def update(conn, %{"id" => id, "video_comment" => video_comment_params}) do
    video_comment = Settings.get_video_comment!(id)

    case Settings.update_video_comment(video_comment, video_comment_params) do
      {:ok, video_comment} ->
        conn
        |> put_flash(:info, "Video comment updated successfully.")
        |> redirect(to: Routes.video_comment_path(conn, :show, video_comment))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", video_comment: video_comment, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    video_comment = Settings.get_video_comment!(id)
    {:ok, _video_comment} = Settings.delete_video_comment(video_comment)

    conn
    |> put_flash(:info, "Video comment deleted successfully.")
    |> redirect(to: Routes.video_comment_path(conn, :index))
  end
end
