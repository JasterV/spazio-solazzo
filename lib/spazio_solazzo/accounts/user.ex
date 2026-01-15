defmodule SpazioSolazzo.Accounts.User do
  @moduledoc """
  Represents a user in the system with magic link authentication.
  """

  use Ash.Resource,
    otp_app: :spazio_solazzo,
    domain: SpazioSolazzo.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAuthentication]

  authentication do
    add_ons do
      log_out_everywhere do
        apply_on_password_change? true
      end
    end

    tokens do
      enabled? true
      token_resource SpazioSolazzo.Accounts.Token
      signing_secret SpazioSolazzo.Secrets
      store_all_tokens? true
      require_token_presence_for_authentication? true
    end

    strategies do
      magic_link do
        identity_field :email
        registration_enabled? true
        require_interaction? true
        sender SpazioSolazzo.Accounts.User.Senders.SendMagicLinkEmail
      end

      remember_me :remember_me
    end
  end

  postgres do
    table "users"
    repo SpazioSolazzo.Repo
  end

  actions do
    defaults [:read]

    read :get_by_email do
      description "Looks up a user by their email"
      argument :email, :ci_string, allow_nil?: false
      get? true
      filter expr(email == ^arg(:email))
    end

    create :sign_in_with_magic_link do
      description "Sign in or register a user with magic link."

      argument :token, :string do
        description "The token from the magic link that was sent to the user"
        allow_nil? false
      end

      argument :remember_me, :boolean do
        description "Whether to generate a remember me token"
        allow_nil? true
      end

      argument :name, :string do
        description "User's full name (required for new users)"
        allow_nil? true
      end

      argument :phone_number, :string do
        description "User's phone number (required for new users)"
        allow_nil? true
      end

      upsert? true
      upsert_identity :unique_email
      upsert_fields [:email, :name, :phone_number]

      # Uses the information from the token to create or sign in the user
      change AshAuthentication.Strategy.MagicLink.SignInChange

      # Conditionally validate name and phone_number for new users
      change SpazioSolazzo.Accounts.User.Changes.ParseRegistrationFields

      change {AshAuthentication.Strategy.RememberMe.MaybeGenerateTokenChange,
              strategy_name: :remember_me}

      metadata :token, :string do
        allow_nil? false
      end
    end

    action :request_magic_link do
      argument :email, :ci_string, allow_nil?: false
      run AshAuthentication.Strategy.MagicLink.Request
    end

    update :update_profile do
      description "Update user profile (name and phone number)"
      accept [:name, :phone_number]
      require_atomic? false
    end

    destroy :terminate_account do
      description "Delete user account with optional booking data removal"
      require_atomic? false

      argument :delete_history, :boolean do
        description "Whether to permanently delete all booking history"
        default false
      end

      change SpazioSolazzo.Accounts.User.Changes.HandleBookingsOnAccountDeletion
    end
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end

    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:update) do
      authorize_if expr(id == ^actor(:id))
    end

    policy action_type(:destroy) do
      authorize_if expr(id == ^actor(:id))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :ci_string do
      allow_nil? false
      public? true
    end

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :phone_number, :string do
      allow_nil? true
      public? true
    end
  end

  identities do
    identity :unique_email, [:email]
  end
end
