defmodule EthTxStatus do
  @moduledoc """
  EthTxStatus is a main module of the logic side of the application, serving functions for view layers
  """

  alias EthTxStatus.EtherscanApiWrapper

  @spec transaction_status(binary()) ::
          {:ok, :confirmed | :pending | :awaiting}
          | {:error,
             :invalid_tx_hash_format
             | :transaction_not_found
             | :request_error
             | :transaction_block_number_not_found
             | :current_block_number_not_found
             | :wrong_block_values
             | :api_limit_reached
             | :invalid_api_key
             | :missing_api_key}

  def transaction_status(hash) do
    with {:ok, :valid_tx_hash_format} <- EtherscanApiWrapper.validate_tx_hash_format(hash) do
      EtherscanApiWrapper.check_transaction_confirmation(hash)
    end
  end
end
