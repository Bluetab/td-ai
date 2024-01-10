defmodule TdAiWeb.PredictionController do
  use TdAiWeb, :controller

  alias TdAi.Predictions
  alias TdAi.Predictions.Prediction

  action_fallback(TdAiWeb.FallbackController)

  def index(conn, _params) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Predictions, :index, claims) do
      predictions = Predictions.list_predictions()
      render(conn, :index, predictions: predictions)
    end
  end

  def create(conn, %{"prediction" => prediction_params}) do
    claims = conn.assigns[:current_resource]
    gen_ai = Application.get_env(:td_ai, :gen_ai_module)

    with :ok <- Bodyguard.permit(Predictions, :create, claims),
         result <- gen_ai.predict(prediction_params),
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
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Predictions, :show, claims) do
      prediction = Predictions.get_prediction!(id)
      render(conn, :show, prediction: prediction)
    end
  end

  def update(conn, %{"id" => id, "prediction" => prediction_params}) do
    claims = conn.assigns[:current_resource]
    prediction = Predictions.get_prediction!(id)

    with :ok <- Bodyguard.permit(Predictions, :update, claims),
         {:ok, %Prediction{} = prediction} <-
           Predictions.update_prediction(prediction, prediction_params) do
      render(conn, :show, prediction: prediction)
    end
  end

  def delete(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]
    prediction = Predictions.get_prediction!(id)

    with :ok <- Bodyguard.permit(Predictions, :delete, claims),
         {:ok, %Prediction{}} <- Predictions.delete_prediction(prediction) do
      send_resp(conn, :no_content, "")
    end
  end
end
