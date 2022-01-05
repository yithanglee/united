defmodule UnitedWeb.ShopController do
  use UnitedWeb, :controller

  alias United.Settings
  alias United.Settings.Shop

  def index(conn, _params) do
    shops = Settings.list_shops()
    render(conn, "index.html", shops: shops)
  end

  def new(conn, _params) do
    changeset = Settings.change_shop(%Shop{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"shop" => shop_params}) do
    case Settings.create_shop(shop_params) do
      {:ok, shop} ->
        conn
        |> put_flash(:info, "Shop created successfully.")
        |> redirect(to: Routes.shop_path(conn, :show, shop))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    shop = Settings.get_shop!(id)
    render(conn, "show.html", shop: shop)
  end

  def edit(conn, %{"id" => id}) do
    shop = Settings.get_shop!(id)
    changeset = Settings.change_shop(shop)
    render(conn, "edit.html", shop: shop, changeset: changeset)
  end

  def update(conn, %{"id" => id, "shop" => shop_params}) do
    shop = Settings.get_shop!(id)

    case Settings.update_shop(shop, shop_params) do
      {:ok, shop} ->
        conn
        |> put_flash(:info, "Shop updated successfully.")
        |> redirect(to: Routes.shop_path(conn, :show, shop))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", shop: shop, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    shop = Settings.get_shop!(id)
    {:ok, _shop} = Settings.delete_shop(shop)

    conn
    |> put_flash(:info, "Shop deleted successfully.")
    |> redirect(to: Routes.shop_path(conn, :index))
  end
end
