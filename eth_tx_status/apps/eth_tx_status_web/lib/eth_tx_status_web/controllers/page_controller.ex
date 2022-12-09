defmodule EthTxStatusWeb.PageController do
  use EthTxStatusWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
