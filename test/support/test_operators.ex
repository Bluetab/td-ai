defmodule TdAi.TestOperators do
  @moduledoc """
  Equality operators for tests
  """

  alias TdAi.Completion.Prompt
  alias TdAi.Completion.Suggestion

  def a <~> b, do: approximately_equal(a, b)
  def a ||| b, do: approximately_equal(sorted(a), sorted(b))

  ## Sort by id if present
  defp sorted([%{id: _} | _] = list) do
    Enum.sort_by(list, & &1.id)
  end

  defp sorted([%{"id" => _} | _] = list) do
    Enum.sort_by(list, &Map.get(&1, "id"))
  end

  defp sorted(list), do: Enum.sort(list)

  ## Equality test for data structures without comparing Ecto associations.
  defp approximately_equal(%Prompt{} = a, %Prompt{} = b) do
    drop_fields = [:resource_mapping]

    Map.drop(a, drop_fields) == Map.drop(b, drop_fields)
  end

  ## Equality test for data structures without comparing Ecto associations.
  defp approximately_equal(%Suggestion{} = a, %Suggestion{} = b) do
    drop_fields = [:prompt, :resource_mapping]

    Map.drop(a, drop_fields) == Map.drop(b, drop_fields)
  end

  defp approximately_equal([h | t], [h2 | t2]) do
    approximately_equal(h, h2) && approximately_equal(t, t2)
  end

  defp approximately_equal(%{"id" => id1}, %{"id" => id2}), do: id1 == id2

  defp approximately_equal(a, b), do: a == b
end
