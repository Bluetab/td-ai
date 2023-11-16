defmodule TdAi.PredictionsTest do
  use TdAi.DataCase

  alias TdAi.Predictions

  describe "predictions" do
    alias TdAi.Predictions.Prediction

    @invalid_attrs %{result: nil, mapping: nil, data_structure_id: nil}

    test "list_predictions/0 returns all predictions" do
      prediction = insert(:prediction)
      assert Predictions.list_predictions() == [prediction]
    end

    test "get_prediction!/1 returns the prediction with given id" do
      prediction = insert(:prediction)
      assert Predictions.get_prediction!(prediction.id) == prediction
    end

    test "create_prediction/1 with valid data creates a prediction" do
      valid_attrs = %{result: [], mapping: ["option1", "option2"], data_structure_id: 42}

      assert {:ok, %Prediction{} = prediction} = Predictions.create_prediction(valid_attrs)
      assert prediction.result == []
      assert prediction.mapping == ["option1", "option2"]
      assert prediction.data_structure_id == 42
    end

    test "create_prediction/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Predictions.create_prediction(@invalid_attrs)
    end

    test "update_prediction/2 with valid data updates the prediction" do
      prediction = insert(:prediction)
      update_attrs = %{result: [], mapping: ["option1"], data_structure_id: 43}

      assert {:ok, %Prediction{} = prediction} =
               Predictions.update_prediction(prediction, update_attrs)

      assert prediction.result == []
      assert prediction.mapping == ["option1"]
      assert prediction.data_structure_id == 43
    end

    test "update_prediction/2 with invalid data returns error changeset" do
      prediction = insert(:prediction)

      assert {:error, %Ecto.Changeset{}} =
               Predictions.update_prediction(prediction, @invalid_attrs)

      assert prediction == Predictions.get_prediction!(prediction.id)
    end

    test "delete_prediction/1 deletes the prediction" do
      prediction = insert(:prediction)
      assert {:ok, %Prediction{}} = Predictions.delete_prediction(prediction)
      assert_raise Ecto.NoResultsError, fn -> Predictions.get_prediction!(prediction.id) end
    end

    test "change_prediction/1 returns a prediction changeset" do
      prediction = insert(:prediction)
      assert %Ecto.Changeset{} = Predictions.change_prediction(prediction)
    end
  end
end
