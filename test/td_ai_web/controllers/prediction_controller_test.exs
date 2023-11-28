defmodule TdAiWeb.PredictionControllerTest do
  use TdAiWeb.ConnCase

  alias TdAi.Predictions.Prediction

  @create_attrs %{
    result: [],
    mapping: ["option1", "option2"],
    data_structure_id: 42
  }
  @update_attrs %{
    result: [],
    mapping: ["option1"],
    data_structure_id: 43
  }
  @invalid_attrs %{result: nil, mapping: nil, data_structure_id: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all predictions", %{conn: conn} do
      conn = get(conn, ~p"/api/predictions")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create prediction" do
    test "renders prediction when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/predictions", prediction: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/predictions/#{id}")

      assert %{
               "id" => ^id,
               "data_structure_id" => 42,
               "mapping" => ["option1", "option2"],
               "result" => [%{"distance" => 10, "id" => 1}]
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/predictions", prediction: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update prediction" do
    setup [:create_prediction]

    test "renders prediction when data is valid", %{
      conn: conn,
      prediction: %Prediction{id: id} = prediction
    } do
      conn = put(conn, ~p"/api/predictions/#{prediction}", prediction: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/predictions/#{id}")

      assert %{
               "id" => ^id,
               "data_structure_id" => 43,
               "mapping" => ["option1"],
               "result" => []
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, prediction: prediction} do
      conn = put(conn, ~p"/api/predictions/#{prediction}", prediction: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete prediction" do
    setup [:create_prediction]

    test "deletes chosen prediction", %{conn: conn, prediction: prediction} do
      conn = delete(conn, ~p"/api/predictions/#{prediction}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/predictions/#{prediction}")
      end
    end
  end

  defp create_prediction(_) do
    prediction = insert(:prediction)
    %{prediction: prediction}
  end
end
