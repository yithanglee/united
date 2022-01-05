defmodule UnitedWeb.ShopProductTagController do
  use UnitedWeb, :controller

  alias United.Settings
  alias United.Settings.ShopProductTag

  def index(conn, _params) do
    shop_product_tags = Settings.list_shop_product_tags()
    render(conn, "index.html", shop_product_tags: shop_product_tags)
  end

  def new(conn, _params) do
    changeset = Settings.change_shop_product_tag(%ShopProductTag{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"shop_product_tag" => shop_product_tag_params}) do
    case Settings.create_shop_product_tag(shop_product_tag_params) do
      {:ok, shop_product_tag} ->
        conn
        |> put_flash(:info, "Shop product tag created successfully.")
        |> redirect(to: Routes.shop_product_tag_path(conn, :show, shop_product_tag))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    shop_product_tag = Settings.get_shop_product_tag!(id)
    render(conn, "show.html", shop_product_tag: shop_product_tag)
  end

  def edit(conn, %{"id" => id}) do
    shop_product_tag = Settings.get_shop_product_tag!(id)
    changeset = Settings.change_shop_product_tag(shop_product_tag)
    render(conn, "edit.html", shop_product_tag: shop_product_tag, changeset: changeset)
  end

  def update(conn, %{"id" => id, "shop_product_tag" => shop_product_tag_params}) do
    shop_product_tag = Settings.get_shop_product_tag!(id)

    case Settings.update_shop_product_tag(shop_product_tag, shop_product_tag_params) do
      {:ok, shop_product_tag} ->
        conn
        |> put_flash(:info, "Shop product tag updated successfully.")
        |> redirect(to: Routes.shop_product_tag_path(conn, :show, shop_product_tag))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", shop_product_tag: shop_product_tag, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    shop_product_tag = Settings.get_shop_product_tag!(id)
    {:ok, _shop_product_tag} = Settings.delete_shop_product_tag(shop_product_tag)

    conn
    |> put_flash(:info, "Shop product tag deleted successfully.")
    |> redirect(to: Routes.shop_product_tag_path(conn, :index))
  end
end
