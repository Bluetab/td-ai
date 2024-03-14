defmodule TdAiWeb.ProviderJSON do
  alias TdAi.Completion.Provider

  alias TdAiWeb.ProviderPropertiesJSON

  @doc """
  Renders a list of providers.
  """
  def index(%{providers: providers}) do
    %{data: for(provider <- providers, do: data(provider))}
  end

  @doc """
  Renders a single provider.
  """
  def show(%{provider: provider}) do
    %{data: data(provider)}
  end

  def chat_completion(%{data: data}), do: data

  def embed(%Provider{} = provider), do: data(provider)
  def embed(_), do: nil

  defp data(%Provider{} = provider) do
    %{
      id: provider.id,
      name: provider.name,
      type: provider.type,
      properties: ProviderPropertiesJSON.embed_one(provider)
    }
  end
end
