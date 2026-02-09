defmodule SpazioSolazzoWeb.Admin.WalkInLiveTest do
  use SpazioSolazzoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  alias SpazioSolazzo.BookingSystem

  setup do
    {:ok, space} =
      BookingSystem.create_space(
        "Arcipelago",
        "arcipelago",
        "Coworking space",
        5
      )

    user =
      "admin@example.com"
      |> register_user("Admin User")
      |> SpazioSolazzo.Accounts.make_admin!(authorize?: false)

    %{space: space, user: user}
  end

  describe "walk-in booking form" do
    test "displays the form with calendar and customer details", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/admin/walk-in")

      assert has_element?(view, "form[phx-change='validate_customer_details']")
      assert has_element?(view, "input[name='customer_name']")
      assert has_element?(view, "input[name='customer_email']")
      assert has_element?(view, "button[type='submit']")
    end

    test "creates single-day walk-in booking successfully", %{
      conn: conn,
      user: user,
      space: space
    } do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/admin/walk-in")

      tomorrow = Date.add(Date.utc_today(), 1)

      # Simulate date selection by sending message to LiveView
      send(view.pid, {:date_selected, tomorrow, tomorrow})
      :timer.sleep(50)

      # Fill in customer details
      view
      |> form("form[phx-change='validate_customer_details']", %{
        "customer_name" => "John Doe",
        "customer_email" => "john@example.com"
      })
      |> render_change()

      # Submit the form
      html =
        view
        |> element("form[phx-submit='create_booking']")
        |> render_submit()

      assert html =~ "Walk-in booking created successfully"

      # Verify booking was created
      start_datetime = DateTime.new!(tomorrow, ~T[00:00:00], "Etc/UTC")
      end_datetime = DateTime.new!(Date.add(tomorrow, 1), ~T[00:00:00], "Etc/UTC")

      {:ok, bookings} =
        BookingSystem.search_bookings(
          space.id,
          start_datetime,
          end_datetime,
          [:accepted],
          nil
        )

      assert length(bookings) == 1
      booking = hd(bookings)
      assert booking.customer_name == "John Doe"
      assert booking.customer_email == "john@example.com"
      assert booking.state == :accepted
    end

    test "shows error when no date is selected", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/admin/walk-in")

      # Fill in customer details without selecting a date
      view
      |> form("form[phx-change='validate_customer_details']", %{
        "customer_name" => "John Doe",
        "customer_email" => "john@example.com"
      })
      |> render_change()

      # Try to submit
      html =
        view
        |> element("form[phx-submit='create_booking']")
        |> render_submit()

      assert html =~ "Please fill in all required fields and select a date"
    end

    test "shows error when customer name is missing", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/admin/walk-in")

      tomorrow = Date.add(Date.utc_today(), 1)
      send(view.pid, {:date_selected, tomorrow, tomorrow})
      :timer.sleep(50)

      view
      |> form("form[phx-change='validate_customer_details']", %{
        "customer_email" => "john@example.com"
      })
      |> render_change()

      html =
        view
        |> element("form[phx-submit='create_booking']")
        |> render_submit()

      assert html =~ "Please fill in all required fields and select a date"
    end

    test "shows error when customer email is missing", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/admin/walk-in")

      tomorrow = Date.add(Date.utc_today(), 1)
      send(view.pid, {:date_selected, tomorrow, tomorrow})
      :timer.sleep(50)

      view
      |> form("form[phx-change='validate_customer_details']", %{
        "customer_name" => "John Doe"
      })
      |> render_change()

      html =
        view
        |> element("form[phx-submit='create_booking']")
        |> render_submit()

      assert html =~ "Please fill in all required fields and select a date"
    end

    test "creates multi-day walk-in booking", %{conn: conn, user: user, space: space} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/admin/walk-in")

      # Select date range (3 days)
      start_date = Date.add(Date.utc_today(), 1)
      end_date = Date.add(Date.utc_today(), 3)

      send(view.pid, {:date_selected, start_date, end_date})
      :timer.sleep(50)

      # Fill in customer details
      view
      |> form("form[phx-change='validate_customer_details']", %{
        "customer_name" => "Jane Smith",
        "customer_email" => "jane@example.com"
      })
      |> render_change()

      # Submit the form
      html =
        view
        |> element("form[phx-submit='create_booking']")
        |> render_submit()

      assert html =~ "Walk-in booking created successfully"

      # Verify booking was created and spans multiple days
      start_datetime = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")
      end_datetime_search = DateTime.new!(Date.add(start_date, 1), ~T[00:00:00], "Etc/UTC")

      {:ok, bookings} =
        BookingSystem.search_bookings(
          space.id,
          start_datetime,
          end_datetime_search,
          [:accepted],
          nil
        )

      assert length(bookings) == 1
      booking = hd(bookings)
      assert booking.customer_name == "Jane Smith"

      # Verify booking appears on all days in the range
      day2_start = DateTime.new!(Date.add(start_date, 1), ~T[00:00:00], "Etc/UTC")
      day2_end = DateTime.new!(Date.add(start_date, 2), ~T[00:00:00], "Etc/UTC")

      {:ok, day2_bookings} =
        BookingSystem.search_bookings(space.id, day2_start, day2_end, [:accepted], nil)

      assert length(day2_bookings) == 1

      day3_start = DateTime.new!(end_date, ~T[00:00:00], "Etc/UTC")
      day3_end = DateTime.new!(Date.add(end_date, 1), ~T[00:00:00], "Etc/UTC")

      {:ok, day3_bookings} =
        BookingSystem.search_bookings(space.id, day3_start, day3_end, [:accepted], nil)

      assert length(day3_bookings) == 1
    end

    test "includes optional phone", %{conn: conn, user: user, space: space} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/admin/walk-in")

      tomorrow = Date.add(Date.utc_today(), 1)
      send(view.pid, {:date_selected, tomorrow, tomorrow})
      :timer.sleep(50)

      view
      |> form("form[phx-change='validate_customer_details']", %{
        "customer_name" => "John Doe",
        "customer_email" => "john@example.com",
        "customer_phone" => "+39 1234567890"
      })
      |> render_change()

      html =
        view
        |> element("form[phx-submit='create_booking']")
        |> render_submit()

      assert html =~ "Walk-in booking created successfully"

      start_datetime = DateTime.new!(tomorrow, ~T[00:00:00], "Etc/UTC")
      end_datetime = DateTime.new!(Date.add(tomorrow, 1), ~T[00:00:00], "Etc/UTC")

      {:ok, bookings} =
        BookingSystem.search_bookings(
          space.id,
          start_datetime,
          end_datetime,
          [:accepted],
          nil
        )

      booking = hd(bookings)
      assert booking.customer_phone == "+39 1234567890"
    end

    test "clears form after successful booking", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/admin/walk-in")

      tomorrow = Date.add(Date.utc_today(), 1)
      send(view.pid, {:date_selected, tomorrow, tomorrow})

      view
      |> form("form[phx-change='validate_customer_details']", %{
        "customer_name" => "John Doe",
        "customer_email" => "john@example.com"
      })
      |> render_change()

      html =
        view
        |> element("form[phx-submit='create_booking']")
        |> render_submit()

      assert html =~ "Walk-in booking created successfully"
      assert html =~ "Not selected"
      assert html =~ ~s(value="")
    end

    test "updates start and end time", %{conn: conn, user: user, space: space} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/admin/walk-in")

      tomorrow = Date.add(Date.utc_today(), 1)
      send(view.pid, {:date_selected, tomorrow, tomorrow})
      :timer.sleep(50)

      view
      |> element("input[name='start-time']")
      |> render_change(%{"start-time" => "10:00"})

      html =
        view
        |> element("input[name='end-time']")
        |> render_change(%{"end-time" => "17:00"})

      assert html =~ "value=\"10:00\""
      assert html =~ "value=\"17:00\""

      view
      |> form("form[phx-change='validate_customer_details']", %{
        "customer_name" => "Time Tester",
        "customer_email" => "time@test.com"
      })
      |> render_change()

      html =
        view
        |> element("form[phx-submit='create_booking']")
        |> render_submit()

      assert html =~ "Walk-in booking created successfully"

      start_search = DateTime.new!(tomorrow, ~T[00:00:00], "Etc/UTC")
      end_search = DateTime.new!(tomorrow, ~T[23:59:59], "Etc/UTC")

      {:ok, bookings} =
        BookingSystem.search_bookings(
          space.id,
          start_search,
          end_search,
          [:accepted],
          nil
        )

      assert length(bookings) == 1
      booking = hd(bookings)
      assert DateTime.to_time(booking.start_datetime) == ~T[10:00:00]
      assert DateTime.to_time(booking.end_datetime) == ~T[17:00:00]
    end
  end

  describe "space selection" do
    setup %{space: _space} do
      {:ok, hall} =
        BookingSystem.create_space(
          "Hall",
          "hall",
          "Event hall",
          1
        )

      {:ok, media_room} =
        BookingSystem.create_space(
          "Media room",
          "media-room",
          "Media room",
          1
        )

      %{hall: hall, media_room: media_room}
    end

    test "displays all available spaces", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, "/admin/walk-in")

      assert html =~ "Arcipelago"
      assert html =~ "Hall"
      assert html =~ "Media room"
      assert html =~ "Select Space"
    end

    test "defaults to Arcipelago space", %{conn: conn, user: user, space: space} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/admin/walk-in")

      # Verify the default space is Arcipelago by checking the space_slug passed to the calendar
      assert has_element?(view, "button[phx-value-space_slug='#{space.slug}']")
    end

    test "can switch to a different space", %{conn: conn, user: user, hall: hall} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/admin/walk-in")

      # Click on the Hall space button
      html =
        view
        |> element("button[phx-value-space_slug='#{hall.slug}']")
        |> render_click()

      assert html =~ "Not selected"
    end

    test "creates booking for the selected space", %{conn: conn, user: user, hall: hall} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/admin/walk-in")

      # Switch to Hall space
      view
      |> element("button[phx-value-space_slug='#{hall.slug}']")
      |> render_click()

      tomorrow = Date.add(Date.utc_today(), 1)
      send(view.pid, {:date_selected, tomorrow, tomorrow})

      # Fill in customer details
      view
      |> form("form[phx-change='validate_customer_details']", %{
        "customer_name" => "Jane Smith",
        "customer_email" => "jane@example.com"
      })
      |> render_change()

      # Submit the form
      html =
        view
        |> element("form[phx-submit='create_booking']")
        |> render_submit()

      assert html =~ "Walk-in booking created successfully"

      # Verify booking was created for the Hall space
      start_datetime = DateTime.new!(tomorrow, ~T[00:00:00], "Etc/UTC")
      end_datetime = DateTime.new!(Date.add(tomorrow, 1), ~T[00:00:00], "Etc/UTC")

      {:ok, hall_bookings} =
        BookingSystem.search_bookings(
          hall.id,
          start_datetime,
          end_datetime,
          [:accepted],
          nil
        )

      assert length(hall_bookings) == 1
      booking = hd(hall_bookings)
      assert booking.customer_name == "Jane Smith"
      assert booking.customer_email == "jane@example.com"
    end

    test "booking is not created on previously selected space after switching", %{
      conn: conn,
      user: user,
      space: arcipelago,
      hall: hall
    } do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/admin/walk-in")

      # Switch to Hall space
      view
      |> element("button[phx-value-space_slug='#{hall.slug}']")
      |> render_click()

      tomorrow = Date.add(Date.utc_today(), 1)
      send(view.pid, {:date_selected, tomorrow, tomorrow})

      view
      |> form("form[phx-change='validate_customer_details']", %{
        "customer_name" => "Test User",
        "customer_email" => "test@example.com"
      })
      |> render_change()

      html =
        view
        |> element("form[phx-submit='create_booking']")
        |> render_submit()

      assert html =~ "Walk-in booking created successfully"

      # Verify NO booking was created for the Arcipelago space
      start_datetime = DateTime.new!(tomorrow, ~T[00:00:00], "Etc/UTC")
      end_datetime = DateTime.new!(Date.add(tomorrow, 1), ~T[00:00:00], "Etc/UTC")

      {:ok, arcipelago_bookings} =
        BookingSystem.search_bookings(
          arcipelago.id,
          start_datetime,
          end_datetime,
          [:accepted],
          nil
        )

      assert arcipelago_bookings == []
    end

    test "resets date selection when switching spaces", %{conn: conn, user: user, hall: hall} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/admin/walk-in")

      # Select a date on the default space
      tomorrow = Date.add(Date.utc_today(), 1)
      send(view.pid, {:date_selected, tomorrow, tomorrow})

      html = render(view)
      assert html =~ Calendar.strftime(tomorrow, "%b %d, %Y")

      # Switch to Hall space
      html =
        view
        |> element("button[phx-value-space_slug='#{hall.slug}']")
        |> render_click()

      # Date selection should be reset
      refute html =~ Calendar.strftime(tomorrow, "%b %d, %Y")
    end
  end
end
