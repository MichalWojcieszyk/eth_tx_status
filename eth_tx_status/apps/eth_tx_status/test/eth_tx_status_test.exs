defmodule EthTxStatusTest do
  use ExUnit.Case, async: true

  import Mox
  import EthTxStatusTest.Misc, only: [random_tx_hash: 0, random_tx_hash: 1, int_to_ether_hex: 1]

  alias EthTxStatus.HTTPClientMock

  setup :verify_on_exit!

  describe "transaction_status/1" do
    test "returns successful status when there are at least two blocks confirmed for given transaction hash" do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok, %{"result" => %{"blockNumber" => int_to_ether_hex(100)}}}
      end)
      |> expect(:get, fn _url -> {:ok, %{"result" => int_to_ether_hex(102)}} end)

      assert EthTxStatus.transaction_status(random_tx_hash()) == {:ok, :confirmed}
    end

    test "returns pending status when there are less then two blocks confirmation for given transaction hash" do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok, %{"result" => %{"blockNumber" => int_to_ether_hex(100)}}}
      end)
      |> expect(:get, fn _url -> {:ok, %{"result" => int_to_ether_hex(101)}} end)

      assert EthTxStatus.transaction_status(random_tx_hash()) == {:ok, :pending}
    end

    test "returns awaiting status when transaction exists but doesn't have block assigned yet" do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok, %{"result" => %{"blockNumber" => nil}}}
      end)

      assert EthTxStatus.transaction_status(random_tx_hash()) == {:ok, :awaiting}
    end

    test "returns error when hash has incorrect format" do
      for tx_hash <- [
            random_tx_hash(63),
            random_tx_hash(65),
            66 |> random_tx_hash() |> String.trim_leading("0x")
          ] do
        assert EthTxStatus.transaction_status(tx_hash) == {:error, :invalid_tx_hash_format}
      end
    end

    test "returns error when transaction is not found" do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok, %{"result" => nil}}
      end)

      assert EthTxStatus.transaction_status(random_tx_hash()) ==
               {:error, :transaction_not_found}
    end

    test "returns error when request fails" do
      HTTPClientMock
      |> expect(:get, fn _url -> {:error, "Server not available"} end)

      assert EthTxStatus.transaction_status(random_tx_hash()) ==
               {:error, :request_error}
    end

    test "returns error when api key is invalid" do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok, %{"result" => "Invalid API Key"}}
      end)

      assert EthTxStatus.transaction_status(random_tx_hash()) ==
               {:error, :invalid_api_key}
    end

    test "returns error when api key is missing" do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok, %{"message" => "NOTOK-Missing/Invalid API Key, rate limit of 1/5sec applied"}}
      end)

      assert EthTxStatus.transaction_status(random_tx_hash()) ==
               {:error, :missing_api_key}
    end
  end
end
