defmodule TdAi.Knowledges do
  @moduledoc """
  Module for managing knowledge base.
  """

  alias Oban
  alias TdAi.Knowledges.Knowledge
  alias TdAi.Knowledges.KnowledgeProcessor
  alias TdAi.Repo
  alias TdAi.Search.Indexer
  alias TdCore.Utils.FileHash

  defdelegate authorize(action, user, params), to: __MODULE__.Policy

  def create_knowledges(files) when is_list(files) do
    knowledges =
      Enum.map(files, fn {file, name, description} ->
        case create_knowledge(file, name, description) do
          {:ok, knowledge_job} ->
            knowledge_job

          {:error, _, _} = error ->
            error
        end
      end)

    case Enum.find(knowledges, &match?({:error, _, _}, &1)) do
      nil -> {:ok, knowledges}
      error -> error
    end
  end

  defp create_knowledge(file, name, description) do
    case prepare_file_to_index(file, name, description) do
      {:error, reason, message} ->
        {:error, reason, message}

      knowledge ->
        with {:ok, %{id: id} = db_knowledge} <- create_knowledge_record(knowledge),
             {:ok, knowledge_params} <- {:ok, add_kwnowledge_id(knowledge, id)},
             {:ok, job} <- enqueue_processing_job(knowledge_params) do
          {:ok, {db_knowledge, job}}
        else
          {:error, changeset} -> {:error, :validation, changeset}
          error -> error
        end
    end
  end

  def list_knowledges do
    Repo.all(Knowledge)
  end

  def get_knowledge!(id), do: Repo.get!(Knowledge, id)

  def get_knowledge(id), do: Repo.get(Knowledge, id)

  def get_knowledge_by_md5(md5), do: Repo.get_by(Knowledge, md5: md5)

  def update_knowledge(%Knowledge{} = knowledge, attrs) do
    knowledge
    |> Knowledge.changeset(attrs)
    |> Repo.update()
  end

  def update_knowledge_file(%Knowledge{} = knowledge, file) do
    case prepare_file_to_index(file, knowledge.name, knowledge.description) do
      {:error, reason, message} ->
        {:error, reason, message}

      knowledge_params ->
        with :ok <- delete_elasticsearch_chunks(knowledge.md5),
             {:ok, %{id: id} = updated_knowledge} <-
               update_knowledge_record(knowledge, knowledge_params),
             {:ok, knowledge_params} <- {:ok, add_kwnowledge_id(knowledge_params, id)},
             {:ok, job} <- enqueue_processing_job(knowledge_params) do
          {:ok, {updated_knowledge, job}}
        else
          {:error, changeset} -> {:error, :validation, changeset}
          error -> error
        end
    end
  end

  def delete_knowledge(knowledge) do
    with :ok <- delete_elasticsearch_chunks(knowledge.md5) do
      Repo.delete(knowledge)
      :ok
    end
  end

  defp uploads_tmp_folder do
    :td_ai
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:uploads_tmp_folder)
  end

  defp prepare_file_to_index(file, name, description) do
    file
    |> Map.from_struct()
    |> Map.take([:path, :filename])
    |> Map.put(:md5, FileHash.hash(Map.get(file, :path), :md5))
    |> Map.put(:name, name)
    |> Map.put(:description, description)
    |> create_tmp_file()
  end

  defp create_tmp_file(%{path: path, md5: md5} = knowledge) do
    tmp_folder = uploads_tmp_folder()
    unless File.exists?(tmp_folder), do: File.mkdir_p!(tmp_folder)

    new_path = Path.join(uploads_tmp_folder(), md5)

    if File.exists?(new_path) do
      {:error, :conflict, "File is already being processed"}
    else
      File.cp!(path, new_path)
      Map.put(knowledge, :path, new_path)
    end
  end

  defp create_knowledge_record(%{md5: md5, filename: filename} = params) do
    format = Path.extname(filename) |> String.trim_leading(".")

    knowledge =
      params
      |> Map.take([:filename, :md5, :name, :description])
      |> Map.put(:format, format)
      |> Map.put(:n_chunks, 0)
      |> Map.put(:status, "awaiting")

    case get_knowledge_by_md5(md5) do
      nil ->
        %Knowledge{}
        |> Knowledge.changeset(knowledge)
        |> Repo.insert()

      %Knowledge{status: "failed"} = existing_knowledge ->
        with :ok <- delete_elasticsearch_chunks(existing_knowledge.md5) do
          existing_knowledge
          |> Knowledge.changeset(knowledge)
          |> Repo.update()
        end

      %Knowledge{status: status} ->
        {:error, :conflict, "File with MD5 #{md5} already exists with status: #{status}"}
    end
  end

  defp update_knowledge_record(
         %Knowledge{} = existing_knowledge,
         %{md5: md5, filename: filename} = params
       ) do
    format = Path.extname(filename) |> String.trim_leading(".")

    knowledge_params =
      params
      |> Map.take([:filename, :md5])
      |> Map.put(:format, format)
      |> Map.put(:n_chunks, 0)
      |> Map.put(:status, "awaiting")

    case get_knowledge_by_md5(md5) do
      nil ->
        existing_knowledge
        |> Knowledge.changeset(knowledge_params)
        |> Repo.update()

      %Knowledge{status: "failed"} ->
        existing_knowledge
        |> Knowledge.changeset(knowledge_params)
        |> Repo.update()

      %Knowledge{status: status} ->
        {:error, :conflict, "File with MD5 #{md5} already exists with status: #{status}"}
    end
  end

  defp enqueue_processing_job(knowledge) do
    knowledge
    |> KnowledgeProcessor.new()
    |> Oban.insert()
  end

  defp delete_elasticsearch_chunks(md5) do
    with {:ok, _} <- Indexer.delete_index_documents_by_query(%{"md5.keyword" => md5}) do
      :ok
    end
  end

  defp add_kwnowledge_id(knowledge_params, id) do
    Map.put(knowledge_params, :id_knowledge, id)
  end
end
