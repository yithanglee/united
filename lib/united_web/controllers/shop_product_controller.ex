defmodule UnitedWeb.ShopProductController do
  use UnitedWeb, :controller

  alias United.Settings
  alias United.Settings.ShopProduct

  def index(conn, _params) do
    shop_products = Settings.list_shop_products()
    render(conn, "index.html", shop_products: shop_products)
  end

  def new(conn, _params) do
    changeset = Settings.change_shop_product(%ShopProduct{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"shop_product" => shop_product_params}) do
    case Settings.create_shop_product(shop_product_params) do
      {:ok, shop_product} ->
        conn
        |> put_flash(:info, "Shop product created successfully.")
        |> redirect(to: Routes.shop_product_path(conn, :show, shop_product))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    shop_product = Settings.get_shop_product!(id)
    render(conn, "show.html", shop_product: shop_product)
  end

  def edit(conn, %{"id" => id}) do
    shop_product = Settings.get_shop_product!(id)
    changeset = Settings.change_shop_product(shop_product)
    render(conn, "edit.html", shop_product: shop_product, changeset: changeset)
  end

  def update(conn, %{"id" => id, "shop_product" => shop_product_params}) do
    shop_product = Settings.get_shop_product!(id)

    case Settings.update_shop_product(shop_product, shop_product_params) do
      {:ok, shop_product} ->
        conn
        |> put_flash(:info, "Shop product updated successfully.")
        |> redirect(to: Routes.shop_product_path(conn, :show, shop_product))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", shop_product: shop_product, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    shop_product = Settings.get_shop_product!(id)
    {:ok, _shop_product} = Settings.delete_shop_product(shop_product)

    conn
    |> put_flash(:info, "Shop product deleted successfully.")
    |> redirect(to: Routes.shop_product_path(conn, :index))
  end
end
