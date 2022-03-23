defmodule UnitedWeb.CustomerOrderLineController do
  use UnitedWeb, :controller

  alias United.Settings
  alias United.Settings.CustomerOrderLine

  def index(conn, _params) do
    customer_order_lines = Settings.list_customer_order_lines()
    render(conn, "index.html", customer_order_lines: customer_order_lines)
  end

  def new(conn, _params) do
    changeset = Settings.change_customer_order_line(%CustomerOrderLine{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"customer_order_line" => customer_order_line_params}) do
    case Settings.create_customer_order_line(customer_order_line_params) do
      {:ok, customer_order_line} ->
        conn
        |> put_flash(:info, "Customer order line created successfully.")
        |> redirect(to: Routes.customer_order_line_path(conn, :show, customer_order_line))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    customer_order_line = Settings.get_customer_order_line!(id)
    render(conn, "show.html", customer_order_line: customer_order_line)
  end

  def edit(conn, %{"id" => id}) do
    customer_order_line = Settings.get_customer_order_line!(id)
    changeset = Settings.change_customer_order_line(customer_order_line)
    render(conn, "edit.html", customer_order_line: customer_order_line, changeset: changeset)
  end

  def update(conn, %{"id" => id, "customer_order_line" => customer_order_line_params}) do
    customer_order_line = Settings.get_customer_order_line!(id)

    case Settings.update_customer_order_line(customer_order_line, customer_order_line_params) do
      {:ok, customer_order_line} ->
        conn
        |> put_flash(:info, "Customer order line updated successfully.")
        |> redirect(to: Routes.customer_order_line_path(conn, :show, customer_order_line))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", customer_order_line: customer_order_line, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    customer_order_line = Settings.get_customer_order_line!(id)
    {:ok, _customer_order_line} = Settings.delete_customer_order_line(customer_order_line)

    conn
    |> put_flash(:info, "Customer order line deleted successfully.")
    |> redirect(to: Routes.customer_order_line_path(conn, :index))
  end
end
