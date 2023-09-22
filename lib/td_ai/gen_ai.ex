defmodule TdAi.GenAi do
  @moduledoc """
    Module for GenAi actions
  """

  use GenServer

  alias TdAi.Indices
  alias TdAi.Indices.Index
  alias TdAi.Milvus
  alias TdAi.NxServings
  alias TdCluster.Cluster.TdBg
  alias TdCluster.Cluster.TdDd

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def load_collection(index), do: GenServer.cast(__MODULE__, {:load_collection, index})

  def predict(%{
        "index_id" => index_id,
        "data_structure_id" => data_structure_id,
        "mapping" => mapping
      }) do
    %{
      embedding: model_name,
      collection_name: collection_name
    } = Indices.get_index!(index_id)

    model = NxServings.new_model(model_name)

    {:ok, data_structure_version} = TdDd.get_latest_structure_version(data_structure_id)

    mapping = Enum.map(mapping, &String.to_existing_atom/1)

    text =
      data_structure_version
      |> Map.take(mapping)
      |> Jason.encode!()

    [vector] = NxServings.calculate_vectors(model, [text])

    {:ok, data} = Milvus.search_vectors(collection_name, vector)
    data
  end

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:load_collection, index}, _) do
    %Index{
      collection_name: collection_name,
      embedding: model_name,
      mapping: mapping
    } = index

    try do
      Indices.update_index(index, %{status: "Loading Model"})

      model = NxServings.new_model(model_name)
      dimension = NxServings.model_vector_size(model)

      index_params = Map.take(index, [:index_type, :index_params, :metric_type])
      {:ok, _} = Milvus.create_collection(collection_name, dimension, index_params)

      Indices.update_index(index, %{status: "Parsing Concepts"})
      {:ok, concepts} = TdBg.list_business_concept_versions([:published])

      mapping = Enum.map(mapping, &String.to_existing_atom/1)

      concepts = Enum.take(concepts, 10)

      texts =
        Enum.map(
          concepts,
          &(&1
            |> Map.take(mapping)
            |> Jason.encode!())
        )

      vectors = NxServings.calculate_vectors(model, texts)

      external_ids = Enum.map(concepts, & &1.id)
      size = Enum.count(external_ids)

      Milvus.insert_vectors(collection_name, external_ids, vectors, size)

      Indices.update_index(index, %{status: "Complete"})

      {:noreply, nil}
    rescue
      error ->
        Indices.update_index(index, %{status: "Error: #{inspect(error)}"})
        reraise error, __STACKTRACE__
    end
  end
end
