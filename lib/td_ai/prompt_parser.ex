defmodule TdAi.PromptParser do
  @moduledoc """
  Module for parsing Prompts
  """
  import TdCore.Utils.CollectionUtils, only: [stringify_keys: 1]

  alias TdAi.Completion.Prompt
  alias TdAi.Completion.ResourceMapping

  alias TdCluster.Cluster

  def parse(%ResourceMapping{fields: fields}, "data_structure", resource_id) do
    {:ok, structure} = Cluster.TdDd.get_latest_structure_version(resource_id)
    structure = stringify_keys(structure)

    Enum.reduce_while(fields, %{}, fn %{source: source, target: target}, acc ->
      value =
        source
        |> String.split(".")
        |> get_value(structure)

      target = String.split(target || source, ".")

      case put_value(acc, target, value) do
        :error ->
          {:halt, :error}

        result ->
          {:cont, result}
      end
    end)
  end

  def generate_user_prompt(%Prompt{user_prompt_template: user_prompt_template}, fields, resource) do
    user_prompt_template
    |> String.replace("{fields}", Jason.encode!(fields))
    |> String.replace("{resource}", Jason.encode!(resource))
  end

  defp put_value(_, _, :error), do: :error
  defp put_value(map, [key], value) when is_map(map), do: Map.put(map, key, value)

  defp put_value(map, [key | rest], value) when is_map(map) do
    nested =
      map
      |> Map.get(key, %{})
      |> put_value(rest, value)

    put_value(map, [key], nested)
  end

  defp put_value(_, _, _), do: :error

  defp get_value([], value), do: value

  defp get_value([key | rest], map) when is_map(map) do
    next_value = Map.get(map, key)
    get_value(rest, next_value)
  end

  defp get_value(_, _), do: nil
end
