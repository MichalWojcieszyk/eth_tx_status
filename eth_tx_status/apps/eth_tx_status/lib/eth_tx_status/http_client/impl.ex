defmodule EthTxStatus.HTTPClientImpl do
  @moduledoc """
  Implementation of the HTTPClient behaviour
  """

  # There are two separate behaviours for HTTPClient and HTTPLibrary to allow easily
  # switching to other HTTP library when necessary and to allow testing request response mapping code.
  # It should be also fine to simplify it and use only one behaviour.
  @behaviour EthTxStatus.HTTPClientBehaviour

  @impl EthTxStatus.HTTPClientBehaviour
  def get(url) do
    case http_lib_impl().get(url) do
      {:ok, {{_, 200, _}, _, response}} -> {:ok, Jason.decode!(response)}
      {:error, {reason, _}} -> {:error, reason}
    end
  end

  defp http_lib_impl do
    Application.get_env(:eth_tx_status, :http_lib, EthTxStatus.HTTPLibImpl)
  end
end
