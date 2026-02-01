defmodule SpazioSolazzo.Accounts.User.Changes.HandleBookingsOnAccountDeletion do
  @moduledoc """
  Handles booking cleanup when a user account is terminated.

  - Cancels all future requested/accepted bookings with a reason
  - Either deletes all bookings or lets the database nullify them based on delete_history argument
  """
  use Ash.Resource.Change
  require Ash.Query
  alias SpazioSolazzo.BookingSystem.Booking
  alias SpazioSolazzo.BookingSystem

  def change(changeset, _opts, _context) do
    changeset
    |> Ash.Changeset.before_action(fn changeset ->
      user = changeset.data
      delete_history = Ash.Changeset.get_argument(changeset, :delete_history)

      future_bookings =
        Booking
        |> Ash.Query.filter(
          user_id == ^user.id and state in [:requested, :accepted] and date >= ^Date.utc_today()
        )
        |> Ash.read!()

      Enum.each(future_bookings, fn booking ->
        BookingSystem.cancel_booking!(booking, "Account deleted by user")
      end)

      if delete_history do
        Booking
        |> Ash.Query.filter(user_id == ^user.id)
        |> Ash.bulk_destroy!(:destroy, %{}, authorize?: false)
      end

      changeset
    end)
  end
end
