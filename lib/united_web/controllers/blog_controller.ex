defmodule UnitedWeb.BlogController do
  use UnitedWeb, :controller

  alias United.Settings
  alias United.Settings.Blog

  def index(conn, _params) do
    blogs = Settings.list_blogs()
    render(conn, "index.html", blogs: blogs)
  end

  def new(conn, _params) do
    changeset = Settings.change_blog(%Blog{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"blog" => blog_params}) do
    case Settings.create_blog(blog_params) do
      {:ok, blog} ->
        conn
        |> put_flash(:info, "Blog created successfully.")
        |> redirect(to: Routes.blog_path(conn, :show, blog))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    blog = Settings.get_blog!(id)
    render(conn, "show.html", blog: blog)
  end

  def edit(conn, %{"id" => id}) do
    blog = Settings.get_blog!(id)
    changeset = Settings.change_blog(blog)
    render(conn, "edit.html", blog: blog, changeset: changeset)
  end

  def update(conn, %{"id" => id, "blog" => blog_params}) do
    blog = Settings.get_blog!(id)

    case Settings.update_blog(blog, blog_params) do
      {:ok, blog} ->
        conn
        |> put_flash(:info, "Blog updated successfully.")
        |> redirect(to: Routes.blog_path(conn, :show, blog))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", blog: blog, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    blog = Settings.get_blog!(id)
    {:ok, _blog} = Settings.delete_blog(blog)

    conn
    |> put_flash(:info, "Blog deleted successfully.")
    |> redirect(to: Routes.blog_path(conn, :index))
  end
end
