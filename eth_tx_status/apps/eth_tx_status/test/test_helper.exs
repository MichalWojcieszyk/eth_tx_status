Mox.defmock(EthTxStatus.HTTPLibMock, for: EthTxStatus.HTTPLibBehaviour)

Application.put_env(:eth_tx_status, :http_lib, EthTxStatus.HTTPLibMock)

ExUnit.start()
