defmodule SpazioSolazzo.BookingSystem.EmailVerification do
  use Ash.Resource,
    domain: SpazioSolazzo.BookingSystem,
    data_layer: AshPostgres.DataLayer,
    notifiers: [Ash.Notifier.PubSub]

  alias SpazioSolazzo.BookingSystem.EmailVerification.Code
  alias SpazioSolazzo.BookingSystem.EmailVerification.CleanupWorker
  alias SpazioSolazzo.BookingSystem.EmailVerification.EmailWorker

  postgres do
    table "email_verifications"
    repo SpazioSolazzo.Repo
  end

  actions do
    defaults [:read, :update]

    create :create do
      accept [:email]

      change fn changeset, _ctx ->
        raw_code = Code.generate()
        hashed_code = Bcrypt.hash_pwd_salt(raw_code)

        changeset
        |> Ash.Changeset.change_attribute(:code_hash, hashed_code)
        # We force the raw code into the context so it's available
        # in the 'verification' struct passed to the after_action hook below.
        |> Ash.Changeset.put_context(:raw_code, raw_code)
      end

      change after_action(fn changeset, verification, _ctx ->
               %{
                 verification_email: verification.email,
                 verification_code: changeset.context.raw_code
               }
               |> EmailWorker.new()
               |> Oban.insert!()

               %{verification_id: verification.id}
               |> CleanupWorker.new(schedule_in: {verification_timeout(), :seconds})
               |> Oban.insert!()

               {:ok, verification}
             end)
    end

    update :verify do
      accept []

      argument :code, :string do
        allow_nil? false
        sensitive? true
      end

      require_atomic? false

      change fn %{data: verification} = changeset, _ctx ->
        input_code = Ash.Changeset.get_argument(changeset, :code)

        if Bcrypt.verify_pass(input_code, verification.code_hash) do
          changeset
        else
          Ash.Changeset.add_error(changeset,
            field: :code,
            message: "Invalid verification code"
          )
        end
      end

      change after_action(fn _changeset, verification, _ctx ->
               # Delete verification after successful verification
               Ash.destroy!(verification)
               {:ok, verification}
             end)
    end

    destroy :destroy do
      primary? true
    end

    destroy :expire
  end

  pub_sub do
    module SpazioSolazzoWeb.Endpoint
    prefix "email_verification"

    publish :expire, ["verification_code_expired", :id]
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :string do
      allow_nil? false
      public? true
    end

    attribute :code_hash, :string do
      allow_nil? false
      sensitive? true
      public? false
    end

    create_timestamp :inserted_at
  end

  defp verification_timeout do
    Application.get_env(:spazio_solazzo, :verification_timeout)
  end
end
