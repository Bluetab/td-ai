defmodule TdAiWeb.SuggestionJSON do
  alias TdAi.Completion.Suggestion

  @doc """
  Renders a list of suggestions.
  """
  def index(%{suggestions: suggestions}) do
    %{data: for(suggestion <- suggestions, do: data(suggestion))}
  end

  @doc """
  Renders a single suggestion.
  """
  def show(%{suggestion: suggestion}) do
    %{data: data(suggestion)}
  end

  defp data(%Suggestion{} = suggestion) do
    %{
      id: suggestion.id,
      resource_id: suggestion.resource_id,
      generated_prompt: suggestion.generated_prompt,
      response: suggestion.response,
      request_time: suggestion.request_time,
      requested_by: suggestion.requested_by,
      prompt_id: suggestion.prompt_id
    }
  end
end
