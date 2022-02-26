defmodule UnitedWeb.PageController do
  use UnitedWeb, :controller
  @app_secret "2e210fa67f156f26d8d9adb2f5524b9e"
  @app_id "716495772618929"
  def fb_login(conn, _params) do
    redir = "https://ff57-115-164-74-68.ngrok.io/fb_callback"

    conn
    |> redirect(
      external:
        "https://www.facebook.com/v13.0/dialog/oauth?client_id=#{@app_id}&redirect_uri=#{redir}"
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

    case res do
      {:ok, resp} ->
        %{"access_token" => access_token, "token_type" => token_type} = Jason.decode!(resp.body)
        IO.inspect(access_token)

      _ ->
        nil
    end

    IO.inspect(res)
    render(conn, "index.html")
  end

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
