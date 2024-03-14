defmodule TdAiWeb.ProviderPropertiesJSON do
  alias TdAi.Completion.Provider
  alias TdAi.Completion.ProviderProperties
  alias TdAiWeb.ProviderPropertiesMockJSON

  def embed_one(%Provider{
        properties: %ProviderProperties{} = properties,
        type: type
      }),
      do: data(type, properties)

  def embed_one(_), do: nil

  defp data("mock", %ProviderProperties{} = properties),
    do: ProviderPropertiesMockJSON.embed_one(properties)

  defp data(type, %ProviderProperties{} = props), do: ProviderProperties.json(props, type)
end

defmodule TdAiWeb.ProviderPropertiesMockJSON do
  alias TdAi.Completion.ProviderProperties
  alias TdAi.Completion.ProviderProperties.Mock

  def embed_one(%ProviderProperties{mock: %Mock{} = props}), do: data(props)
  def embed_one(_), do: nil

  defp data(%Mock{} = mock) do
    %{
      model: mock.model
    }
  end
end
