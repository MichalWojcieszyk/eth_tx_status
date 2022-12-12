defmodule EthTxStatusTest.Misc do
  @moduledoc """
  Set of helper functions for tests
  """

  @spec int_to_ether_hex(integer()) :: binary()
  def random_tx_hash(length \\ 64) do
    chars = Enum.concat([?0..?9, ?A..?F, ?a..?f])

    "0x#{Stream.repeatedly(fn -> Enum.random(chars) end) |> Enum.take(length) |> List.to_string()}"
  end

  @spec int_to_ether_hex(integer()) :: binary()
  def int_to_ether_hex(integer) do
    "0x#{Integer.to_string(integer, 16)}"
  end
end
