defmodule TdAiWeb.PromptJSON do
  alias TdAi.Completion.Prompt

  alias TdAiWeb.ProviderJSON

  @doc """
  Renders a list of prompts.
  """
  def index(%{prompts: prompts}) do
    %{data: for(prompt <- prompts, do: data(prompt))}
  end

  @doc """
  Renders a single prompt.
  """
  def show(%{prompt: prompt}) do
    %{data: data(prompt)}
  end

  defp data(%Prompt{} = prompt) do
    %{
      id: prompt.id,
      name: prompt.name,
      resource_type: prompt.resource_type,
      language: prompt.language,
      system_prompt: prompt.system_prompt,
      user_prompt_template: prompt.user_prompt_template,
      active: prompt.active,
      provider_id: prompt.provider_id,
      provider: ProviderJSON.embed(prompt.provider)
    }
  end
end
