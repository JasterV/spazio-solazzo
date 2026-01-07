defmodule SpazioSolazzo.Accounts do
  use Ash.Domain,
    otp_app: :spazio_solazzo

  resources do
    resource SpazioSolazzo.Accounts.Token
    resource SpazioSolazzo.Accounts.User
  end
end
