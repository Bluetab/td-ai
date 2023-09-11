defmodule TdAi.Python do
  def run(collection_name, embedding, mapping) do
    # collection_name = "test1"
    # embedding = "paraphrase-MiniLM-L6-v2"
    # mapping = ["description"]

    config = Application.get_env(:td_ai, :python)

    IO.inspect({collection_name, embedding, mapping, config}, label: "PARAMETROS PYTHON")

    path = [:code.priv_dir(:td_ai), "scripts"] |> Path.join()
    {:ok, pid} = :python.start([{:python_path, to_charlist(path)}, {:python, 'python3'}])
    :python.call(pid, :load_collection, :load, [collection_name, embedding, mapping, config])
  end
end
