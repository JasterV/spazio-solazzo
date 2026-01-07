defmodule SpazioSolazzo.Secrets do
  use AshAuthentication.Secret

  def secret_for(
        [:authentication, :tokens, :signing_secret],
        SpazioSolazzo.Accounts.User,
        _opts,
        _context
      ) do
    Application.fetch_env(:spazio_solazzo, :token_signing_secret)
  end
end
