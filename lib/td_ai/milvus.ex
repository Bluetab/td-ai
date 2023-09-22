defmodule TdAi.Milvus do
  @moduledoc """
    Server to handle requests to Milvus Database
  """
  use GenServer

  def start_link(_) do
    config = Application.get_env(:td_ai, :milvus)

    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  def list_collections, do: GenServer.call(__MODULE__, :list_collections)

  def create_collection(collection_name, dimension, index_params \\ %{}) do
    with {:ok, _} <-
           create_collection(%{
             dbName: "default",
             collection_name: collection_name,
             schema: %{
               autoID: false,
               fields: [
                 %{
                   name: "external_id",
                   is_primary_key: true,
                   data_type: 5
                 },
                 %{
                   name: "vector",
                   data_type: 101,
                   is_primary_key: false,
                   # dim: dimension
                   type_params: [
                     %{
                       key: "dim",
                       value: "#{dimension}"
                     }
                   ]
                 }
               ],
               name: collection_name
             }
           }),
         {:ok, _} <- create_index(collection_name, index_params) do
      {:ok, nil}
    end
  end

  def create_collection(params),
    do: GenServer.call(__MODULE__, {:create_collection, params})

  def insert_vectors(collection_name, external_ids, vectors, size),
    do:
      GenServer.call(__MODULE__, {:insert_vectors, collection_name, external_ids, vectors, size})

  def load_collection(collection_name),
    do: GenServer.call(__MODULE__, {:load_collection, collection_name})

  def search_vectors(collection_name, vector, params \\ %{}) do
    with {:ok, _} <- load_collection(collection_name),
         {:ok, data} <-
           GenServer.call(__MODULE__, {:search_vectors, collection_name, vector, params}) do
      %{
        "results" => %{
          "ids" => %{"IdField" => %{"IntId" => %{"data" => ids}}},
          "scores" => scores
        }
      } = data

      result =
        ids
        |> Enum.zip(scores)
        |> Enum.map(fn {id, distance} -> %{id: id, distance: distance} end)

      {:ok, result}
    end
  end

  def create_index(collection_name, params \\ %{}),
    do: GenServer.call(__MODULE__, {:create_index, collection_name, params})

  @impl true
  def init(%{
        host: host,
        port: port
      }) do
    url = "#{host}:#{port}"

    headers = [
      # {"Authorization", "Bearer #{username}:#{password}"},
      {"accept", "application/json"},
      {"content-type", "application/json"}
    ]

    {:ok, {url, headers}}
  end

  def init(_), do: {:stop, :invalid_config}

  @impl GenServer
  def handle_call(:list_collections, _from, {url, headers} = state) do
    reply =
      "#{url}/api/v1/collections"
      |> Req.get!(headers: headers)
      |> get_reply()

    {:reply, reply, state}
  end

  @impl GenServer
  def handle_call({:create_collection, params}, _from, {url, headers} = state) do
    reply =
      "#{url}/api/v1/collection"
      |> Req.post!(headers: headers, json: params)
      |> get_reply()

    {:reply, reply, state}
  end

  @impl GenServer
  def handle_call(
        {:insert_vectors, collection_name, external_ids, vectors, size},
        _from,
        {url, headers} = state
      ) do
    reply =
      "#{url}/api/v1/entities"
      |> Req.post!(
        headers: headers,
        json: %{
          collection_name: collection_name,
          fields_data: [
            %{
              field_name: "external_id",
              type: 5,
              field: external_ids
            },
            %{
              field_name: "vector",
              type: 101,
              field: vectors
            }
          ],
          num_rows: size
        }
      )
      |> get_reply()

    {:reply, reply, state}
  end

  @impl GenServer
  def handle_call(
        {:load_collection, collection_name},
        _from,
        {url, headers} = state
      ) do
    json = %{collection_name: collection_name}

    reply =
      "#{url}/api/v1/collection/load"
      |> Req.post!(
        headers: headers,
        json: json
      )
      |> get_reply()

    {:reply, reply, state}
  end

  @impl GenServer
  def handle_call(
        {:search_vectors, collection_name, vector, _params},
        _from,
        {url, headers} = state
      ) do
    json = %{
      collection_name: collection_name,
      vectors: [vector],
      dsl_type: 1,
      search_params: [
        %{key: "anns_field", value: "vector"},
        %{key: "topk", value: "10"},
        %{key: "params", value: "{\"nprobe\": 10}"},
        %{key: "metric_type", value: "L2"},
        %{key: "round_decimal", value: "-1"}
      ]
    }

    reply =
      "#{url}/api/v1/search"
      |> Req.post!(
        headers: headers,
        json: json
      )
      |> get_reply()
      |> dbg

    {:reply, reply, state}
  end

  @impl true
  def handle_call(
        {:create_index, collection_name, params},
        _from,
        {url, headers} = state
      ) do
    extra_params =
      Enum.reduce(params, [], fn
        {:metric_type, value}, acc -> acc ++ [%{key: "metric_type", value: value}]
        {:index_type, value}, acc -> acc ++ [%{key: "index_type", value: value}]
        {:index_params, value}, acc -> acc ++ [%{key: "params", value: Jason.encode!(value)}]
        _, acc -> acc
      end)

    json = %{collection_name: collection_name, field_name: "vector", extra_params: extra_params}

    reply =
      "#{url}/api/v1/index"
      |> Req.post!(
        headers: headers,
        json: json
      )
      |> get_reply()

    {:reply, reply, state}
  end

  defp get_reply(%{body: %{"status" => %{"error_code" => code, "reason" => message}}}),
    do: {:error, %{code: code, message: message}}

  defp get_reply(%{body: %{"error_code" => code, "reason" => message}}),
    do: {:error, %{code: code, message: message}}

  defp get_reply(%{status: 200, body: data}), do: {:ok, data}

  defp get_reply(_), do: {:error, :invalid_milvus_request}
end
