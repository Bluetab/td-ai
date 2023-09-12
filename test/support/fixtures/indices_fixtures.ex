defmodule TdAi.IndicesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TdAi.Indices` context.
  """

  @doc """
  Generate a index.
  """
  def index_fixture(attrs \\ %{}) do
    {:ok, index} =
      attrs
      |> Enum.into(%{
        collection_name: "some collection_name",
        embedding: "some embedding",
        mapping: ["option1", "option2"],
        index_type: "some index_type",
        metric_type: "some metric_type"
      })
      |> TdAi.Indices.create_index()

    index
  end
end
