defmodule SpazioSolazzo.BookingSystem.Validations.FutureDate do
  @moduledoc """
  Validates that a date or datetime is in the future relative to UTC now/today.
  """
  use Ash.Resource.Validation

  @impl true
  def init(opts) do
    if Keyword.has_key?(opts, :field) do
      {:ok, opts}
    else
      {:error, "The `field` option is required."}
    end
  end

  @impl true
  def validate(changeset, opts, _context) do
    field = opts[:field]
    value = get_value(changeset, field)

    if value && in_past?(value) do
      {:error, field: field, message: "cannot be in the past"}
    else
      :ok
    end
  end

  defp in_past?(%Date{} = date), do: Date.compare(date, Date.utc_today()) == :lt
  defp in_past?(%DateTime{} = dt), do: DateTime.compare(dt, DateTime.utc_now()) == :lt
  defp in_past?(_), do: false

  defp get_value(changeset, field) do
    Ash.Changeset.get_argument(changeset, field) || Ash.Changeset.get_attribute(changeset, field)
  end
end
