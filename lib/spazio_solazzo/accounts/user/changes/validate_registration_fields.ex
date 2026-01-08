defmodule SpazioSolazzo.Accounts.User.Changes.ValidateRegistrationFields do
  @moduledoc """
  Conditionally validates that name and phone_number are present for new user registrations.
  For existing users (upserts), these fields are not required.
  """
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    email = Ash.Changeset.get_attribute(changeset, :email)

    case SpazioSolazzo.Accounts.get_user_by_email(email, authorize?: false) do
      {:ok, %{phone_number: phone, name: name}} ->
        changeset
        |> Ash.Changeset.force_change_attribute(:name, name)
        |> Ash.Changeset.force_change_attribute(:phone_number, phone)

      _ ->
        name = Ash.Changeset.get_argument(changeset, :name)
        phone = Ash.Changeset.get_argument(changeset, :phone_number)

        changeset
        |> validate_required_for_registration(:name, name)
        |> validate_required_for_registration(:phone_number, phone)
    end
  end

  defp validate_required_for_registration(changeset, field, value) do
    if is_nil(value) || value == "" do
      Ash.Changeset.add_error(
        changeset,
        Ash.Error.Changes.Required.exception(field: field, type: :argument)
      )
    else
      Ash.Changeset.change_attribute(changeset, field, value)
    end
  end
end
