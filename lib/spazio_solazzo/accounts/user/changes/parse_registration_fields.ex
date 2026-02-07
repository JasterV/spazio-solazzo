defmodule SpazioSolazzo.Accounts.User.Changes.ParseRegistrationFields do
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
        # User is already registered, we'll just set the same values it had
        changeset
        |> Ash.Changeset.force_change_attribute(:name, name)
        |> Ash.Changeset.force_change_attribute(:phone_number, phone)

      _ ->
        # User is not yet registered, we'll parse & validate the new values
        name = Ash.Changeset.get_argument(changeset, :name)
        phone = Ash.Changeset.get_argument(changeset, :phone_number)

        changeset
        |> parse_name(name)
        |> parse_phone_number(phone)
    end
  end

  defp parse_name(changeset, nil) do
    Ash.Changeset.add_error(
      changeset,
      Ash.Error.Changes.Required.exception(field: :name, type: :argument)
    )
  end

  defp parse_name(changeset, value) do
    value = String.trim(value)

    if value == "" do
      parse_name(changeset, nil)
    else
      Ash.Changeset.change_attribute(changeset, :name, value)
    end
  end

  defp parse_phone_number(changeset, nil) do
    # The phone number is nullable, this is fine
    Ash.Changeset.change_attribute(changeset, :phone_number, nil)
  end

  defp parse_phone_number(changeset, value) do
    value = String.trim(value)

    if value == "" do
      # Instead of returning an error, we'll consider an empty phone number
      # as if the user didn't want to set one, which is valid.
      parse_name(changeset, nil)
    else
      Ash.Changeset.change_attribute(changeset, :phone_number, value)
    end
  end
end
