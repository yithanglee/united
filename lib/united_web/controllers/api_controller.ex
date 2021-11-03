defmodule UnitedWeb.ApiController do
  use UnitedWeb, :controller

  def webhook(conn, params) do
    final =
      case params["scope"] do
        "gen_inputs" ->
          BluePotion.test_module(params["module"])

        _ ->
          %{status: "received"}
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(final))
  end
end
