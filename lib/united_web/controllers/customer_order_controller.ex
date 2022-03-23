defmodule UnitedWeb.CustomerOrderController do
  use UnitedWeb, :controller

  alias United.Settings
  alias United.Settings.CustomerOrder

  def index(conn, _params) do
    customer_orders = Settings.list_customer_orders()
    render(conn, "index.html", customer_orders: customer_orders)
  end

  def new(conn, _params) do
    changeset = Settings.change_customer_order(%CustomerOrder{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"customer_order" => customer_order_params}) do
    case Settings.create_customer_order(customer_order_params) do
      {:ok, customer_order} ->
        conn
        |> put_flash(:info, "Customer order created successfully.")
        |> redirect(to: Routes.customer_order_path(conn, :show, customer_order))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    customer_order = Settings.get_customer_order!(id)
    render(conn, "show.html", customer_order: customer_order)
  end

  def edit(conn, %{"id" => id}) do
    customer_order = Settings.get_customer_order!(id)
    changeset = Settings.change_customer_order(customer_order)
    render(conn, "edit.html", customer_order: customer_order, changeset: changeset)
  end

  def update(conn, %{"id" => id, "customer_order" => customer_order_params}) do
    customer_order = Settings.get_customer_order!(id)

    case Settings.update_customer_order(customer_order, customer_order_params) do
      {:ok, customer_order} ->
        conn
        |> put_flash(:info, "Customer order updated successfully.")
        |> redirect(to: Routes.customer_order_path(conn, :show, customer_order))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", customer_order: customer_order, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    customer_order = Settings.get_customer_order!(id)
    {:ok, _customer_order} = Settings.delete_customer_order(customer_order)

    conn
    |> put_flash(:info, "Customer order deleted successfully.")
    |> redirect(to: Routes.customer_order_path(conn, :index))
  end
end
