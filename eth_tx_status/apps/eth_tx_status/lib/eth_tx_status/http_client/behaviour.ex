defmodule EthTxStatus.HTTPClientBehaviour do
  @moduledoc """
  Behaviour definition for the HTTPClient
  """

  @type url :: binary
  @type successful_response :: map
  @type error_response :: atom

  @callback get(url) :: {:ok, successful_response} | {:error, error_response}
end
