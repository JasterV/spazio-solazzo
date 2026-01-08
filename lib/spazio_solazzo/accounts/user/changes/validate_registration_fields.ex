defmodule SpazioSolazzo.Accounts.User.Changes.ValidateRegistrationFields do
  @moduledoc """
  Conditionally validates that name and phone_number are present for new user registrations.
  For existing users (upserts), these fields are not required.
  """
  use Ash.Resource.Change

  # TODO: Fix this logic, the action type is always create
  # We need another way to check if the user already existed or not
  @impl true
  def change(changeset, _opts, _context) do
    if changeset.action_type == :create do
      changeset
      |> validate_argument_present(:name, "Name is required for new users")
      |> validate_argument_present(:phone_number, "Phone number is required for new users")
      |> set_attributes_from_arguments()
    else
      changeset
    end
  end

  defp validate_argument_present(changeset, argument, message) do
    case Ash.Changeset.fetch_argument(changeset, argument) do
      {:ok, value} when not is_nil(value) and value != "" ->
        changeset

      _ ->
        Ash.Changeset.add_error(changeset, field: argument, message: message)
    end
  end

  defp set_attributes_from_arguments(changeset) do
    changeset
    |> maybe_set_attribute(:name)
    |> maybe_set_attribute(:phone_number)
  end

  defp maybe_set_attribute(changeset, field) do
    case Ash.Changeset.fetch_argument(changeset, field) do
      {:ok, value} when not is_nil(value) ->
        Ash.Changeset.change_attribute(changeset, field, value)

      _ ->
        changeset
    end
  end
end
