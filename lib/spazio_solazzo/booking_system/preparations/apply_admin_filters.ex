defmodule SpazioSolazzo.BookingSystem.Preparations.ApplyAdminFilters do
  @moduledoc """
  Ash Preparation that applies common admin filters (space_id, email, date) to booking queries.
  """
  use Ash.Resource.Preparation

  @impl true
  def prepare(query, _opts, _context) do
    query
    |> apply_space_filter()
    |> apply_email_filter()
    |> apply_date_filter()
  end

  defp apply_space_filter(query) do
    case Ash.Query.get_argument(query, :space_id) do
      nil -> query
      space_id -> Ash.Query.filter(query, space_id == ^space_id)
    end
  end

  defp apply_email_filter(query) do
    case Ash.Query.get_argument(query, :email) do
      nil -> query
      email -> Ash.Query.filter(query, customer_email == ^email)
    end
  end

  defp apply_date_filter(query) do
    case Ash.Query.get_argument(query, :date) do
      nil ->
        query

      date ->
        day_start = DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
        day_end = DateTime.new!(date, ~T[23:59:59], "Etc/UTC")
        Ash.Query.filter(query, start_datetime < ^day_end and end_datetime > ^day_start)
    end
  end
end
