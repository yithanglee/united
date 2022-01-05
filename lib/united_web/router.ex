defmodule UnitedWeb.Router do
  use UnitedWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :frontend do
    plug(:put_layout, {UnitedWeb.LayoutView, :frontend})
    # plug(Materialize.Authorization)
  end

  scope "/admin", UnitedWeb do
    pipe_through :browser
    get("/login", LoginController, :index)
    post("/authenticate", LoginController, :authenticate)
    get("/logout", LoginController, :logout)
    resources "/users", UserController
    resources "/blogs", BlogController
    resources "/shops", ShopController
    resources "/shop_products", ShopProductController
    resources "/tags", TagController
    resources "/shop_product_tags", ShopProductTagController
    resources "/stored_medias", StoredMediaController
  end

  scope "/api", UnitedWeb do
    pipe_through :api
    get("/webhook", ApiController, :webhook)
    post("/webhook", ApiController, :webhook_post)
    delete("/webhook", ApiController, :webhook_delete)
    get("/:model", ApiController, :datatable)
    post("/:model", ApiController, :form_submission)
  end

  scope "/", UnitedWeb do
    pipe_through [:browser, :frontend]

    get "*path", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", UnitedWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: UnitedWeb.Telemetry
    end
  end
end
