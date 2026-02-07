defmodule SpazioSolazzoWeb.Admin.WalkInLive do
  @moduledoc """
  Admin walk-in booking tool for the coworking space.
  """

  use SpazioSolazzoWeb, :live_view
  alias SpazioSolazzo.BookingSystem

  def mount(_params, _session, socket) do
    {:ok, space} = BookingSystem.get_space_by_slug("arcipelago")

    today = Date.utc_today()
    first_day = Date.beginning_of_month(today)
    booking_counts = fetch_booking_counts(space.id, first_day)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:created")
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:approved")
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:cancelled")
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:rejected")
    end

    {:ok,
     assign(socket,
       space: space,
       first_day_of_month: first_day,
       booking_counts: booking_counts,
       start_date: nil,
       end_date: nil,
       start_time: ~T[09:00:00],
       end_time: ~T[18:00:00],
       multi_day_mode: false,
       customer_details_form: customer_details_form()
     )}
  end

  def handle_event("update_start_time", %{"value" => time_str}, socket) do
    case Time.from_iso8601(time_str <> ":00") do
      {:ok, time} -> {:noreply, assign(socket, start_time: time)}
      _ -> {:noreply, socket}
    end
  end

  def handle_event("update_end_time", %{"value" => time_str}, socket) do
    case Time.from_iso8601(time_str <> ":00") do
      {:ok, time} -> {:noreply, assign(socket, end_time: time)}
      _ -> {:noreply, socket}
    end
  end

  def handle_event("validate_customer_details", form, socket) do
    {:noreply, assign(socket, customer_details_form: to_form(form))}
  end

  def handle_event("create_booking", _, %{assigns: %{start_date: s, end_date: e}} = socket)
      when is_nil(s) or is_nil(e) do
    {:noreply, put_flash(socket, :error, "Please fill in all required fields and select a date")}
  end

  def handle_event("create_booking", form, socket) do
    case parse_submitted_form(form) do
      {:error, error} -> {:noreply, put_flash(socket, :error, error)}
      {:ok, form} -> create_walk_in(form, socket)
    end
  end

  def handle_info({:change_month, new_date}, socket) do
    booking_counts = fetch_booking_counts(socket.assigns.space.id, new_date)
    {:noreply, assign(socket, first_day_of_month: new_date, booking_counts: booking_counts)}
  end

  def handle_info({:date_selected, start_date, end_date}, socket) do
    {:noreply, assign(socket, start_date: start_date, end_date: end_date)}
  end

  def handle_info({:multi_day_mode_toggle, mode}, socket) do
    {:noreply, assign(socket, multi_day_mode: mode)}
  end

  def handle_info(%{topic: "booking:" <> _}, socket) do
    booking_counts =
      fetch_booking_counts(socket.assigns.space.id, socket.assigns.first_day_of_month)

    {:noreply, assign(socket, booking_counts: booking_counts)}
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  defp fetch_booking_counts(space_id, date) do
    start_dt = DateTime.new!(Date.beginning_of_month(date), ~T[00:00:00])
    end_dt = DateTime.new!(Date.end_of_month(date), ~T[23:59:59])

    {:ok, bookings} =
      BookingSystem.search_bookings(
        space_id,
        start_dt,
        end_dt,
        [:accepted],
        [:start_datetime, :end_datetime]
      )

    Enum.reduce(bookings, %{}, fn booking, acc ->
      range =
        Date.range(
          DateTime.to_date(booking.start_datetime),
          DateTime.to_date(booking.end_datetime)
        )

      Enum.reduce(range, acc, fn d, count_acc ->
        Map.update(count_acc, d, 1, &(&1 + 1))
      end)
    end)
  end

  defp create_walk_in(form, socket) do
    %{
      start_date: start_date,
      end_date: end_date,
      start_time: start_time,
      end_time: end_time,
      space: space
    } = socket.assigns

    start_datetime = DateTime.new!(start_date, start_time, "Etc/UTC")
    end_datetime = DateTime.new!(end_date, end_time, "Etc/UTC")

    case BookingSystem.create_walk_in(
           space.id,
           start_datetime,
           end_datetime,
           form.customer_name,
           form.customer_email,
           form.customer_phone
         ) do
      {:ok, _booking} ->
        SpazioSolazzoWeb.Admin.AdminCalendarComponent.reset("walk-in-calendar")

        {:noreply,
         socket
         |> assign(
           customer_details_form: customer_details_form(),
           start_date: nil,
           end_date: nil
         )
         |> put_flash(:info, "Walk-in booking created successfully")}

      {:error, error} ->
        {:noreply, put_flash(socket, :error, "Failed to create walk-in: #{inspect(error)}")}
    end
  end

  defp parse_submitted_form(%{
         "customer_name" => name,
         "customer_email" => email,
         "customer_phone" => phone
       }) do
    name = String.trim(name)
    email = String.trim(email)
    phone = String.trim(phone)

    if name == "" || email == "" do
      {:error, "Please fill in all required fields and select a date"}
    else
      {:ok, %{customer_name: name, customer_email: email, customer_phone: phone}}
    end
  end

  defp days_selected(nil, nil), do: 0
  defp days_selected(start_date, nil) when not is_nil(start_date), do: 1

  defp days_selected(start_date, end_date) when not is_nil(start_date) and not is_nil(end_date),
    do: Date.diff(end_date, start_date) + 1

  defp days_selected(_, _), do: 0

  defp customer_details_form(),
    do: to_form(%{"customer_name" => "", "customer_email" => "", "customer_phone" => ""})
end
