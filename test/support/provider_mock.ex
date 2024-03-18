defmodule TdAi.ProviderClients.MockImpl do
  @moduledoc """
  Helper functions for Provider Mock
  """

  alias TdAi.Completion.Messages

  def chat_completion(provider_properties, messages) do
    properties = Map.from_struct(provider_properties)

    response =
      %{
        "provider_properties" => properties,
        "messages" => Messages.json(messages)
      }
      |> Jason.encode!()

    {:ok, response}
  end
end
