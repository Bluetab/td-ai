defmodule TdAiWeb.ResourceMappingJSON do
  alias TdAi.Completion.ResourceMapping
  alias TdAiWeb.ResourceMappingFieldJSON

  @doc """
  Renders a list of resource_mappings.
  """
  def index(%{resource_mappings: resource_mappings}) do
    %{data: for(resource_mapping <- resource_mappings, do: data(resource_mapping))}
  end

  @doc """
  Renders a single resource_mapping.
  """
  def show(%{resource_mapping: resource_mapping}) do
    %{data: data(resource_mapping)}
  end

  defp data(%ResourceMapping{} = resource_mapping) do
    %{
      id: resource_mapping.id,
      name: resource_mapping.name,
      fields: ResourceMappingFieldJSON.embeds_many(resource_mapping)
    }
  end
end

defmodule TdAiWeb.ResourceMappingFieldJSON do
  alias TdAi.Completion.ResourceMapping.Field

  @doc """
  Renders a list of resource_mappings.
  """
  def embeds_many(%{fields: fields}), do: for(field <- fields, do: data(field))

  defp data(%Field{} = field) do
    %{
      source: field.source,
      target: field.target
    }
  end
end
