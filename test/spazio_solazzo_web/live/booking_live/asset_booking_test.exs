defmodule SpazioSolazzoWeb.BookingLive.AssetBookingTest do
  use SpazioSolazzoWeb.ConnCase
  import Phoenix.LiveViewTest

  alias SpazioSolazzo.BookingSystem
  alias SpazioSolazzo.Accounts.User

  setup %{conn: conn} do
    {:ok, space} = BookingSystem.create_space("TestSpace", "test-space", "Test description")
    {:ok, asset} = BookingSystem.create_asset("Test Asset", space.id)

    today = Date.utc_today()
    day_of_week = SpazioSolazzo.DateExt.day_of_week_atom(today)

    {:ok, slot} =
      BookingSystem.create_time_slot_template(
        ~T[09:00:00],
        ~T[10:00:00],
        day_of_week,
        space.id
      )

    conn = Plug.Test.init_test_session(conn, %{})
    conn = log_in_user(conn)

    %{space: space, asset: asset, slot: slot, conn: conn}
  end

  defp log_in_user(conn) do
    {:ok, user} =
      SpazioSolazzo.Repo.insert(%User{
        id: Ash.UUID.generate(),
        email: "test@example.com",
        name: "Test User",
        phone_number: "+1234567890"
      })

    {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(user)

    conn
    |> Plug.Test.init_test_session(%{})
    |> Plug.Conn.put_session("user_token", token)
  end

  describe "AssetBooking mount" do
    test "renders asset booking page with available time slots", %{
      conn: conn,
      space: space,
      asset: asset
    } do
      {:ok, view, html} = live(conn, ~p"/book/asset/#{asset.id}")

      assert html =~ space.name
      assert html =~ asset.name
      assert html =~ "Available Time Slots"
      assert has_element?(view, "button[phx-click='select_slot']")
      assert has_element?(view, "#booking-calendar")
    end

    test "displays calendar with current month", %{conn: conn, asset: asset} do
      {:ok, view, html} = live(conn, ~p"/book/asset/#{asset.id}")

      today = Date.utc_today()
      month_name = Calendar.strftime(today, "%B %Y")

      assert html =~ month_name
      assert has_element?(view, ".calendar-container")
    end

    test "displays back button to space landing page", %{conn: conn, asset: asset, space: space} do
      {:ok, _view, html} = live(conn, ~p"/book/asset/#{asset.id}")

      assert html =~ "Back to #{space.name}"
      assert html =~ "/#{space.slug}"
    end

    test "redirects when asset not found", %{conn: conn} do
      assert {:error, {:live_redirect, %{to: "/", flash: %{"error" => "Asset not found"}}}} =
               live(conn, ~p"/book/asset/00000000-0000-0000-0000-000000000000")
    end
  end

  describe "AssetBooking time slot selection" do
    test "opens booking modal when clicking a time slot", %{conn: conn, asset: asset} do
      {:ok, view, _html} = live(conn, ~p"/book/asset/#{asset.id}")

      view
      |> element("button[phx-click='select_slot']")
      |> render_click()

      assert has_element?(view, "#booking-modal")
      assert has_element?(view, "textarea[name='customer_comment']")
    end
  end

  describe "AssetBooking full booking flow" do
    test "completes full booking flow", %{conn: conn, asset: asset} do
      {:ok, view, _html} = live(conn, ~p"/book/asset/#{asset.id}")

      view
      |> element("button[phx-click='select_slot']")
      |> render_click()

      assert has_element?(view, "#booking-modal")

      view
      |> element("#booking-form")
      |> render_submit(%{"customer_comment" => "test comment"})

      assert has_element?(view, "#success-modal")

      assert {:ok, [booking]} =
               BookingSystem.list_active_asset_bookings_by_date(asset.id, Date.utc_today())

      assert booking.customer_email == "test@example.com"
      assert booking.customer_name == "Test User"
      assert booking.customer_phone == "+1234567890"
      assert booking.customer_comment == "test comment"
    end
  end

  describe "AssetBooking cancellation" do
    test "cancels booking flow", %{conn: conn, asset: asset} do
      {:ok, view, _html} = live(conn, ~p"/book/asset/#{asset.id}")

      view
      |> element("button[phx-click='select_slot']")
      |> render_click()

      assert has_element?(view, "#booking-modal")

      view
      |> element("button", "Cancel")
      |> render_click()

      refute has_element?(view, "#booking-form")
    end
  end

  describe "AssetBooking date selection" do
    test "updates available time slots when selecting date from calendar", %{
      conn: conn,
      asset: asset,
      space: space
    } do
      {:ok, view, _html} = live(conn, ~p"/book/asset/#{asset.id}")

      tomorrow = Date.add(Date.utc_today(), 1)
      tomorrow_day_of_week = SpazioSolazzo.DateExt.day_of_week_atom(tomorrow)

      {:ok, _slot} =
        BookingSystem.create_time_slot_template(
          ~T[14:00:00],
          ~T[15:00:00],
          tomorrow_day_of_week,
          space.id
        )

      # Click on a date in the calendar
      view
      |> element(
        "#booking-calendar button[phx-click='select-date'][phx-value-date='#{Date.to_iso8601(tomorrow)}']"
      )
      |> render_click()

      assert has_element?(view, "button[phx-click='select_slot']")
    end

    test "prevents selection of past dates", %{conn: conn, asset: asset} do
      {:ok, view, _html} = live(conn, ~p"/book/asset/#{asset.id}")

      yesterday = Date.add(Date.utc_today(), -1)

      # Past dates should be disabled
      assert has_element?(
               view,
               "#booking-calendar button[disabled][phx-value-date='#{Date.to_iso8601(yesterday)}']"
             )
    end

    test "displays selected date in the time slots section", %{conn: conn, asset: asset} do
      {:ok, view, _html} = live(conn, ~p"/book/asset/#{asset.id}")

      today = Date.utc_today()
      formatted_date = SpazioSolazzo.CalendarExt.format_date(today)

      assert has_element?(view, ".time-slots-wrapper", formatted_date)
    end
  end

  describe "AssetBooking calendar navigation" do
    test "navigates to next month", %{conn: conn, asset: asset} do
      {:ok, view, _html} = live(conn, ~p"/book/asset/#{asset.id}")

      current_month = Date.utc_today() |> Date.beginning_of_month()
      next_month = Date.shift(current_month, month: 1)
      next_month_name = Calendar.strftime(next_month, "%B %Y")

      view
      |> element("#booking-calendar button[phx-click='next-month']")
      |> render_click()

      assert has_element?(view, ".calendar-container", next_month_name)
    end

    test "navigates to previous month", %{conn: conn, asset: asset} do
      {:ok, view, _html} = live(conn, ~p"/book/asset/#{asset.id}")

      current_month = Date.utc_today() |> Date.beginning_of_month()
      prev_month = Date.shift(current_month, month: -1)
      prev_month_name = Calendar.strftime(prev_month, "%B %Y")

      view
      |> element("#booking-calendar button[phx-click='prev-month']")
      |> render_click()

      assert has_element?(view, ".calendar-container", prev_month_name)
    end

    test "only displays days from current viewing month", %{conn: conn, asset: asset} do
      {:ok, _view, html} = live(conn, ~p"/book/asset/#{asset.id}")

      # Calendar should have empty divs for days not in current month
      assert html =~ ~s(<div class="p-2"></div>)
    end
  end
end
