Mox.defmock(EthTxStatus.HTTPLibMock, for: EthTxStatus.HTTPLibBehaviour)
Mox.defmock(EthTxStatus.HTTPClientMock, for: EthTxStatus.HTTPClientBehaviour)

Application.put_env(:eth_tx_status, :http_lib, EthTxStatus.HTTPLibMock)
Application.put_env(:eth_tx_status, :http_client, EthTxStatus.HTTPClientMock)

ExUnit.start()
