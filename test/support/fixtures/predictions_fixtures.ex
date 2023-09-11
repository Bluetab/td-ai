defmodule TdAi.PredictionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TdAi.Predictions` context.
  """

  @doc """
  Generate a prediction.
  """
  def prediction_fixture(attrs \\ %{}) do
    {:ok, prediction} =
      attrs
      |> Enum.into(%{
        result: [],
        mapping: ["option1", "option2"],
        data_structure_id: 42
      })
      |> TdAi.Predictions.create_prediction()

    prediction
  end
end
