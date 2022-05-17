defmodule United.Authorization do
  use Phoenix.Controller, namespace: UnitedWeb
  import Plug.Conn
  require IEx

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    if conn.request_path |> String.contains?("/admin") do
      if conn.private.plug_session["current_user"] == nil do
        cond do
          conn.request_path |> String.contains?("/login") ->
            conn

          conn.request_path |> String.contains?("/logout") ->
            conn

          conn.request_path |> String.contains?("/authenticate") ->
            conn

          true ->
            conn
            |> put_flash(:error, "You haven't login.")
            |> redirect(to: "/admin/login")
            |> halt
        end
      else
        conn
      end
    else
      if conn.request_path |> String.contains?("/0") do
        conn
        |> put_flash(:error, "Unauthorized.")
        |> redirect(to: "/admin")
        |> halt
      else
        conn
      end
    end
  end
end

defmodule United.ApiAuthorization do
  use Phoenix.Controller, namespace: UnitedWeb
  import Plug.Conn
  require IEx

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    # IO.inspect(conn)

    if conn.method == "POST" do
      cond do
        Plug.Conn.get_req_header(conn, "referer")
        |> List.first()
        |> String.contains?("/admin/dashboard") ->
          conn

        conn.params["scope"] in ["google_signin", "strong_search"] ->
          conn

        true ->
          with auth_token <- Plug.Conn.get_req_header(conn, "authorization") |> List.first(),
               true <- auth_token != nil,
               token <- auth_token |> String.split("Basic ") |> List.last(),
               t <- United.Settings.decode_member_token2(token),
               true <- t != nil do
            IO.inspect(t)

            IO.inspect("auth")
            conn
          else
            _ ->
              IO.inspect("not auth")

              conn
              |> resp(500, Jason.encode!(%{message: "Not authorized."}))
              |> halt
          end
      end
    else
      conn
    end
  end
end
