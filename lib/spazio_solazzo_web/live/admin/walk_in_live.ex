defmodule SpazioSolazzoWeb.Admin.WalkInLive do
  @moduledoc """
  Admin walk-in booking tool for the coworking space.
  """

  use SpazioSolazzoWeb, :live_view

  alias SpazioSolazzo.BookingSystem

  def mount(_params, _session, socket) do
    # Get coworking space
    {:ok, spaces} = Ash.read(SpazioSolazzo.BookingSystem.Space)
    coworking_space = Enum.find(spaces, &(&1.slug == "coworking"))

    if coworking_space == nil do
      {:ok,
       socket
       |> put_flash(:error, "Coworking space not found")
       |> push_navigate(to: "/admin/dashboard")}
    else
      {:ok,
       assign(socket,
         coworking_space: coworking_space,
         multi_day_mode: false,
         start_date: nil,
         end_date: nil,
         selected_date: nil,
         start_time: ~T[09:00:00],
         end_time: ~T[18:00:00],
         customer_name: "",
         customer_email: "",
         customer_phone: "",
         customer_comment: "",
         time_slot_warning: nil
       )}
    end
  end

  def handle_event("update_start_time", %{"value" => time_str}, socket) do
    case Time.from_iso8601(time_str <> ":00") do
      {:ok, time} ->
        socket =
          socket
          |> assign(start_time: time)
          |> check_time_slot_capacity()

        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("update_end_time", %{"value" => time_str}, socket) do
    case Time.from_iso8601(time_str <> ":00") do
      {:ok, time} ->
        socket =
          socket
          |> assign(end_time: time)
          |> check_time_slot_capacity()

        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("update_customer_details", params, socket) do
    {:noreply,
     assign(socket,
       customer_name: Map.get(params, "customer_name", ""),
       customer_email: Map.get(params, "customer_email", ""),
       customer_phone: Map.get(params, "customer_phone", ""),
       customer_comment: Map.get(params, "customer_comment", "")
     )}
  end

  def handle_event("create_booking", _, socket) do
    with true <- socket.assigns.customer_name != "",
         true <- socket.assigns.customer_email != "",
         start_date when not is_nil(start_date) <- get_start_date(socket),
         end_date when not is_nil(end_date) <- get_end_date(socket) do
      # Create datetime objects
      start_datetime =
        DateTime.new!(start_date, socket.assigns.start_time, "Etc/UTC")

      end_datetime =
        DateTime.new!(end_date, socket.assigns.end_time, "Etc/UTC")

      case BookingSystem.create_walk_in(
             socket.assigns.coworking_space.id,
             start_datetime,
             end_datetime,
             socket.assigns.customer_name,
             socket.assigns.customer_email,
             socket.assigns.customer_phone,
             socket.assigns.customer_comment
           ) do
        {:ok, _booking} ->
          {:noreply,
           socket
           |> assign(
             customer_name: "",
             customer_email: "",
             customer_phone: "",
             customer_comment: "",
             start_date: nil,
             end_date: nil,
             selected_date: nil,
             time_slot_warning: nil
           )
           |> put_flash(:info, "Walk-in booking created successfully")}

        {:error, error} ->
          {:noreply, put_flash(socket, :error, "Failed to create walk-in: #{inspect(error)}")}
      end
    else
      _ ->
        {:noreply,
         put_flash(socket, :error, "Please fill in all required fields and select a date")}
    end
  end

  def handle_info({:multi_day_mode_changed, multi_day}, socket) do
    {:noreply, assign(socket, multi_day_mode: multi_day)}
  end

  def handle_info({:date_selected, start_date, end_date}, socket) do
    socket =
      socket
      |> assign(start_date: start_date, end_date: end_date, selected_date: nil)
      |> check_time_slot_capacity()

    {:noreply, socket}
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  defp get_start_date(socket) do
    socket.assigns.start_date || socket.assigns.selected_date
  end

  defp get_end_date(socket) do
    socket.assigns.end_date || socket.assigns.selected_date
  end

  defp check_time_slot_capacity(socket) do
    # Only check for single-day bookings
    if socket.assigns.multi_day_mode || socket.assigns.selected_date == nil do
      assign(socket, time_slot_warning: nil)
    else
      date = socket.assigns.selected_date

      case BookingSystem.check_availability(
             socket.assigns.coworking_space.id,
             date,
             socket.assigns.start_time,
             socket.assigns.end_time
           ) do
        {:ok, :over_capacity} ->
          assign(socket,
            time_slot_warning: "This time slot is currently overbooked. Proceed with caution."
          )

        _ ->
          assign(socket, time_slot_warning: nil)
      end
    end
  end

  defp days_selected(nil, nil, nil), do: 0
  defp days_selected(selected, nil, nil) when not is_nil(selected), do: 1
  defp days_selected(nil, start_date, nil) when not is_nil(start_date), do: 1

  defp days_selected(nil, start_date, end_date)
       when not is_nil(start_date) and not is_nil(end_date) do
    Date.diff(end_date, start_date) + 1
  end

  defp days_selected(_, _, _), do: 0
end
