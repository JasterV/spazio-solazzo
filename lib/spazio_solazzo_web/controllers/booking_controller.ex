defmodule SpazioSolazzoWeb.BookingController do
  use SpazioSolazzoWeb, :controller

  def confirm(conn, %{"token" => _token}) do
    conn
    |> put_flash(
      :info,
      "Please use the admin dashboard to manage booking requests."
    )
    |> redirect(to: "/admin/dashboard")
  end
end
