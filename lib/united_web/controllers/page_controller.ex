defmodule UnitedWeb.PageController do
  use UnitedWeb, :controller
  @app_secret Application.get_env(:united, :facebook)[:app_secret]
  @app_id Application.get_env(:united, :facebook)[:app_id]
  @fb_callback Application.get_env(:united, :facebook)[:callback_url]
  require IEx

  def fb_relogin(conn, _params) do
    # redir = "https://ff57-115-164-74-68.ngrok.io/fb_callback"
    redir = @fb_callback
    user_id = conn.private.plug_session["current_user"].id

    IO.inspect(redir)

    link =
      "https://www.facebook.com/v13.0/dialog/oauth?client_id=#{@app_id}&auth_type=rerequest&scope=pages_show_list,pages_read_engagement,pages_read_user_content&redirect_uri=#{
        redir
      }&state={user_id=#{user_id}}"

    IO.inspect(link)

    conn
    |> redirect(external: link)
  end

  def fb_login(conn, _params) do
    # redir = "https://ff57-115-164-74-68.ngrok.io/fb_callback"
    redir = @fb_callback
    user_id = conn.private.plug_session["current_user"].id

    IO.inspect(redir)

    link =
      "https://www.facebook.com/v13.0/dialog/oauth?client_id=#{@app_id}&redirect_uri=#{redir}&state={user_id=#{
        user_id
      }}"

    IO.inspect(link)

    conn
    |> redirect(external: link)
  end

  def fb_callback(conn, %{"code" => code} = params) do
    IO.inspect(params)
    # redir = "https://ff57-115-164-74-68.ngrok.io/fb_callback"
    redir = @fb_callback

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
        |> redirect(to: "/admin/dashboard")

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

  def show_page(conn, params) do
    render(conn, "show.html", params)
  end

  def member_dashboard(conn, _params) do
    render(conn, "member_dashboard.html", layout: {UnitedWeb.LayoutView, "member.html"})
  end

  def dashboard(conn, _params) do
    render(conn, "dashboard.html")
  end
end
