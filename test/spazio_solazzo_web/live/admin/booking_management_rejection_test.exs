defmodule SpazioSolazzoWeb.Admin.BookingManagementRejectionTest do
  use SpazioSolazzoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  alias SpazioSolazzo.BookingSystem

  defp create_booking(space, user) do
    tomorrow = Date.add(Date.utc_today(), 1)
    start_time = ~T[10:00:00]
    end_time = ~T[12:00:00]

    {:ok, booking} =
      BookingSystem.create_booking(
        space.id,
        user.id,
        tomorrow,
        start_time,
        end_time,
        "Test User",
        "test@example.com",
        "+1234567890",
        "Test booking comment"
      )

    booking
  end

  setup do
    {:ok, space} =
      BookingSystem.create_space(
        "Coworking",
        "coworking",
        "Coworking space",
        5
      )

    admin_user =
      "admin@example.com"
      |> register_user("Admin User")
      |> SpazioSolazzo.Accounts.make_admin!(authorize?: false)

    regular_user = register_user("user@example.com", "Regular User")

    %{space: space, admin_user: admin_user, regular_user: regular_user}
  end

  describe "booking rejection modal" do
    test "shows reject modal when clicking reject button", %{
      conn: conn,
      admin_user: admin_user,
      space: space,
      regular_user: regular_user
    } do
      booking = create_booking(space, regular_user)
      conn = log_in_user(conn, admin_user)
      {:ok, view, _html} = live(conn, "/admin/bookings")

      refute has_element?(view, "#success-modal")

      html =
        view
        |> element("button[phx-click='show_reject_modal'][phx-value-booking_id='#{booking.id}']")
        |> render_click()

      assert html =~ "Reject Booking"
      assert html =~ "Rejection Reason"
    end

    test "hides reject modal when clicking cancel", %{
      conn: conn,
      admin_user: admin_user,
      space: space,
      regular_user: regular_user
    } do
      booking = create_booking(space, regular_user)
      conn = log_in_user(conn, admin_user)
      {:ok, view, _html} = live(conn, "/admin/bookings")

      view
      |> element("button[phx-click='show_reject_modal'][phx-value-booking_id='#{booking.id}']")
      |> render_click()

      html =
        view
        |> element("button[phx-click='hide_reject_modal']")
        |> render_click()

      refute html =~ "Reject Booking"
    end

    test "shows error when rejection reason is empty", %{
      conn: conn,
      admin_user: admin_user,
      space: space,
      regular_user: regular_user
    } do
      booking = create_booking(space, regular_user)
      conn = log_in_user(conn, admin_user)
      {:ok, view, _html} = live(conn, "/admin/bookings")

      view
      |> element("button[phx-click='show_reject_modal'][phx-value-booking_id='#{booking.id}']")
      |> render_click()

      html =
        view
        |> element("form[phx-submit='confirm_reject']")
        |> render_submit(%{"reason" => ""})

      assert html =~ "Please provide a rejection reason"
    end

    test "successfully rejects booking with valid reason", %{
      conn: conn,
      admin_user: admin_user,
      space: space,
      regular_user: regular_user
    } do
      booking = create_booking(space, regular_user)
      conn = log_in_user(conn, admin_user)
      {:ok, view, _html} = live(conn, "/admin/bookings")

      view
      |> element("button[phx-click='show_reject_modal'][phx-value-booking_id='#{booking.id}']")
      |> render_click()

      view
      |> element("textarea[name='reason']")
      |> render_change(%{"reason" => "Space under maintenance"})

      html =
        view
        |> element("form[phx-submit='confirm_reject']")
        |> render_submit()

      assert html =~ "Booking rejected"

      {:ok, updated_booking} = Ash.get(SpazioSolazzo.BookingSystem.Booking, booking.id)
      assert updated_booking.state == :rejected
      assert updated_booking.rejection_reason == "Space under maintenance"
    end

    test "updates rejection reason as user types", %{
      conn: conn,
      admin_user: admin_user,
      space: space,
      regular_user: regular_user
    } do
      booking = create_booking(space, regular_user)
      conn = log_in_user(conn, admin_user)
      {:ok, view, _html} = live(conn, "/admin/bookings")

      view
      |> element("button[phx-click='show_reject_modal'][phx-value-booking_id='#{booking.id}']")
      |> render_click()

      html =
        view
        |> element("textarea[name='reason']")
        |> render_change(%{"reason" => "Fully booked"})

      assert html =~ "Fully booked"
    end

    test "closes modal after successful rejection", %{
      conn: conn,
      admin_user: admin_user,
      space: space,
      regular_user: regular_user
    } do
      booking = create_booking(space, regular_user)
      conn = log_in_user(conn, admin_user)
      {:ok, view, _html} = live(conn, "/admin/bookings")

      view
      |> element("button[phx-click='show_reject_modal'][phx-value-booking_id='#{booking.id}']")
      |> render_click()

      view
      |> element("textarea[name='reason']")
      |> render_change(%{"reason" => "Not available"})

      html =
        view
        |> element("form[phx-submit='confirm_reject']")
        |> render_submit()

      refute html =~ "Reject Booking"
      assert html =~ "Booking rejected"
    end

    test "rejected booking moves from pending to past bookings", %{
      conn: conn,
      admin_user: admin_user,
      space: space,
      regular_user: regular_user
    } do
      booking = create_booking(space, regular_user)
      conn = log_in_user(conn, admin_user)
      {:ok, view, html} = live(conn, "/admin/bookings")

      assert html =~ "Pending"

      view
      |> element("button[phx-click='show_reject_modal'][phx-value-booking_id='#{booking.id}']")
      |> render_click()

      view
      |> element("textarea[name='reason']")
      |> render_change(%{"reason" => "Not available"})

      _html =
        view
        |> element("form[phx-submit='confirm_reject']")
        |> render_submit()

      {:ok, updated_booking} = Ash.get(SpazioSolazzo.BookingSystem.Booking, booking.id)
      assert updated_booking.state == :rejected
      assert updated_booking.rejection_reason == "Not available"
    end

    test "multiple bookings can be rejected independently", %{
      conn: conn,
      admin_user: admin_user,
      space: space,
      regular_user: regular_user
    } do
      tomorrow = Date.add(Date.utc_today(), 1)

      {:ok, booking1} =
        BookingSystem.create_booking(
          space.id,
          regular_user.id,
          tomorrow,
          ~T[09:00:00],
          ~T[11:00:00],
          "Test User",
          "test@example.com",
          "+1234567890",
          "First booking"
        )

      {:ok, booking2} =
        BookingSystem.create_booking(
          space.id,
          regular_user.id,
          tomorrow,
          ~T[14:00:00],
          ~T[16:00:00],
          "Test User",
          "test@example.com",
          "+1234567890",
          "Second booking"
        )

      conn = log_in_user(conn, admin_user)
      {:ok, view, _html} = live(conn, "/admin/bookings")

      view
      |> element("button[phx-click='show_reject_modal'][phx-value-booking_id='#{booking1.id}']")
      |> render_click()

      view
      |> element("textarea[name='reason']")
      |> render_change(%{"reason" => "Reason 1"})

      view
      |> element("form[phx-submit='confirm_reject']")
      |> render_submit()

      {:ok, updated_booking1} = Ash.get(SpazioSolazzo.BookingSystem.Booking, booking1.id)
      {:ok, updated_booking2} = Ash.get(SpazioSolazzo.BookingSystem.Booking, booking2.id)

      assert updated_booking1.state == :rejected
      assert updated_booking1.rejection_reason == "Reason 1"
      assert updated_booking2.state == :requested
    end
  end
end
