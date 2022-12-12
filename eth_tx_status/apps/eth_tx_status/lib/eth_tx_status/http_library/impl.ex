defmodule EthTxStatus.HTTPLibImpl do
  @moduledoc """
  Implementation of the HTTPLib behaviour
  """

  @behaviour EthTxStatus.HTTPLibBehaviour

  @impl EthTxStatus.HTTPLibBehaviour
  def get(url) do
    :inets.start()
    :ssl.start()

    :httpc.request(:get, {url, []}, [], [])
  end
end
