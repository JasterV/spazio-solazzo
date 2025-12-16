defmodule SpazioSolazzo.BookingSystem.EmailVerification.Code do
  @moduledoc """
  Generate unique email verification codes
  """

  def generate do
    :rand.uniform(999_999)
    |> Integer.to_string()
    |> String.pad_leading(6, "0")
  end
end
