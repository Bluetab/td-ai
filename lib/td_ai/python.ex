defmodule TdAi.Python do
  alias TdAi.Indices

  def load_collection(params) do
    config = Application.get_env(:td_ai, :python)

    path = [:code.priv_dir(:td_ai), "scripts"] |> Path.join()
    {:ok, pid} = :python.start([{:python_path, to_charlist(path)}, {:python, 'python3'}])
    :python.call(pid, :load_collection, :load, [params, config])
  end

  def predict(%{"index_id" => index_id} = params) do
    index = Indices.get_index!(index_id)
    params = Map.merge(index, params)

    config = Application.get_env(:td_ai, :python)

    path = [:code.priv_dir(:td_ai), "scripts"] |> Path.join()
    {:ok, pid} = :python.start([{:python_path, to_charlist(path)}, {:python, 'python3'}])

    :python.call(pid, :predictor, :predict, [params, config])
  end
end
