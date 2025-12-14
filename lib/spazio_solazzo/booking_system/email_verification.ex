defmodule SpazioSolazzo.BookingSystem.EmailVerification do
  use Ash.Resource,
    domain: SpazioSolazzo.BookingSystem,
    data_layer: AshPostgres.DataLayer,
    notifiers: [Ash.Notifier.PubSub]

  alias SpazioSolazzo.BookingSystem.EmailVerification.VerificationCodeGenerator
  alias SpazioSolazzo.BookingSystem.EmailVerification.EmailSender
  alias SpazioSolazzo.BookingSystem.EmailVerification.CleanupWorker

  postgres do
    table "email_verifications"
    repo SpazioSolazzo.Repo
  end

  actions do
    defaults [:read, :update]

    create :create do
      accept [:email]

      change fn changeset, _ctx ->
        code = VerificationCodeGenerator.generate()
        Ash.Changeset.change_attribute(changeset, :code, code)
      end

      change after_action(fn _changeset, verification, _ctx ->
               EmailSender.send_verification_code(
                 verification.email,
                 verification.code
               )

               %{verification_id: verification.id}
               |> CleanupWorker.new(schedule_in: {verification_timeout(), :seconds})
               |> Oban.insert()

               {:ok, verification}
             end)
    end

    update :verify do
      accept []
      argument :code, :string, allow_nil?: false
      require_atomic? false

      change fn %{data: verification} = changeset, _ctx ->
        code = Ash.Changeset.get_argument(changeset, :code)

        if verification.code == code do
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

    attribute :code, :string do
      allow_nil? false
      public? false
    end

    create_timestamp :inserted_at
  end

  defp verification_timeout do
    Application.get_env(:spazio_solazzo, :verification_timeout, 60)
  end
end
