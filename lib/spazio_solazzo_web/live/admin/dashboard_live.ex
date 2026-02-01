defmodule SpazioSolazzoWeb.Admin.DashboardLive do
  @moduledoc """
  Admin dashboard for managing booking requests and creating walk-in bookings.
  """

  use SpazioSolazzoWeb, :live_view

  alias SpazioSolazzo.BookingSystem

  def mount(_params, _session, socket) do
    {:ok, spaces} = Ash.read(SpazioSolazzo.BookingSystem.Space)
    {:ok, requests} = BookingSystem.list_booking_requests(nil, nil, nil, load: [:space, :user])

    if connected?(socket) do
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:created")
    end

    {:ok,
     assign(socket,
       active_tab: :requests,
       spaces: spaces,
       requests: requests,
       filter_space_id: nil,
       filter_email: nil,
       filter_date: nil,
       show_reject_modal: false,
       rejecting_booking_id: nil,
       rejection_reason: "",
       walk_in_form: %{
         space_id: nil,
         customer_name: "",
         customer_email: "",
         customer_phone: "",
         customer_comment: "",
         start_datetime: nil,
         end_datetime: nil
       },
       capacity_warning: nil
     )}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: String.to_existing_atom(tab))}
  end

  def handle_event("filter_requests", params, socket) do
    space_id = if params["space_id"] == "", do: nil, else: params["space_id"]
    email = if params["email"] == "", do: nil, else: params["email"]

    date =
      if params["date"] == "",
        do: nil,
        else: Date.from_iso8601!(params["date"])

    {:ok, requests} =
      BookingSystem.list_booking_requests(space_id, email, date, load: [:space, :user])

    {:noreply,
     assign(socket,
       requests: requests,
       filter_space_id: space_id,
       filter_email: email,
       filter_date: date
     )}
  end

  def handle_event("approve_booking", %{"booking_id" => booking_id}, socket) do
    case Ash.get(SpazioSolazzo.BookingSystem.Booking, booking_id) do
      {:ok, booking} ->
        case BookingSystem.approve_booking(booking) do
          {:ok, _approved} ->
            {:ok, requests} =
              BookingSystem.list_booking_requests(
                socket.assigns.filter_space_id,
                socket.assigns.filter_email,
                socket.assigns.filter_date,
                load: [:space, :user]
              )

            {:noreply,
             socket
             |> assign(requests: requests)
             |> put_flash(:info, "Booking approved successfully")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to approve booking")}
        end

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Booking not found")}
    end
  end

  def handle_event("show_reject_modal", %{"booking_id" => booking_id}, socket) do
    {:noreply,
     assign(socket,
       show_reject_modal: true,
       rejecting_booking_id: booking_id,
       rejection_reason: ""
     )}
  end

  def handle_event("hide_reject_modal", _, socket) do
    {:noreply,
     assign(socket,
       show_reject_modal: false,
       rejecting_booking_id: nil,
       rejection_reason: ""
     )}
  end

  def handle_event("update_rejection_reason", %{"reason" => reason}, socket) do
    {:noreply, assign(socket, rejection_reason: reason)}
  end

  def handle_event("confirm_reject", _, socket) do
    if String.trim(socket.assigns.rejection_reason) == "" do
      {:noreply, put_flash(socket, :error, "Please provide a rejection reason")}
    else
      case Ash.get(SpazioSolazzo.BookingSystem.Booking, socket.assigns.rejecting_booking_id) do
        {:ok, booking} ->
          case BookingSystem.reject_booking(booking, socket.assigns.rejection_reason) do
            {:ok, _rejected} ->
              {:ok, requests} =
                BookingSystem.list_booking_requests(
                  socket.assigns.filter_space_id,
                  socket.assigns.filter_email,
                  socket.assigns.filter_date,
                  load: [:space, :user]
                )

              {:noreply,
               socket
               |> assign(
                 requests: requests,
                 show_reject_modal: false,
                 rejecting_booking_id: nil,
                 rejection_reason: ""
               )
               |> put_flash(:info, "Booking rejected")}

            {:error, _} ->
              {:noreply, put_flash(socket, :error, "Failed to reject booking")}
          end

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Booking not found")}
      end
    end
  end

  def handle_event("update_walk_in_form", params, socket) do
    form = socket.assigns.walk_in_form

    updated_form =
      Map.merge(form, %{
        space_id: params["space_id"],
        customer_name: params["customer_name"] || form.customer_name,
        customer_email: params["customer_email"] || form.customer_email,
        customer_phone: params["customer_phone"] || form.customer_phone,
        customer_comment: params["customer_comment"] || form.customer_comment,
        start_datetime: parse_datetime(params["start_datetime"]),
        end_datetime: parse_datetime(params["end_datetime"])
      })

    {:noreply, assign(socket, walk_in_form: updated_form)}
  end

  def handle_event("create_walk_in", _, socket) do
    form = socket.assigns.walk_in_form

    with true <- form.space_id != nil,
         true <- form.customer_name != "",
         true <- form.customer_email != "",
         true <- form.start_datetime != nil,
         true <- form.end_datetime != nil do
      case BookingSystem.create_walk_in(
             form.space_id,
             %{
               name: form.customer_name,
               email: form.customer_email,
               phone: form.customer_phone,
               comment: form.customer_comment
             },
             form.start_datetime,
             form.end_datetime
           ) do
        {:ok, _booking} ->
          {:noreply,
           socket
           |> assign(
             walk_in_form: %{
               space_id: nil,
               customer_name: "",
               customer_email: "",
               customer_phone: "",
               customer_comment: "",
               start_datetime: nil,
               end_datetime: nil
             },
             capacity_warning: nil
           )
           |> put_flash(:info, "Walk-in booking created successfully")}

        {:error, error} ->
          {:noreply, put_flash(socket, :error, "Failed to create walk-in: #{inspect(error)}")}
      end
    else
      _ ->
        {:noreply, put_flash(socket, :error, "Please fill in all required fields")}
    end
  end

  def handle_info(
        %{topic: "booking:created", payload: %{data: _data}},
        socket
      ) do
    {:ok, requests} =
      BookingSystem.list_booking_requests(
        socket.assigns.filter_space_id,
        socket.assigns.filter_email,
        socket.assigns.filter_date,
        load: [:space, :user]
      )

    {:noreply, assign(socket, requests: requests)}
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  defp parse_datetime(nil), do: nil
  defp parse_datetime(""), do: nil

  defp parse_datetime(datetime_string) do
    case DateTime.from_iso8601(datetime_string <> ":00Z") do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end
end
