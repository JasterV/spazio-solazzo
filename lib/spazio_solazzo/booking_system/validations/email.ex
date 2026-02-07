defmodule SpazioSolazzo.BookingSystem.Validations.Email do
  @moduledoc """
  Validates that a field contains a valid email address.
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

    if value && !String.match?(value, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/) do
      {:error, field: field, message: "must be a valid email"}
    else
      :ok
    end
  end

  defp get_value(changeset, field) do
    Ash.Changeset.get_argument(changeset, field) || Ash.Changeset.get_attribute(changeset, field)
  end
end
