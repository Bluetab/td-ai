defmodule TdAiWeb.PredictionController do
  use TdAiWeb, :controller

  alias TdAi.Predictions
  alias TdAi.Predictions.Prediction

  action_fallback(TdAiWeb.FallbackController)

  def index(conn, _params) do
    predictions = Predictions.list_predictions()
    render(conn, :index, predictions: predictions)
  end

  def create(conn, %{"prediction" => prediction_params}) do
    IO.inspect(prediction_params, label: "prediction_params")

    %{
      "index_id" => index_id,
      "mapping" => mapping,
      "data_structure_id" => data_structure_id
    } = prediction_params

    with [_ | _] = result <- TdAi.Python.predict(index_id, mapping, data_structure_id),
         prediction_params <- Map.put(prediction_params, "result", result),
         {:ok, %Prediction{} = prediction} <-
           Predictions.create_prediction(prediction_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/predictions/#{prediction}")
      |> render(:show, prediction: prediction)
    end
  end

  def show(conn, %{"id" => id}) do
    prediction = Predictions.get_prediction!(id)
    render(conn, :show, prediction: prediction)
  end

  def update(conn, %{"id" => id, "prediction" => prediction_params}) do
    prediction = Predictions.get_prediction!(id)

    with {:ok, %Prediction{} = prediction} <-
           Predictions.update_prediction(prediction, prediction_params) do
      render(conn, :show, prediction: prediction)
    end
  end

  def delete(conn, %{"id" => id}) do
    prediction = Predictions.get_prediction!(id)

    with {:ok, %Prediction{}} <- Predictions.delete_prediction(prediction) do
      send_resp(conn, :no_content, "")
    end
  end
end
