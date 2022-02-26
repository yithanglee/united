defmodule UnitedWeb.PageController do
  use UnitedWeb, :controller
  @app_secret Application.get_env(:united, :facebook)[:app_secret]
  @app_id Application.get_env(:united, :facebook)[:app_id]
  require IEx

  def fb_login(conn, _params) do
    redir = "https://ff57-115-164-74-68.ngrok.io/fb_callback"
    user_id = conn.private.plug_session["current_user"].id

    conn
    |> redirect(
      external:
        "https://www.facebook.com/v13.0/dialog/oauth?client_id=#{@app_id}&redirect_uri=#{redir}&state={user_id=#{
          user_id
        }}"
    )
  end

  def fb_callback(conn, %{"code" => code} = params) do
    IO.inspect(params)
    redir = "https://ff57-115-164-74-68.ngrok.io/fb_callback"

    url =
      "https://graph.facebook.com/v13.0/oauth/access_token?client_id=#{@app_id}&redirect_uri=#{
        redir
      }&client_secret=#{@app_secret}&code=#{code}"

    # conn
    # |> redirect(external: url)
    res = HTTPoison.get(url)
    IO.inspect(res)

    case res do
      {:ok, resp} ->
        %{"access_token" => access_token, "token_type" => token_type} = Jason.decode!(resp.body)
        IO.inspect(access_token)

        [_key, id] =
          conn.params["state"]
          |> String.replace("{", "")
          |> String.replace("}", "")
          |> String.split("=")

        # current_user = conn.private.plug_session["current_user"]

        user = United.Settings.get_user!(id)

        %{"data" => %{"user_id" => fb_user_id}} = FacebookHelper.inspect_token(access_token)

        {:ok, user} =
          United.Settings.update_user(user, %{
            fb_user_id: fb_user_id,
            user_access_token: access_token
          })

        conn
        |> put_session(:current_user, BluePotion.s_to_map(user))
        |> put_flash(:info, "FB token recorded!")
        |> redirect(to: "/admin/blogs")

      _ ->
        nil

        conn
        |> put_flash(:info, "FB token recorded!")
        |> redirect(to: "/admin/blogs")
    end
  end

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
