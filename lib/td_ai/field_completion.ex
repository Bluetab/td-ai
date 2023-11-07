defmodule TdAi.FieldCompletion do
  @moduledoc """
  GenServer for Field Completion tasks
  """

  use GenServer

  alias TdCluster.Cluster

  @test """

  fields = [
    %{description: "a short name for the concept", field: "alias"},
    %{
      description: "a boolean weather the concept contains sensitive information",
      field: "gdpr"
    },
    %{
      description: "a boolean weather the concept refers to a critical business term",
      field: "Critical Business Term"
    }
  ]
  TdAi.FieldCompletion.resource_field_completion("data_structure", 12335456, fields)


  """

  def start_link(_) do
    case Application.get_env(:td_core, :env) do
      :test -> :ok
      _ -> GenServer.start_link(__MODULE__, nil, name: __MODULE__)
    end
  end

  def resource_field_completion(resource_type, resource_id, fields) do
    case Application.get_env(:td_core, :env) do
      :test -> %{}
      _ -> GenServer.call(__MODULE__, {resource_type, resource_id, fields}, 30000)
    end
  end

  @impl GenServer
  def init(_) do
    system_prompt = Application.fetch_env!(:td_ai, TdAi.FieldCompletion)[:system_prompt]
    model = Application.fetch_env!(:td_ai, TdAi.FieldCompletion)[:model]

    {:ok,
     %{
       system_prompt: system_prompt,
       model: model
     }}
  end

  @impl GenServer
  def handle_call(
        {"data_structure", resource_id, fields},
        _from,
        %{
          system_prompt: system_prompt,
          model: model
        } = state
      ) do
    {:ok, structure} = Cluster.TdDd.get_latest_structure_version(resource_id)

    structure =
      structure
      |> Map.take([:name, :group, :classes, :type, :mutable_metadata, :description])
      |> Jason.encode!()

    content =
      """
      Data Structure: #{structure}
      Fill the following fields: #{Jason.encode!(fields)}
      """

    {:ok,
     %{
       choices: [
         %{
           "message" => %{
             "content" => response
           }
         }
       ]
     }} =
      OpenAI.chat_completion(
        model: model,
        messages: [
          %{
            role: "system",
            content: system_prompt
          },
          %{
            role: "user",
            content: content
          }
        ]
      )

    result = Jason.decode!(response)
    # result = nil
    {:reply, result, state}
  end

  @impl GenServer
  def handle_call(_, _from, state) do
    {:reply, nil, state}
  end
end
