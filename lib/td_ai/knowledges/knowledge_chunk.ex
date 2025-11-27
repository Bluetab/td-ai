defmodule TdAi.Knowledges.KnowledgeChunk do
  @moduledoc """
  Knowledge chunk
  """

  @derive {Jason.Encoder,
           only: [:id, :chunk_id, :embedding, :filename, :md5, :format, :page, :text]}
  defstruct [:id, :chunk_id, :embedding, :filename, :md5, :format, :page, :text]

  def transform(chunk) do
    chunk
    |> Map.to_list()
    |> Enum.into(%{}, fn {k, v} -> {String.to_atom(k), v} end)
    |> then(&struct(__MODULE__, &1))
  end
end
