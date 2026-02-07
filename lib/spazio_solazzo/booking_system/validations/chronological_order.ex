defmodule SpazioSolazzo.BookingSystem.Validations.ChronologicalOrder do
  @moduledoc """
  Validates that an end time/datetime occurs after a start time/datetime.
  """
  use Ash.Resource.Validation

  @impl true
  def init(opts) do
    if Keyword.has_key?(opts, :start) && Keyword.has_key?(opts, :end) do
      {:ok, opts}
    else
      {:error, "Both `start` and `end` options are required."}
    end
  end

  @impl true
  def validate(changeset, opts, _context) do
    start_field = opts[:start]
    end_field = opts[:end]

    start_val = get_value(changeset, start_field)
    end_val = get_value(changeset, end_field)

    if start_val && end_val && !after?(end_val, start_val) do
      {:error, field: end_field, message: "must be after #{start_field}"}
    else
      :ok
    end
  end

  defp after?(%Time{} = a, %Time{} = b), do: Time.compare(a, b) == :gt
  defp after?(%DateTime{} = a, %DateTime{} = b), do: DateTime.compare(a, b) == :gt
  defp after?(_, _), do: true

  defp get_value(changeset, field) do
    Ash.Changeset.get_argument(changeset, field) || Ash.Changeset.get_attribute(changeset, field)
  end
end
