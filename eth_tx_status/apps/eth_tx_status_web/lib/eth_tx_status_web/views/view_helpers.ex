defmodule EthTxStatusWeb.ViewHelpers do
  @moduledoc """
  Helpers functions for views.
  """

  def empty?(value) when is_binary(value) do
    value |> String.trim() |> String.length() == 0
  end

  def empty?(value) when is_atom(value) do
    false
  end
end
