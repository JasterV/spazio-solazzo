defmodule SpazioSolazzo.Accounts do
  @moduledoc """
  The Accounts domain manages user authentication and authorization.
  """

  use Ash.Domain,
    otp_app: :spazio_solazzo

  resources do
    resource SpazioSolazzo.Accounts.Token

    resource SpazioSolazzo.Accounts.User do
      define :get_user_by_email, action: :read, get_by: [:email]
    end
  end
end
