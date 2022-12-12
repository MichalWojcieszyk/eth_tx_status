defmodule EthTxStatus.EtherscanApiWrapper do
  @moduledoc """
  Module responsible for preparing requests and calling Etherscan API via HTTPClient
  """

  @api_key System.get_env("ETHERSCAN_API_KEY")

  @spec validate_tx_hash_format(binary()) ::
          {:ok, :valid_tx_hash_format} | {:error, :invalid_tx_hash_format}
  def validate_tx_hash_format(hash) do
    if String.match?(hash, ~r/^0x([A-Fa-f0-9]{64})$/) do
      {:ok, :valid_tx_hash_format}
    else
      {:error, :invalid_tx_hash_format}
    end
  end

  @spec check_transaction_confirmation(binary()) ::
          {:ok, :confirmed | :pending | :awaiting}
          | {:error,
             :transaction_not_found
             | :request_error
             | :transaction_block_number_not_found
             | :current_block_number_not_found
             | :wrong_block_values
             | :api_limit_reached
             | :invalid_api_key
             | :missing_api_key}
  def check_transaction_confirmation(hash) do
    with {:ok, transaction_block_number} when transaction_block_number != :awaiting <-
           get_transaction_block_number(hash),
         {:ok, current_block_number} <- get_current_block_number() do
      do_check_transaction_confirmation(transaction_block_number, current_block_number)
    end
  end

  defp get_transaction_block_number(hash) do
    url = transaction_by_hash_url(hash)

    case http_client_impl().get(url) do
      {:ok, %{"result" => %{"blockNumber" => nil}}} ->
        {:ok, :awaiting}

      {:ok, %{"result" => %{"blockNumber" => block_number}}} ->
        {:ok, hex_block_number_to_int(block_number)}

      {:ok, %{"result" => nil}} ->
        {:error, :transaction_not_found}

      {:ok, %{"result" => "Invalid API Key"}} ->
        {:error, :invalid_api_key}

      {:ok, %{"message" => "NOTOK-Missing/Invalid API Key, rate limit of 1/5sec applied"}} ->
        {:error, :missing_api_key}

      {:ok,
       %{
         "message" => "NOTOK",
         "result" => "Max rate limit reached, please use API Key for higher rate limit"
       }} ->
        {:error, :api_limit_reached}

      {:error, _} ->
        {:error, :request_error}

      _error ->
        {:error, :transaction_block_number_not_found}
    end
  end

  defp get_current_block_number do
    url = get_current_block_number_url()

    case http_client_impl().get(url) do
      {:ok, %{"result" => "Invalid API Key"}} ->
        {:error, :invalid_api_key}

      {:ok,
       %{
         "message" => "NOTOK",
         "result" => "Max rate limit reached, please use API Key for higher rate limit"
       }} ->
        {:error, :api_limit_reached}

      {:ok, %{"result" => block_number}} ->
        {:ok, hex_block_number_to_int(block_number)}

      {:error, _} ->
        {:error, :request_error}

      {:ok, %{"message" => "NOTOK-Missing/Invalid API Key, rate limit of 1/5sec applied"}} ->
        {:error, :missing_api_key}

      _error ->
        {:error, :current_block_number_not_found}
    end
  end

  defp do_check_transaction_confirmation(transaction_block_number, current_block_number)
       when current_block_number - transaction_block_number >= 2 do
    {:ok, :confirmed}
  end

  defp do_check_transaction_confirmation(transaction_block_number, current_block_number)
       when current_block_number < transaction_block_number do
    {:error, :wrong_block_values}
  end

  defp do_check_transaction_confirmation(_transaction_block_number, _current_block_number) do
    {:ok, :pending}
  end

  defp transaction_by_hash_url(hash) do
    "https://api.etherscan.io/api?module=proxy&action=eth_getTransactionByHash&txhash=#{hash}&apikey=#{@api_key}"
  end

  defp get_current_block_number_url do
    "https://api.etherscan.io/api?module=proxy&action=eth_blockNumber&apikey=#{@api_key}"
  end

  defp hex_block_number_to_int(hex_block_number) when is_binary(hex_block_number) do
    {int_block_number, ""} = hex_block_number |> String.trim_leading("0x") |> Integer.parse(16)

    int_block_number
  end

  defp http_client_impl do
    Application.get_env(:eth_tx_status, :http_client, EthTxStatus.HTTPClientImpl)
  end
end
