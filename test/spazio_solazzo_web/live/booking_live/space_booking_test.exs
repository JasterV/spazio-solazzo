defmodule SpazioSolazzoWeb.BookingLive.SpaceBookingTest do
  use SpazioSolazzoWeb.ConnCase
  import Phoenix.LiveViewTest
  import SpazioSolazzo.AuthHelpers

  alias SpazioSolazzo.BookingSystem

  # Helper to convert old map-based call to new signature
  defp request_booking(space_id, user_id, date, start_time, end_time, customer_details) do
    BookingSystem.create_booking(
      space_id,
      user_id,
      date,
      start_time,
      end_time,
      customer_details.name,
      customer_details.email,
      customer_details[:phone],
      customer_details[:comment]
    )
  end

  setup %{conn: conn} do
    {:ok, space} =
      BookingSystem.create_space(
        "Test Space",
        "test-space",
        "Test description",
        2
      )

    today = Date.utc_today()
    day_of_week = day_of_week_atom(today)

    {:ok, slot1} =
      BookingSystem.create_time_slot_template(
        ~T[09:00:00],
        ~T[13:00:00],
        day_of_week,
        space.id
      )

    {:ok, slot2} =
      BookingSystem.create_time_slot_template(
        ~T[14:00:00],
        ~T[18:00:00],
        day_of_week,
        space.id
      )

    user = register_user("testuser@example.com", "Test User", "+39 1234567890")
    unauth_conn = conn
    conn = log_in_user(conn, user)

    %{
      conn: conn,
      unauth_conn: unauth_conn,
      space: space,
      slot1: slot1,
      slot2: slot2,
      today: today,
      user: user
    }
  end

  defp day_of_week_atom(date) do
    case Date.day_of_week(date) do
      1 -> :monday
      2 -> :tuesday
      3 -> :wednesday
      4 -> :thursday
      5 -> :friday
      6 -> :saturday
      7 -> :sunday
    end
  end

  describe "SpaceBooking mount" do
    test "renders space booking page with available time slots", %{
      conn: conn,
      space: space
    } do
      {:ok, view, html} = live(conn, ~p"/book/space/#{space.slug}")

      assert html =~ space.name
      assert html =~ space.description
      assert html =~ "Available Time Slots"
      assert has_element?(view, "button[phx-click='select_slot']")
      assert has_element?(view, "#booking-calendar")
    end

    test "displays calendar with current month", %{conn: conn, space: space} do
      {:ok, view, html} = live(conn, ~p"/book/space/#{space.slug}")

      today = Date.utc_today()
      month_name = Calendar.strftime(today, "%B %Y")

      assert html =~ month_name
      assert has_element?(view, ".calendar-container")
    end

    test "displays back button to home page", %{conn: conn, space: space} do
      {:ok, _view, html} = live(conn, ~p"/book/space/#{space.slug}")

      assert html =~ "Back to #{space.name}"
      assert html =~ "/#{space.slug}"
    end

    test "redirects when space not found", %{conn: conn} do
      assert {:error, {:live_redirect, %{to: "/", flash: %{"error" => "Space not found"}}}} =
               live(conn, ~p"/book/space/nonexistent-space")
    end

    test "shows message when no time slots available", %{conn: conn} do
      {:ok, empty_space} =
        BookingSystem.create_space(
          "Empty Space",
          "empty-space",
          "No slots",
          5
        )

      {:ok, _view, html} = live(conn, ~p"/book/space/#{empty_space.slug}")

      assert html =~ "No time slots available for this date"
    end
  end

  describe "SpaceBooking calendar navigation" do
    test "navigates to previous month", %{conn: conn, space: space} do
      {:ok, view, _html} = live(conn, ~p"/book/space/#{space.slug}")

      today = Date.utc_today()
      current_month = Calendar.strftime(today, "%B %Y")

      prev_month =
        today
        |> Date.shift(month: -1)
        |> Calendar.strftime("%B %Y")

      html = view |> element("button[phx-click='prev-month']") |> render_click()

      assert html =~ prev_month
      refute html =~ current_month
    end

    test "navigates to next month", %{conn: conn, space: space} do
      {:ok, view, _html} = live(conn, ~p"/book/space/#{space.slug}")

      today = Date.utc_today()
      current_month = Calendar.strftime(today, "%B %Y")

      next_month =
        today
        |> Date.shift(month: 1)
        |> Calendar.strftime("%B %Y")

      html = view |> element("button[phx-click='next-month']") |> render_click()

      assert html =~ next_month
      refute html =~ current_month
    end
  end

  describe "SpaceBooking date selection" do
    test "updates time slots when selecting a different date", %{conn: conn, space: space} do
      # Find next Monday from today
      today = Date.utc_today()
      days_until_monday = rem(8 - Date.day_of_week(today), 7)
      days_until_monday = if days_until_monday == 0, do: 7, else: days_until_monday
      monday_date = Date.add(today, days_until_monday)

      {:ok, _monday_slot} =
        BookingSystem.create_time_slot_template(
          ~T[20:00:00],
          ~T[22:00:00],
          :monday,
          space.id
        )

      {:ok, view, _html} = live(conn, ~p"/book/space/#{space.slug}")

      # Click on a date button in the calendar
      view
      |> element("button[phx-value-date='#{Date.to_iso8601(monday_date)}']")
      |> render_click()

      html = render(view)

      assert html =~ "20:00"
      assert html =~ "22:00"
    end

    test "shows selected date in formatted string", %{conn: conn, space: space} do
      {:ok, view, _html} = live(conn, ~p"/book/space/#{space.slug}")

      today = Date.utc_today()
      formatted_date = Calendar.strftime(today, "%A, %B %d, %Y")

      html = render(view)

      assert html =~ formatted_date
    end

    test "does not allow selecting past dates", %{conn: conn, space: space} do
      {:ok, view, _html} = live(conn, ~p"/book/space/#{space.slug}")

      # Navigate to previous month (January 2026), where all dates are in the past
      view
      |> element("button[phx-click='prev-month']")
      |> render_click()

      # Check that there's at least one disabled button (past date)
      html = render(view)
      assert html =~ "disabled"

      # Verify that clicking a past date doesn't change the selected date
      # by checking we can't click on January 15th (a past date)
      refute has_element?(view, "button[phx-click='select-date'][phx-value-date='2026-01-15']")
    end
  end

  describe "SpaceBooking time slot display" do
    test "displays available time slots with correct styling", %{conn: conn, space: space} do
      {:ok, _view, html} = live(conn, ~p"/book/space/#{space.slug}")

      assert html =~ "09:00"
      assert html =~ "13:00"
      assert html =~ "14:00"
      assert html =~ "18:00"
      assert html =~ "Available - Request Booking"
    end

    test "shows high demand label for slots over public capacity", %{
      conn: conn,
      space: space,
      today: today
    } do
      for i <- 1..2 do
        {:ok, booking} =
          request_booking(
            space.id,
            nil,
            today,
            ~T[09:00:00],
            ~T[13:00:00],
            %{name: "User #{i}", email: "user#{i}@example.com", phone: "", comment: ""}
          )

        {:ok, _} = BookingSystem.approve_booking(booking.id)
      end

      {:ok, _view, html} = live(conn, ~p"/book/space/#{space.slug}")

      assert html =~ "High Demand - Join Waitlist"
    end

    test "shows slots over capacity with high demand warning", %{
      conn: conn,
      space: space,
      today: today
    } do
      for i <- 1..3 do
        {:ok, booking} =
          request_booking(
            space.id,
            nil,
            today,
            ~T[09:00:00],
            ~T[13:00:00],
            %{name: "User #{i}", email: "user#{i}@example.com", phone: "", comment: ""}
          )

        {:ok, _} = BookingSystem.approve_booking(booking.id)
      end

      {:ok, view, _html} = live(conn, ~p"/book/space/#{space.slug}")

      html = render(view)

      assert html =~ "14:00"
      assert html =~ "09:00"
      assert html =~ "High Demand"
    end
  end

  describe "SpaceBooking modal interaction" do
    test "opens booking modal when clicking a time slot", %{
      conn: conn,
      space: space,
      slot1: slot1,
      user: user
    } do
      {:ok, view, _html} = live(conn, ~p"/book/space/#{space.slug}")

      view
      |> element("button[phx-click='select_slot'][phx-value-time_slot_id='#{slot1.id}']")
      |> render_click()

      assert has_element?(view, "#booking-modal")
      assert has_element?(view, "input[name='customer_name']")
      # Authenticated users see their email displayed, not an input field
      assert render(view) =~ to_string(user.email)
      assert has_element?(view, "input[name='customer_phone']")
      assert has_element?(view, "textarea[name='customer_comment']")
    end

    test "closes modal when clicking cancel", %{conn: conn, space: space, slot1: slot1} do
      {:ok, view, _html} = live(conn, ~p"/book/space/#{space.slug}")

      view
      |> element("button[phx-click='select_slot'][phx-value-time_slot_id='#{slot1.id}']")
      |> render_click()

      assert has_element?(view, "#booking-modal")

      view
      |> element("button", "Cancel")
      |> render_click()

      refute has_element?(view, "#booking-modal")
    end

    test "shows high demand warning in modal for slots over public capacity", %{
      conn: conn,
      space: space,
      today: today,
      slot1: slot1
    } do
      for i <- 1..2 do
        {:ok, booking} =
          request_booking(
            space.id,
            nil,
            today,
            ~T[09:00:00],
            ~T[13:00:00],
            %{name: "User #{i}", email: "user#{i}@example.com", phone: "", comment: ""}
          )

        {:ok, _} = BookingSystem.approve_booking(booking.id)
      end

      {:ok, view, _html} = live(conn, ~p"/book/space/#{space.slug}")

      html =
        view
        |> element("button[phx-click='select_slot'][phx-value-time_slot_id='#{slot1.id}']")
        |> render_click()

      assert html =~ "High Demand Time Slot"
      assert html =~ "subject to admin approval"
    end
  end

  describe "SpaceBooking submission" do
    test "completes booking request successfully", %{conn: conn, space: space, slot1: slot1} do
      {:ok, view, _html} = live(conn, ~p"/book/space/#{space.slug}")

      view
      |> element("button[phx-click='select_slot'][phx-value-time_slot_id='#{slot1.id}']")
      |> render_click()

      form_data = %{
        "customer_name" => "Test User",
        "customer_email" => "testuser@example.com",
        "customer_phone" => "+39 1234567890",
        "customer_comment" => "Test comment"
      }

      view
      |> element("#booking-form")
      |> render_submit(form_data)

      assert has_element?(view, "#success-modal")
      assert render(view) =~ "Request Submitted!"
      assert render(view) =~ "pending approval"
    end

    test "creates booking in database", %{conn: conn, space: space, today: today, slot1: slot1} do
      {:ok, view, _html} = live(conn, ~p"/book/space/#{space.slug}")

      view
      |> element("button[phx-click='select_slot'][phx-value-time_slot_id='#{slot1.id}']")
      |> render_click()

      form_data = %{
        "customer_name" => "Test User",
        "customer_email" => "testuser@example.com",
        "customer_phone" => "+39 1234567890",
        "customer_comment" => "Test comment"
      }

      view
      |> element("#booking-form")
      |> render_submit(form_data)

      # Process the handle_info message that creates the booking
      render(view)

      day_start = DateTime.new!(today, ~T[00:00:00], "Etc/UTC")
      day_end = DateTime.new!(today, ~T[23:59:59], "Etc/UTC")

      {:ok, bookings} =
        BookingSystem.search_bookings(
          space.id,
          day_start,
          day_end,
          [:requested],
          [:customer_name, :customer_email, :customer_phone, :customer_comment, :state]
        )

      assert length(bookings) == 1
      booking = hd(bookings)
      assert booking.customer_name == "Test User"
      assert booking.customer_email == "testuser@example.com"
      assert booking.customer_phone == "+39 1234567890"
      assert booking.customer_comment == "Test comment"
      assert booking.state == :requested
    end

    test "validates required fields", %{conn: conn, space: space, slot1: slot1} do
      {:ok, view, _html} = live(conn, ~p"/book/space/#{space.slug}")

      view
      |> element("button[phx-click='select_slot'][phx-value-time_slot_id='#{slot1.id}']")
      |> render_click()

      form_data = %{
        "customer_name" => "",
        "customer_email" => "",
        "customer_phone" => "",
        "customer_comment" => ""
      }

      view
      |> element("#booking-form")
      |> render_submit(form_data)

      refute has_element?(view, "#success-modal")
    end

    test "closes success modal when clicking close", %{conn: conn, space: space, slot1: slot1} do
      {:ok, view, _html} = live(conn, ~p"/book/space/#{space.slug}")

      view
      |> element("button[phx-click='select_slot'][phx-value-time_slot_id='#{slot1.id}']")
      |> render_click()

      form_data = %{
        "customer_name" => "Test User",
        "customer_email" => "testuser@example.com",
        "customer_phone" => "",
        "customer_comment" => ""
      }

      view
      |> element("#booking-form")
      |> render_submit(form_data)

      assert has_element?(view, "#success-modal")

      view
      |> element("button[phx-click='close_success_modal']")
      |> render_click()

      refute has_element?(view, "#success-modal")
    end
  end

  describe "SpaceBooking real-time updates" do
    test "updates availability when booking is approved", %{
      conn: conn,
      space: space,
      today: today
    } do
      {:ok, view, _html} = live(conn, ~p"/book/space/#{space.slug}")

      initial_html = render(view)
      assert initial_html =~ "Available - Request Booking"

      {:ok, booking} =
        request_booking(
          space.id,
          nil,
          today,
          ~T[09:00:00],
          ~T[13:00:00],
          %{name: "User 1", email: "user1@example.com", phone: "", comment: ""}
        )

      {:ok, _} = BookingSystem.approve_booking(booking.id)

      html = render(view)
      assert html =~ "Available - Request Booking"

      {:ok, booking2} =
        request_booking(
          space.id,
          nil,
          today,
          ~T[09:00:00],
          ~T[13:00:00],
          %{name: "User 2", email: "user2@example.com", phone: "", comment: ""}
        )

      {:ok, _} = BookingSystem.approve_booking(booking2.id)

      html = render(view)
      assert html =~ "High Demand - Join Waitlist"
    end

    test "updates when booking is cancelled", %{conn: conn, space: space, today: today} do
      {:ok, booking1} =
        request_booking(
          space.id,
          nil,
          today,
          ~T[09:00:00],
          ~T[13:00:00],
          %{name: "User 1", email: "user1@example.com", phone: "", comment: ""}
        )

      {:ok, _} = BookingSystem.approve_booking(booking1.id)

      {:ok, booking2} =
        request_booking(
          space.id,
          nil,
          today,
          ~T[09:00:00],
          ~T[13:00:00],
          %{name: "User 2", email: "user2@example.com", phone: "", comment: ""}
        )

      {:ok, _} = BookingSystem.approve_booking(booking2.id)

      {:ok, view, _html} = live(conn, ~p"/book/space/#{space.slug}")

      html = render(view)
      assert html =~ "High Demand - Join Waitlist"

      {:ok, _} = BookingSystem.cancel_booking(booking1.id, "Test cancellation")

      html = render(view)
      assert html =~ "Available - Request Booking"
    end
  end

  describe "SpaceBooking authenticated user flow" do
    test "pre-fills user data in booking form", %{
      conn: conn,
      space: space,
      user: user,
      slot1: slot1
    } do
      {:ok, view, _html} = live(conn, ~p"/book/space/#{space.slug}")

      html =
        view
        |> element("button[phx-click='select_slot'][phx-value-time_slot_id='#{slot1.id}']")
        |> render_click()

      assert html =~ user.name
      assert html =~ to_string(user.email)
      assert html =~ user.phone_number
    end

    test "uses authenticated user email for booking", %{
      slot1: slot1,
      conn: conn,
      space: space,
      user: user,
      today: today
    } do
      {:ok, view, _html} = live(conn, ~p"/book/space/#{space.slug}")

      view
      |> element("button[phx-click='select_slot'][phx-value-time_slot_id='#{slot1.id}']")
      |> render_click()

      form_data = %{
        "customer_name" => "Test User",
        "customer_phone" => "+39 1234567890",
        "customer_comment" => "Test"
      }

      view
      |> element("#booking-form")
      |> render_submit(form_data)

      # Process the handle_info message that creates the booking
      render(view)

      day_start = DateTime.new!(today, ~T[00:00:00], "Etc/UTC")
      day_end = DateTime.new!(today, ~T[23:59:59], "Etc/UTC")

      {:ok, bookings} =
        BookingSystem.search_bookings(
          space.id,
          day_start,
          day_end,
          [:requested],
          [:customer_email, :user_id]
        )

      assert length(bookings) == 1
      booking = hd(bookings)
      assert to_string(booking.customer_email) == to_string(user.email)
      assert booking.user_id == user.id
    end
  end

  describe "SpaceBooking edge cases" do
    # Note: This test was removed because duplicate booking prevention now correctly
    # blocks the same user from booking the same slot twice, which is the expected behavior.
    # Duplicate booking prevention is thoroughly tested in duplicate_booking_prevention_test.exs

    test "shows high demand when public capacity is reached", %{conn: conn} do
      {:ok, small_space} =
        BookingSystem.create_space(
          "Small Space",
          "small-space",
          "Limited capacity",
          1
        )

      today = Date.utc_today()
      day_of_week = day_of_week_atom(today)

      {:ok, _slot} =
        BookingSystem.create_time_slot_template(
          ~T[09:00:00],
          ~T[10:00:00],
          day_of_week,
          small_space.id
        )

      {:ok, booking} =
        request_booking(
          small_space.id,
          nil,
          today,
          ~T[09:00:00],
          ~T[10:00:00],
          %{name: "User 1", email: "user1@example.com", phone: "", comment: ""}
        )

      {:ok, _} = BookingSystem.approve_booking(booking.id)

      {:ok, _view, html} = live(conn, ~p"/book/space/#{small_space.slug}")

      assert html =~ "High Demand - Join Waitlist"
    end

    test "handles rapid date changes", %{conn: conn, space: space} do
      {:ok, view, _html} = live(conn, ~p"/book/space/#{space.slug}")

      # Use future dates relative to today
      today = Date.utc_today()

      dates = [
        Date.add(today, 1),
        Date.add(today, 2),
        Date.add(today, 3),
        Date.add(today, 1)
      ]

      for date <- dates do
        view
        |> element("button[phx-click='select-date'][phx-value-date='#{Date.to_iso8601(date)}']")
        |> render_click()
      end

      html = render(view)
      # Verify the last selected date is shown (which is Date.add(today, 1))
      final_date = Date.add(today, 1)
      formatted_date = Calendar.strftime(final_date, "%A, %B %d, %Y")
      assert html =~ formatted_date
    end
  end
end
