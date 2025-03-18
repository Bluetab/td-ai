defmodule TdAi.ProviderClients.InvalidProvider do
  @moduledoc """
  Provider implementation for OpenAi
  """

  @behaviour TdAi.ProviderClient

  @impl true
  def chat_completion(_, _) do
    {:error, :invalid_provider}
  end
end
