defmodule EthTxStatusWeb.ConfirmationLive do
  use EthTxStatusWeb, :live_view

  import EthTxStatusWeb.ViewHelpers, only: [empty?: 1]

  def mount(_params, _session, socket) do
    {:ok, assign(socket, status: "", tx_hash: "", input: :input)}
  end

  def render(assigns) do
    ~H"""
    <h1>Ethereum transaction status checker</h1>

    <.form let={f} for={@input} phx-submit="check">
      <%= label f, :transaction_hash %>
      <%= text_input f, :transaction_hash %>
      <%= error_tag f, :transaction_hash %>

      <%= submit "Check status" %>
    </.form>

    <div><%= if not empty?(@tx_hash), do: "Transaction hash: "%> <%= @tx_hash %></div>
    <div><%= if not empty?(@status), do: "Status: "%> <%= @status %></div>
    """
  end

  def handle_event("check", %{"input" => %{"transaction_hash" => tx_hash}}, socket) do
    case EthTxStatus.transaction_status(tx_hash) do
      {:ok, response} ->
        {:noreply,
         socket
         |> put_flash(:error, "")
         |> put_flash(:info, tx_hash_status_to_text(response))
         |> assign(status: response, tx_hash: tx_hash)}

      {:error, response} ->
        {:noreply,
         socket
         |> put_flash(:info, "")
         |> put_flash(:error, tx_hash_status_to_text(response))
         |> assign(status: response, tx_hash: tx_hash)}
    end
  end
end
