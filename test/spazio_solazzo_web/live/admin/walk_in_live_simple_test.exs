defmodule SpazioSolazzoWeb.Admin.WalkInLiveSimpleTest do
  use SpazioSolazzoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  alias SpazioSolazzo.BookingSystem

  setup do
    {:ok, space} =
      BookingSystem.create_space(
        "Coworking",
        "coworking",
        "Coworking space",
        5
      )

    user =
      "admin@example.com"
      |> register_user("Admin User")
      |> SpazioSolazzo.Accounts.make_admin!(authorize?: false)

    %{space: space, user: user}
  end

  describe "walk-in booking creation bug" do
    test "can create booking by directly setting assigns", %{conn: conn, user: user, space: space} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/admin/walk-in")

      tomorrow = Date.add(Date.utc_today(), 1)

      # Simulate the calendar component sending the date_selected message
      send(view.pid, {:date_selected, tomorrow, tomorrow})

      # Fill in customer details using the form
      view
      |> form("form[phx-change='validate_customer_details']", %{
        "customer_name" => "John Doe",
        "customer_email" => "john@example.com"
      })
      |> render_change()

      # Try to create the booking
      html =
        view
        |> element("form[phx-submit='create_booking']")
        |> render_submit()

      assert html =~ "Walk-in booking created successfully"

      # Verify booking was created
      start_datetime = DateTime.new!(tomorrow, ~T[00:00:00], "Etc/UTC")
      end_datetime = DateTime.new!(Date.add(tomorrow, 1), ~T[00:00:00], "Etc/UTC")

      assert {:ok, [_booking]} =
               BookingSystem.search_bookings(
                 space.id,
                 start_datetime,
                 end_datetime,
                 [:accepted],
                 nil
               )
    end
  end
end
