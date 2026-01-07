defmodule SpazioSolazzoWeb.Router do
  use SpazioSolazzoWeb, :router

  use AshAuthentication.Phoenix.Router

  import AshAuthentication.Plug.Helpers

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SpazioSolazzoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
    plug :set_actor, :user
  end

  scope "/", SpazioSolazzoWeb do
    pipe_through :browser

    live "/", PageLive
    live "/coworking", CoworkingLive
    live "/meeting", MeetingLive
    live "/music", MusicLive
    get "/bookings/confirm", BookingController, :confirm
    get "/bookings/cancel", BookingController, :cancel
    auth_routes AuthController, SpazioSolazzo.Accounts.User, path: "/auth"
    sign_out_route AuthController

    ash_authentication_live_session :authenticated_routes,
      on_mount: [
        {SpazioSolazzoWeb.LiveUserAuth, :live_user_required}
      ] do
      live "/book/asset/:asset_id", AssetBookingLive
    end

    # Remove these if you'd like to use your own authentication views
    sign_in_route register_path: "/register",
                  reset_path: "/reset",
                  auth_routes_prefix: "/auth",
                  on_mount: [{SpazioSolazzoWeb.LiveUserAuth, :live_no_user}],
                  overrides: [
                    SpazioSolazzoWeb.AuthOverrides,
                    Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI
                  ]

    magic_sign_in_route(SpazioSolazzo.Accounts.User, :magic_link,
      auth_routes_prefix: "/auth",
      overrides: [
        SpazioSolazzoWeb.AuthOverrides,
        Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI
      ]
    )
  end

  # Other scopes may use custom stacks.
  # scope "/api", SpazioSolazzoWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:spazio_solazzo, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SpazioSolazzoWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  if Application.compile_env(:spazio_solazzo, :dev_routes) do
    import AshAdmin.Router

    scope "/admin" do
      pipe_through :browser

      ash_admin "/"
    end
  end
end
