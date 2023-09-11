defmodule TdAiWeb.PredictionJSON do
  alias TdAi.Predictions.Prediction

  @doc """
  Renders a list of predictions.
  """
  def index(%{predictions: predictions}) do
    %{data: for(prediction <- predictions, do: data(prediction))}
  end

  @doc """
  Renders a single prediction.
  """
  def show(%{prediction: prediction}) do
    %{data: data(prediction)}
  end

  defp data(%Prediction{} = prediction) do
    %{
      id: prediction.id,
      mapping: prediction.mapping,
      result: prediction.result,
      data_structure_id: prediction.data_structure_id
    }
  end
end
