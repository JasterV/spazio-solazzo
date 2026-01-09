defmodule SpazioSolazzo.Accounts do
  @moduledoc """
  The Accounts domain manages user authentication and authorization.
  """

  use Ash.Domain,
    otp_app: :spazio_solazzo,
    extensions: [AshPhoenix]

  resources do
    resource SpazioSolazzo.Accounts.Token

    resource SpazioSolazzo.Accounts.User do
      define :request_magic_link, action: :request_magic_link, args: [:email]

      define :sign_in_with_magic_link,
        action: :sign_in_with_magic_link,
        args: [:token, :remember_me, :name, :phone_number]

      define :get_user_by_email, action: :read, get_by: [:email]
      define :terminate_account, action: :terminate_account, args: [:delete_history]
      define :update_profile, action: :update_profile, args: [:name, :phone_number]
    end
  end
end
