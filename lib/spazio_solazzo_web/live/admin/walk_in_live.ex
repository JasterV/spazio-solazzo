defmodule SpazioSolazzoWeb.Admin.WalkInLive do
  @moduledoc """
  Admin walk-in booking tool for the coworking space.
  """

  use SpazioSolazzoWeb, :live_view
  alias SpazioSolazzo.BookingSystem

  def mount(_params, _session, socket) do
    {:ok, space} = BookingSystem.get_space_by_slug("coworking")

    {:ok,
     assign(socket,
       space: space,
       multi_day_mode: false,
       start_date: nil,
       end_date: nil,
       start_time: ~T[09:00:00],
       end_time: ~T[18:00:00],
       customer_details_form: customer_details_form()
     )}
  end

  def handle_event("update_start_time", %{"value" => time_str}, socket) do
    case Time.from_iso8601(time_str <> ":00") do
      {:ok, time} ->
        {:noreply, assign(socket, start_time: time)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("update_end_time", %{"value" => time_str}, socket) do
    case Time.from_iso8601(time_str <> ":00") do
      {:ok, time} ->
        {:noreply, assign(socket, end_time: time)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event(
        "validate_customer_details",
        form,
        socket
      ) do
    {:noreply, assign(socket, customer_details_form: to_form(form))}
  end

  def handle_event(
        "create_booking",
        _,
        %{assigns: %{start_date: start_date, end_date: end_date}} = socket
      )
      when is_nil(start_date) or is_nil(end_date) do
    {:noreply, put_flash(socket, :error, "Please fill in all required fields and select a date")}
  end

  def handle_event("create_booking", form, socket) do
    case parse_submitted_form(form) do
      {:error, error} -> {:noreply, put_flash(socket, :error, error)}
      {:ok, form} -> create_walk_in(form, socket)
    end
  end

  defp create_walk_in(
         form,
         %{
           assigns: %{
             start_date: start_date,
             end_date: end_date,
             start_time: start_time,
             end_time: end_time,
             space: space
           }
         } = socket
       ) do
    start_datetime =
      DateTime.new!(start_date, start_time, "Etc/UTC")

    end_datetime =
      DateTime.new!(end_date, end_time, "Etc/UTC")

    case BookingSystem.create_walk_in(
           space.id,
           start_datetime,
           end_datetime,
           form.customer_name,
           form.customer_email,
           form.customer_phone
         ) do
      {:ok, _booking} ->
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
         "customer_name" => customer_name,
         "customer_email" => customer_email,
         "customer_phone" => customer_phone
       }) do
    customer_name = String.trim(customer_name)
    customer_email = String.trim(customer_email)
    customer_phone = String.trim(customer_phone)

    if customer_name == "" || customer_email == "" do
      {:error, "Please fill in all required fields and select a date"}
    else
      {:ok,
       %{
         customer_name: customer_name,
         customer_email: customer_email,
         customer_phone: customer_phone
       }}
    end
  end

  def handle_info({:multi_day_mode_changed, multi_day}, socket) do
    {:noreply, assign(socket, multi_day_mode: multi_day)}
  end

  def handle_info({:date_selected, start_date, end_date}, socket) do
    {:noreply, assign(socket, start_date: start_date, end_date: end_date)}
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  defp days_selected(nil, nil), do: 0
  defp days_selected(start_date, nil) when not is_nil(start_date), do: 1

  defp days_selected(start_date, end_date)
       when not is_nil(start_date) and not is_nil(end_date) do
    Date.diff(end_date, start_date) + 1
  end

  defp days_selected(_, _), do: 0

  defp customer_details_form() do
    to_form(%{"customer_name" => "", "customer_email" => "", "customer_phone" => ""})
  end
end
