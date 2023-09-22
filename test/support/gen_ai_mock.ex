defmodule TdAi.GenAiMock do
  @moduledoc """
  Mock for TdAi.GenAi Module
  """

  def load_collection(_params) do
    :ok
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
