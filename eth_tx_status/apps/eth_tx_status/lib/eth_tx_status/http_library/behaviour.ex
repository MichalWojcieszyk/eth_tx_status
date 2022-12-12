defmodule EthTxStatus.HTTPLibBehaviour do
  @moduledoc """
  Behaviour definition for the HTTPLib
  """

  @type url :: binary
  @type status :: tuple
  @type headers :: list
  @type successful_response :: list
  @type error_response :: term

  @callback get(url) :: {:ok, {status, headers, successful_response}} | {:error, error_response}
end
