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
      accept [:name, :description, :slug, :capacity]

      validate fn changeset, _ctx ->
        capacity = Ash.Changeset.get_attribute(changeset, :capacity)

        if capacity && capacity <= 0 do
          {:error, field: :capacity, message: "must be greater than 0"}
        else
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

        start_datetime = DateTime.new!(date_arg, start_time_arg, "Etc/UTC")
        end_datetime = DateTime.new!(date_arg, end_time_arg, "Etc/UTC")

        # Load the space
        case Ash.get(__MODULE__, space_id) do
          {:ok, space} ->
            # Get accepted bookings for this space that overlap with the requested time slot
            query =
              SpazioSolazzo.BookingSystem.Booking
              |> Ash.Query.filter(
                expr(
                  space_id == ^space_id and state == :accepted and start_datetime < ^end_datetime and
                    end_datetime > ^start_datetime
                )
              )

            case Ash.read(query) do
              {:ok, overlapping_bookings} ->
                current_count = length(overlapping_bookings)

                availability =
                  if current_count >= space.capacity do
                    :over_capacity
                  else
                    :available
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

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false, public?: true
    attribute :description, :string, allow_nil?: false, public?: true
    attribute :slug, :string, allow_nil?: false, public?: true
    attribute :capacity, :integer, allow_nil?: false, public?: true
  end

  identities do
    identity :unique_name, [:name]
    identity :unique_slug, [:slug]
  end
end
