defmodule UnitedWeb.LoginController do
  use UnitedWeb, :controller
  import Ecto.Query
  alias United.{Settings, Repo}

  def index(conn, params) do
    render(conn, "login.html", layout: {UnitedWeb.LayoutView, "login.html"})
  end

  def register(conn, params) do
    render(conn, "register.html", layout: {UnitedWeb.LayoutView, "login.html"})
  end

  def create(conn, params) do
    crypted_password =
      :crypto.hash(:sha512, params["password"]) |> Base.encode16() |> String.downcase()

    case Settings.create_user(
           params
           |> Map.put("crypted_password", crypted_password)
           |> Map.delete("password")
         ) do
      {:ok, user} ->
        conn
        |> put_session(:current_user, BluePotion.s_to_map(user))
        |> put_flash(:info, "Welcome!")
        |> redirect(to: "/admin/blogs")

      {:error, cg} ->
        conn
        |> put_flash(:error, "Please try again!")
        |> redirect(to: "/admin/register")
    end
  end

  def authenticate(conn, params) do
    if check_password(params) do
      users = Repo.all(from u in Settings.User, where: u.username == ^params["username"])
      user = List.first(users)

      conn
      |> put_session(:current_user, BluePotion.s_to_map(user))
      |> put_flash(:info, "Welcome!")
      |> redirect(to: "/admin/blogs")
    else
      conn
      |> put_flash(:info, "Denied!")
      |> redirect(to: "/admin/login")
    end
  end

  def logout(conn, params) do
    conn
    |> delete_session(:current_user)
    |> put_flash(:info, "Logout!")
    |> redirect(to: "/admin/login")
  end

  def check_password(params) do
    # your auth method here

    # sample reference
    users = Repo.all(from u in Settings.User, where: u.username == ^params["username"])

    if users != [] do
      user = List.first(users)

      crypted_password =
        :crypto.hash(:sha512, params["password"]) |> Base.encode16() |> String.downcase()

      crypted_password == user.crypted_password
    else
      false
    end
  end
end
