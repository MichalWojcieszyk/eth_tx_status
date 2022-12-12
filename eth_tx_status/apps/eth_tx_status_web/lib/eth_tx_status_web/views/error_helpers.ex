defmodule EthTxStatusWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  use Phoenix.HTML

  def tx_hash_status_to_text(:confirmed), do: "Transaction was confirmed by at least two blocks."

  def tx_hash_status_to_text(:pending),
    do: "Transaction has already a block, but the confirmation is still pending."

  def tx_hash_status_to_text(:awaiting),
    do: "Transaction is waiting for being assigned to a block."

  def tx_hash_status_to_text(:invalid_tx_hash_format), do: "Transaction hash is in wrong format."
  def tx_hash_status_to_text(:transaction_not_found), do: "Transaction is not found."
  def tx_hash_status_to_text(:request_error), do: "Something wrong happened, please try again."

  def tx_hash_status_to_text(:transaction_block_number_not_found),
    do: "Transaction block number is not found. Please try again."

  def tx_hash_status_to_text(:current_block_number_not_found),
    do: "Current block number is not found. Please try again."

  def tx_hash_status_to_text(:wrong_block_values),
    do: "Block values seems to be incorrect for this hash. Please try again."

  def tx_hash_status_to_text(:api_limit_reached), do: "API limit reached. Please try again."

  def tx_hash_status_to_text(:invalid_api_key), do: "Etherscan API key is invalid."
  def tx_hash_status_to_text(:missing_api_key), do: "Etherscan API key is missing."

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn error ->
      content_tag(:span, translate_error(error),
        class: "invalid-feedback",
        phx_feedback_for: input_name(form, field)
      )
    end)
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext("errors", "is invalid")
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(EthTxStatusWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(EthTxStatusWeb.Gettext, "errors", msg, opts)
    end
  end
end
