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
    plug :sign_in_with_remember_me
    plug :load_from_session
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
    plug :set_actor, :user
  end

  scope "/", SpazioSolazzoWeb do
    pipe_through :browser

    get "/sign-out", AuthController, :sign_out
    get "/auth/magic/sign-in", AuthController, :magic_sign_in
    get "/auth/failure", AuthController, :auth_failure

    ash_authentication_live_session :unauthenticated_routes,
      on_mount: [
        {SpazioSolazzoWeb.LiveUserAuth, :live_user_optional}
      ] do
      live "/", PageLive
      live "/coworking", CoworkingLive
      live "/meeting", MeetingLive
      live "/music", MusicLive
    end

    ash_authentication_live_session :no_user_routes,
      on_mount: [
        {SpazioSolazzoWeb.LiveUserAuth, :live_no_user}
      ] do
      live "/sign-in/callback", AuthCallbackLive
      live "/sign-in", SignInLive
    end

    ash_authentication_live_session :authenticated_routes,
      on_mount: [
        {SpazioSolazzoWeb.LiveUserAuth, :live_user_required}
      ] do
      live "/book/space/:space_slug", SpaceBookingLive
      live "/bookings/cancel", BookingCancellationLive
      live "/profile", ProfileLive
    end

    ash_authentication_live_session :admin_routes,
      on_mount: [
        {SpazioSolazzoWeb.LiveUserAuth, :live_admin_required}
      ] do
      live "/admin/dashboard", Admin.DashboardLive
      live "/admin/bookings", Admin.BookingManagementLive
      live "/admin/walk-in", Admin.WalkInLive
    end
  end

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
