defmodule EthTxStatus.HTTPLibImpl do
  @moduledoc """
  Implementation of the HTTPLib behaviour
  """

  @behaviour EthTxStatus.HTTPLibBehaviour

  @impl EthTxStatus.HTTPLibBehaviour
  def get(url) do
    # These "start" functions are here for simplicity and transparency
    # (they will return "already started" message for second and next calls) but they
    # can be also moved to a part of code which is run only once on server start.
    :inets.start()
    :ssl.start()

    :httpc.request(:get, {url, []}, [], [])
  end
end
