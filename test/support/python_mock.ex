defmodule TdAi.PythonMock do
  def load_collection(_params) do
    ~c"ok"
  end

  def predict(_params) do
    [
      %{
        id: 1,
        distance: 10
      }
    ]
  end
end
