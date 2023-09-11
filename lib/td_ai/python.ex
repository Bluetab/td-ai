defmodule TdAi.Python do
  alias TdAi.Indices

  def load_collection(collection_name, embedding, mapping) do
    config = Application.get_env(:td_ai, :python)

    path = [:code.priv_dir(:td_ai), "scripts"] |> Path.join()
    {:ok, pid} = :python.start([{:python_path, to_charlist(path)}, {:python, 'python3'}])
    :python.call(pid, :load_collection, :load, [collection_name, embedding, mapping, config])
  end

  def predict(index_id, mapping, data_structure_id) do
    %{
      collection_name: collection_name,
      embedding: embedding
    } = Indices.get_index!(index_id)

    config = Application.get_env(:td_ai, :python)

    path = [:code.priv_dir(:td_ai), "scripts"] |> Path.join()
    {:ok, pid} = :python.start([{:python_path, to_charlist(path)}, {:python, 'python3'}])

    :python.call(pid, :predictor, :predict, [
      collection_name,
      embedding,
      mapping,
      data_structure_id,
      config
    ])
  end
end
