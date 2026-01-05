defmodule SpazioSolazzo.BookingSystem.EmailVerification.Code do
  @moduledoc """
  Generate unique email verification codes
  """

  def generate do
    <<code::32>> = :crypto.strong_rand_bytes(4)
    code = rem(code, 1_000_000)

    code
    |> Integer.to_string()
    |> String.pad_leading(6, "0")
  end
end
