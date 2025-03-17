defmodule TdAiWeb.TranslationJSON do
  alias TdAi.Completion.Translation

  def index(%{translations: translations}) do
    %{data: for(translation <- translations, do: data(translation))}
  end

  def show(%{translation: translation}) do
    %{data: data(translation)}
  end

  def show_content(%{translation_content: translation_content}) do
    %{data: translation_content}
  end

  def availability_check(%{response: {status, reason}}) do
    %{
      data: %{
        status: status,
        reason: reason
      }
    }
  end

  defp data(%Translation{} = translation) do
    %{
      id: translation.id,
      resource_id: translation.resource_id,
      generated_prompt: translation.generated_prompt,
      response: translation.response,
      request_time: translation.request_time,
      requested_by: translation.requested_by,
      status: translation.status,
      prompt_id: translation.prompt_id
    }
  end
end
