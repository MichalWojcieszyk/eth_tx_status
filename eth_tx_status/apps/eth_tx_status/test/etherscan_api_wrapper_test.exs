defmodule EthTxStatus.EtherscanApiWrapperTest do
  use ExUnit.Case, async: true

  import Mox
  import EthTxStatusTest.Misc, only: [random_tx_hash: 0, random_tx_hash: 1, int_to_ether_hex: 1]

  alias EthTxStatus.{EtherscanApiWrapper, HTTPClientMock}

  setup :verify_on_exit!

  # Some of the tests have been written using property-based custom approach
  # with some range predefined. It gives some additional safety and works fine
  # with app this size, although when the app grows together with tests execution time,
  # testing only edge values should also be good enough here.
  describe "validate_tx_hash_format/1" do
    test "returns ok tuple when format is correct" do
      Enum.each(1..100, fn _ ->
        tx_hash = random_tx_hash()

        assert EtherscanApiWrapper.validate_tx_hash_format(tx_hash) ==
                 {:ok, :valid_tx_hash_format}
      end)
    end

    test "returns error tuple when hash is too short" do
      for length <- 0..63 do
        tx_hash = random_tx_hash(length)

        assert EtherscanApiWrapper.validate_tx_hash_format(tx_hash) ==
                 {:error, :invalid_tx_hash_format}
      end
    end

    test "returns error tuple when hash is too long" do
      for length <- 65..130 do
        tx_hash = random_tx_hash(length)

        assert EtherscanApiWrapper.validate_tx_hash_format(tx_hash) ==
                 {:error, :invalid_tx_hash_format}
      end
    end

    test "returns error tuple when hash has wrong beginning" do
      for tx_hash <- [
            66 |> random_tx_hash() |> String.trim_leading("0x"),
            65 |> random_tx_hash() |> String.trim_leading("0"),
            65 |> random_tx_hash() |> String.trim_leading("0x") |> String.pad_leading(1, "x")
          ] do
        assert EtherscanApiWrapper.validate_tx_hash_format(tx_hash) ==
                 {:error, :invalid_tx_hash_format}
      end
    end

    test "returns error tuple when hash contains not only integers and strings" do
      for special_character <- ["-", "_", "@", "$", ".", ","] do
        tx_hash = 63 |> random_tx_hash() |> String.pad_trailing(1, special_character)

        assert EtherscanApiWrapper.validate_tx_hash_format(tx_hash) ==
                 {:error, :invalid_tx_hash_format}
      end
    end
  end

  describe "check_transaction_confirmation/1" do
    test "returns confirmed status when transaction is confirmed by at least two blocks" do
      for current_block <- 102..200 do
        HTTPClientMock
        |> expect(:get, fn _url ->
          {:ok, %{"result" => %{"blockNumber" => int_to_ether_hex(100)}}}
        end)
        |> expect(:get, fn _url -> {:ok, %{"result" => int_to_ether_hex(current_block)}} end)

        assert EtherscanApiWrapper.check_transaction_confirmation(random_tx_hash()) ==
                 {:ok, :confirmed}
      end
    end

    test "returns confirmed status when transaction is confirmed by at least two blocks (multiple transaction block cases)" do
      for current_block <- 1000..10_000 do
        HTTPClientMock
        |> expect(:get, fn _url ->
          {:ok, %{"result" => %{"blockNumber" => int_to_ether_hex(current_block - 2)}}}
        end)
        |> expect(:get, fn _url -> {:ok, %{"result" => int_to_ether_hex(current_block)}} end)

        assert EtherscanApiWrapper.check_transaction_confirmation(random_tx_hash()) ==
                 {:ok, :confirmed}
      end
    end

    test "returns pending status when transaction is confirmed by less then two blocks" do
      for current_block <- [100, 101] do
        HTTPClientMock
        |> expect(:get, fn _url ->
          {:ok, %{"result" => %{"blockNumber" => int_to_ether_hex(100)}}}
        end)
        |> expect(:get, fn _url -> {:ok, %{"result" => int_to_ether_hex(current_block)}} end)

        assert EtherscanApiWrapper.check_transaction_confirmation(random_tx_hash()) ==
                 {:ok, :pending}
      end
    end

    test "returns awaiting status when transaction exists but doesn't have block yet" do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok, %{"result" => %{"blockNumber" => nil}}}
      end)

      assert EtherscanApiWrapper.check_transaction_confirmation(random_tx_hash()) ==
               {:ok, :awaiting}
    end

    test "returns wrong block values error when current block number is lower than transaction one" do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok, %{"result" => %{"blockNumber" => int_to_ether_hex(100)}}}
      end)
      |> expect(:get, fn _url -> {:ok, %{"result" => int_to_ether_hex(99)}} end)

      assert EtherscanApiWrapper.check_transaction_confirmation(random_tx_hash()) ==
               {:error, :wrong_block_values}
    end

    test "returns error when transaction is not found" do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok, %{"result" => nil}}
      end)

      assert EtherscanApiWrapper.check_transaction_confirmation(random_tx_hash()) ==
               {:error, :transaction_not_found}
    end

    test "returns transaction block number error when is not found" do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok, %{"result" => %{}}}
      end)

      assert EtherscanApiWrapper.check_transaction_confirmation(random_tx_hash()) ==
               {:error, :transaction_block_number_not_found}
    end

    test "returns current block number error when is not found" do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok, %{"result" => %{"blockNumber" => int_to_ether_hex(100)}}}
      end)
      |> expect(:get, fn _url -> {:ok, %{}} end)

      assert EtherscanApiWrapper.check_transaction_confirmation(random_tx_hash()) ==
               {:error, :current_block_number_not_found}
    end

    test "returns error when get transaction block request fails" do
      HTTPClientMock
      |> expect(:get, fn _url -> {:error, "Server not available"} end)

      assert EtherscanApiWrapper.check_transaction_confirmation(random_tx_hash()) ==
               {:error, :request_error}
    end

    test "returns error when get current block request fails" do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok, %{"result" => %{"blockNumber" => int_to_ether_hex(100)}}}
      end)
      |> expect(:get, fn _url -> {:error, "Server not available"} end)

      assert EtherscanApiWrapper.check_transaction_confirmation(random_tx_hash()) ==
               {:error, :request_error}
    end

    test "returns error when API limit was reached for get transaction block endpoint" do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok,
         %{
           "status" => "0",
           "message" => "NOTOK",
           "result" => "Max rate limit reached, please use API Key for higher rate limit"
         }}
      end)

      assert EtherscanApiWrapper.check_transaction_confirmation(random_tx_hash()) ==
               {:error, :api_limit_reached}
    end

    test "returns error when API limit was reached for get current block endpoint" do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok, %{"result" => %{"blockNumber" => int_to_ether_hex(100)}}}
      end)
      |> expect(:get, fn _url ->
        {:ok,
         %{
           "status" => "0",
           "message" => "NOTOK",
           "result" => "Max rate limit reached, please use API Key for higher rate limit"
         }}
      end)

      assert EtherscanApiWrapper.check_transaction_confirmation(random_tx_hash()) ==
               {:error, :api_limit_reached}
    end

    test "returns error when api key is invalid for get transaction block request" do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok, %{"result" => "Invalid API Key"}}
      end)

      assert EtherscanApiWrapper.check_transaction_confirmation(random_tx_hash()) ==
               {:error, :invalid_api_key}
    end

    test "returns error when api key is invalid for get current block request" do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok, %{"result" => %{"blockNumber" => int_to_ether_hex(100)}}}
      end)
      |> expect(:get, fn _url ->
        {:ok, %{"result" => "Invalid API Key"}}
      end)

      assert EtherscanApiWrapper.check_transaction_confirmation(random_tx_hash()) ==
               {:error, :invalid_api_key}
    end

    test "returns error when api key is missing for get transaction block request" do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok, %{"message" => "NOTOK-Missing/Invalid API Key, rate limit of 1/5sec applied"}}
      end)

      assert EtherscanApiWrapper.check_transaction_confirmation(random_tx_hash()) ==
               {:error, :missing_api_key}
    end

    test "returns error when api key is missing for get current block request" do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok, %{"result" => %{"blockNumber" => int_to_ether_hex(100)}}}
      end)
      |> expect(:get, fn _url ->
        {:ok, %{"message" => "NOTOK-Missing/Invalid API Key, rate limit of 1/5sec applied"}}
      end)

      assert EtherscanApiWrapper.check_transaction_confirmation(random_tx_hash()) ==
               {:error, :missing_api_key}
    end
  end
end
