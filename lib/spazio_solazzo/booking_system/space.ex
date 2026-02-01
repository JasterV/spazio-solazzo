defmodule SpazioSolazzo.BookingSystem.Space do
  @moduledoc """
  Represents a physical or virtual space that contains bookable assets.
  """

  use Ash.Resource,
    otp_app: :spazio_solazzo,
    domain: SpazioSolazzo.BookingSystem,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "spaces"
    repo SpazioSolazzo.Repo
  end

  actions do
    defaults [:read]

    create :create do
      accept [:name, :description, :slug, :public_capacity, :real_capacity]

      validate fn changeset, _ctx ->
        real_capacity = Ash.Changeset.get_attribute(changeset, :real_capacity)
        public_capacity = Ash.Changeset.get_attribute(changeset, :public_capacity)

        cond do
          real_capacity && real_capacity <= 0 ->
            {:error, field: :real_capacity, message: "must be greater than 0"}

          public_capacity && public_capacity <= 0 ->
            {:error, field: :public_capacity, message: "must be greater than 0"}

          real_capacity && public_capacity && public_capacity > real_capacity ->
            {:error,
             field: :public_capacity, message: "must be less than or equal to real_capacity"}

          true ->
            :ok
        end
      end
    end

    action :check_availability, :atom do
      argument :space_id, :uuid, allow_nil?: false
      argument :date, :date, allow_nil?: false
      argument :start_time, :time, allow_nil?: false
      argument :end_time, :time, allow_nil?: false

      run fn input, _context ->
        require Ash.Query

        space_id = input.arguments.space_id
        date_arg = input.arguments.date
        start_time_arg = input.arguments.start_time
        end_time_arg = input.arguments.end_time

        # Load the space
        case Ash.get(__MODULE__, space_id) do
          {:ok, space} ->
            # Get accepted bookings for this space on the given date
            query =
              SpazioSolazzo.BookingSystem.Booking
              |> Ash.Query.filter(
                expr(space_id == ^space_id and date == ^date_arg and state == :accepted)
              )

            case Ash.read(query) do
              {:ok, bookings} ->
                # Filter overlapping bookings
                overlapping_bookings =
                  Enum.filter(bookings, fn booking ->
                    Time.compare(booking.start_time, end_time_arg) == :lt and
                      Time.compare(start_time_arg, booking.end_time) == :lt
                  end)

                current_count = length(overlapping_bookings)

                availability =
                  cond do
                    current_count >= space.real_capacity -> :over_real_capacity
                    current_count >= space.public_capacity -> :over_public_capacity
                    true -> :available
                  end

                {:ok, availability}

              error ->
                error
            end

          error ->
            error
        end
      end
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false, public?: true
    attribute :description, :string, allow_nil?: false, public?: true
    attribute :slug, :string, allow_nil?: false, public?: true
    attribute :public_capacity, :integer, allow_nil?: false, public?: true
    attribute :real_capacity, :integer, allow_nil?: false, public?: true
  end

  identities do
    identity :unique_name, [:name]
    identity :unique_slug, [:slug]
  end

  policies do
    policy action(:check_availability) do
      authorize_if always()
    end

    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:create) do
      authorize_if always()
    end
  end
end
