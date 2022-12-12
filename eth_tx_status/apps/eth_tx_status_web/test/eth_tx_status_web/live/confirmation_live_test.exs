defmodule EthTxStatusWeb.ConfirmationLiveTest do
  use EthTxStatusWeb.ConnCase

  import Phoenix.Component
  import Phoenix.LiveViewTest

  import Mox
  import EthTxStatusTest.Misc, only: [random_tx_hash: 0, random_tx_hash: 1, int_to_ether_hex: 1]

  alias EthTxStatusWeb.ConfirmationLive
  alias EthTxStatus.HTTPClientMock

  describe "render empty component" do
    setup do
      component =
        render_component(&ConfirmationLive.render/1, status: "", tx_hash: "", input: :input)

      {:ok, %{component: component}}
    end

    test "renders page header", %{component: component} do
      component =~ "<h1>Ethereum transaction status checker</h1>"
    end

    test "renders transaction hash label", %{component: component} do
      component =~ "<label for=\"input_transaction_hash\">Transaction hash</label>"
    end

    test "renders transaction hash input", %{component: component} do
      component =~
        "<input id=\"input_transaction_hash\" name=\"input[transaction_hash]\" type=\"text\">"
    end

    test "renders transaction hash confirm button", %{component: component} do
      component =~ "<button type=\"submit\">Check status</button>"
    end
  end

  describe "returns correct flash message, transaction hash and status when submitting transaction hash" do
    setup %{conn: conn} do
      {:ok, view, html} = live(conn, "/eth_tx_status")
      assert html =~ "<h1>Ethereum transaction status checker</h1>"

      {:ok, %{view: view}}
    end

    test "submits confirmed transaction hash", %{view: view} do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok, %{"result" => %{"blockNumber" => int_to_ether_hex(100)}}}
      end)
      |> expect(:get, fn _url -> {:ok, %{"result" => int_to_ether_hex(102)}} end)

      tx_hash = random_tx_hash()

      result_page = return_submit_page(view, tx_hash)

      assert_page_elements(%{
        page: result_page,
        flash_message: "Transaction was confirmed by at least two blocks.",
        tx_hash: tx_hash,
        status: "confirmed"
      })
    end

    test "submits pending transaction hash", %{view: view} do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok, %{"result" => %{"blockNumber" => int_to_ether_hex(100)}}}
      end)
      |> expect(:get, fn _url -> {:ok, %{"result" => int_to_ether_hex(101)}} end)

      tx_hash = random_tx_hash()

      result_page = return_submit_page(view, tx_hash)

      assert_page_elements(%{
        page: result_page,
        flash_message: "Transaction has already a block, but the confirmation is still pending.",
        tx_hash: tx_hash,
        status: "pending"
      })
    end

    test "submits awaiting transaction hash", %{view: view} do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok, %{"result" => %{"blockNumber" => nil}}}
      end)

      tx_hash = random_tx_hash()

      result_page = return_submit_page(view, tx_hash)

      assert_page_elements(%{
        page: result_page,
        flash_message: "Transaction is waiting for being assigned to a block.",
        tx_hash: tx_hash,
        status: "awaiting"
      })
    end

    test "submits wrong format transaction hash", %{view: view} do
      for tx_hash <- [
            random_tx_hash(63),
            random_tx_hash(65),
            66 |> random_tx_hash() |> String.trim_leading("0x")
          ] do
        result_page = return_submit_page(view, tx_hash)

        assert_page_elements(%{
          page: result_page,
          flash_message: "Transaction hash is in wrong format.",
          tx_hash: tx_hash,
          status: "invalid_tx_hash_format"
        })
      end
    end

    test "submits not existing transaction hash", %{view: view} do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok, %{"result" => nil}}
      end)

      tx_hash = random_tx_hash()

      result_page = return_submit_page(view, tx_hash)

      assert_page_elements(%{
        page: result_page,
        flash_message: "Transaction is not found.",
        tx_hash: tx_hash,
        status: "transaction_not_found"
      })
    end

    test "returns error when API does not work", %{view: view} do
      HTTPClientMock
      |> expect(:get, fn _url -> {:error, "Server not available"} end)

      tx_hash = random_tx_hash()

      result_page = return_submit_page(view, tx_hash)

      assert_page_elements(%{
        page: result_page,
        flash_message: "Something wrong happened, please try again.",
        tx_hash: tx_hash,
        status: "request_error"
      })
    end

    test "returns error when API limit was reached", %{view: view} do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok,
         %{
           "status" => "0",
           "message" => "NOTOK",
           "result" => "Max rate limit reached, please use API Key for higher rate limit"
         }}
      end)

      tx_hash = random_tx_hash()

      result_page = return_submit_page(view, tx_hash)

      assert_page_elements(%{
        page: result_page,
        flash_message: "API limit reached. Please try again.",
        tx_hash: tx_hash,
        status: "api_limit_reached"
      })
    end

    test "submits while using invalid api key", %{view: view} do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok, %{"result" => "Invalid API Key"}}
      end)

      tx_hash = random_tx_hash()

      result_page = return_submit_page(view, tx_hash)

      assert_page_elements(%{
        page: result_page,
        flash_message: "Etherscan API key is invalid.",
        tx_hash: tx_hash,
        status: "invalid_api_key"
      })
    end

    test "submits while missing api key", %{view: view} do
      HTTPClientMock
      |> expect(:get, fn _url ->
        {:ok, %{"message" => "NOTOK-Missing/Invalid API Key, rate limit of 1/5sec applied"}}
      end)

      tx_hash = random_tx_hash()

      result_page = return_submit_page(view, tx_hash)

      assert_page_elements(%{
        page: result_page,
        flash_message: "Etherscan API key is missing",
        tx_hash: tx_hash,
        status: "missing_api_key"
      })
    end

    test "submits empty field", %{view: view} do
      result_page = return_submit_page(view, "")

      assert result_page =~ "Transaction hash is in wrong format."
      refute result_page =~ "Transaction hash:"
      assert result_page =~ "<div>Status:  invalid_tx_hash_format</div>"
    end
  end

  defp return_submit_page(view, tx_hash) do
    view
    |> element("form")
    |> render_submit(%{input: %{transaction_hash: tx_hash}})
  end

  defp assert_page_elements(%{
         page: page,
         flash_message: flash_message,
         tx_hash: tx_hash,
         status: status
       }) do
    assert page =~ flash_message
    assert page =~ "<div>Transaction hash:  #{tx_hash}</div>"
    assert page =~ "<div>Status:  #{status}</div>"
  end
end
