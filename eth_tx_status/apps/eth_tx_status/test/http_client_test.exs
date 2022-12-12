defmodule EthTxStatus.HTTPClientTest do
  use ExUnit.Case, async: true

  import Mox

  alias EthTxStatus.{HTTPClientImpl, HTTPLibMock}

  @example_url "https://api.etherscan.io/api?action=eth_getTransactionByHash"

  setup :verify_on_exit!

  describe "get/1" do
    test "maps successful response" do
      expect(HTTPLibMock, :get, fn _url ->
        {:ok,
         {{'HTTP/1.1', 200, 'OK'},
          [
            {'cache-control', 'private'},
            {'connection', 'keep-alive'}
          ], '{"jsonrpc":"2.0","id":1,"result":{"blockNumber":"0xcf2420"}}\n'}}
      end)

      assert HTTPClientImpl.get(@example_url) ==
               {:ok, %{"result" => %{"blockNumber" => "0xcf2420"}, "id" => 1, "jsonrpc" => "2.0"}}
    end

    test "maps error response" do
      expect(HTTPLibMock, :get, fn _url ->
        {:error, {:failure, :inets}}
      end)

      assert HTTPClientImpl.get(@example_url) == {:error, :failure}
    end
  end
end
