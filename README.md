# Ethereum transaction status checker

### How the application works

User can input ETH transaction hash of (tx_hash) and as the result should be returned status of the transaction or error message when something was wrong.
Demo recording of the app can be found [here](https://www.loom.com/share/63ab9a7d4baf471a88b1a760455c3989).

##### Possible transaction statuses

- success
- pending
- awaiting

##### Possible error statuses

- invalid tx hash format
- transaction not found
- request error
- transaction block number not found
- current block number not found
- wrong block values
- api limit reached
- invalid api key
- missing api key

### Running it locally

1. Copy the GitHub repo.
2. Navigate in terminal to `/eth_tx_status/eth_tx_status` (project main) directory.
3. Make sure you have Elixir and Erlang installed. You can use [asdf ](https://asdf-vm.com/) to get latest versions. You can also add `/tool-versions` file. Versions used during development:

- elixir 1.14.2
- erlang 25.1.1

4. Run in terminal `export ETHERSCAN_API_KEY='YOUR_API_KEY'`.
5. To run code analysis tools and tests, run `mix dialyzer`, `mix credo` and `mix test`
6. Next run `mix phx.server`.
7. Open browser and enter http://localhost:4000/eth_tx_status

### How transaction status is checked

Application is using Etherscan API to check transaction confirmation. It performs two requests, first to check transaction block number and second to check current block number. When the current block number is at least two numbers higher then transaction block number, transaction is accepted as confirmed.

There are three possible scenarios here:

1. **Success**: when there are at least two block confirmations. To check this scenario, user can input one of the confirmed transactions hashes from [Etherscan page](https://etherscan.io/).
2. **Pending**: when transaction was added to Blockchain, but it's not yet confirmed by at least two blocks. These transactions can be found also on the [Etherscan page](https://etherscan.io/) in latest transactions (watch out to act fast and pick one that is not yet confirmed).
3. **Awaiting**: when transaction exists, but is waiting for being added to Blockchain. Examples to test this case can be found as waiting characters on [TxStreet page](https://txstreet.com/v/eth-btc).

### Technologies used

- **Elixir/Phoenix**: it was requested in the task, but it's also my stack of choice and they are good fit to be used for this case. Phoenix is lightweight enough framework, that it can be used also for one-endpoint, no-database apps without any flaws.
- **Phoenix LiveView**: works perfect in cases like this, when the frontend part is simple, we don't expect offline or pure internet connections. Adding JS and it's frameworks might be an overkill for the current scope of the app. Serving frontend with standard Phoenix controllers will also work fine here, but thanks to LiveView we have some nice websockets connections and easy way to extend frontend features.

### Concepts/libraries used

- **dialyzer/credo**: code analysis libraries. Also used **TypeSpec** for some static typing and functions documentation.
- **mox**: used for mocking external API requests in tests. My go-to way of mocking, based on behaviours/contracts.
- **httpc**: Erlang library used for performing API requests. It looks like HTTP libraries is the one of really few areas in Elixir, where there are no clear favourite in terms library to use, as there are many possibilities. Most often I use HTTPoison, which works fine for general use case, but here to avoid adding more dependecies while performing only one request, built-in Erlang library can be used. There are behaviour and mock for HTTPClient which make it possible to easily switch to other client in the future, when other solution will be needed.
- **Etherscan API**: this seems to be source of truth in terms of checking ETH transactions status. API is also free for simple usage. The documentation might be better, but it was enough to fulfill this task.

### Approaches

- **simplicity**: I tried to achieve the task in similar way as I will do it in my daily work. It means using correct tools and doing only the necessary parts, but keeping the quality high. Elixir with OTP ecosystem is a very powerful tool and it's possible to do a lot without additional libraries. Also app this size doesn't require any fancy architecture or conventions. It seems that couple layers of code, with extracted API part and HTTPClient is enough and makes the code readable and easily extendable.
- **tests first**: Tests are inseparable part of the code, so when possible, I try to use TDD or at least to write down possible test cases before starting with code. Also, the lower the layer, tests are more detailed and the more cases should be covered. I also added property-based-like tests with pure Elixir (they might be expensive, but for this use case seems to be fine) and included some randomness for validating `tx_hash`.
  There are two separate mocks with behaviours as I wanted to keep it easy to replace HTTPClient app, but the result might be also achieved mocking only the HTTP library and using one mock in total.
- **easy to review**: In general I try to achieve result fast and then refactor and improve code, but before I put pull request to review, I rebase its history, so it will be easy for reviewers to check it. Similarly in this case, code was rebased couple times and it can be reviewed commit-by-commit in logical order.
- **bottom up**: I started here with backend part. From the HTTPClient, then wrapper around API and finally business logic. Finally frontend part of the app to display the result.
- **backend focus**: Most of the "fun" and decisions to made were on backend, so this part got most of the attention. Frontend part is quite straight forward, although it serves its job well and the UX part should be logical for users. There is not a lot of styling, but I think it was not a point of this task.

### Possible next steps to extend the app (depends on project scope, user feedback etc.)

- adding "refresh" button to make a check without inputting the tx_hash again
- improving designs and adding more styling
- showing more details for the transaction than only status, similarly to Etherscan page
- having a list of recent inputs and making the calls async until the transaction is confirmed
- implementing more endpoints from Etherscan to allow users performing more actions
