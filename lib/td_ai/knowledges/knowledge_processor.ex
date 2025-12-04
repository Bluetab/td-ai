defmodule TdAi.Knowledges.KnowledgeProcessor do
  @moduledoc """
    An Oban worker responsible for processing knowledge files.

    This worker is enqueued when a knowledge file is uploaded and executes
    the processing logic asynchronously using `TdAi.Knowledges.KnowledgeProcessor`.

    ## Functionality
    - Ensures uniqueness based on the file `hash`, preventing duplicate processing.
    - Processes uploaded knowledge files asynchronously via Oban.
    - Supports retry attempts (up to 1) in case of failures.
  """

  use Oban.Worker, queue: :knowledge_queue, max_attempts: 1

  alias TdAi.Indices
  alias TdAi.Knowledges.Knowledge
  alias TdAi.Knowledges.KnowledgeChunk
  alias TdAi.Repo
  alias TdAi.Search.Indexer

  require Logger

  @chunks_processor Application.compile_env(:td_ai, :chunks_processor)
  @vector_generator Application.compile_env(:td_ai, :vector_generator)

  @index_type :rag

  @impl Oban.Worker
  def perform(%Oban.Job{args: knowledge}), do: process_knowledge(knowledge)

  def process_knowledge(
        %{
          "filename" => filename,
          "md5" => file_md5,
          "path" => file_path,
          "id_knowledge" => id_knowledge
        } = knowledge
      ) do
    update_knowledge_status(file_md5, "processing", 0)

    collections = get_collections()

    chunks =
      knowledge
      |> @chunks_processor.chunks_kwnowledge()
      |> Enum.map(fn %{"chunk_id" => chunk_id} = chunk ->
        chunk
        |> Map.put("id", "#{id_knowledge}_#{chunk_id}")
        |> Map.put("md5", file_md5)
        |> Map.put("filename", filename)
        |> Map.put("format", Path.extname(filename) |> String.trim_leading("."))
        |> Map.put("embedding", %{})
        |> KnowledgeChunk.transform()
      end)
      |> add_embeddings(collections)

    Indexer.index_documents_batch(chunks)
    update_knowledge_status(file_md5, "completed", length(chunks))

    delete_tmp_file(file_path)
    {:ok, :ok}
  rescue
    error ->
      Logger.error("Error processing knowledge file: #{filename} error: #{inspect(error)}")
      update_knowledge_status(file_md5, "failed", 0)
      delete_tmp_file(file_path)
      {:error, error}
  end

  def get_index_type, do: @index_type

  def get_collections do
    Indices.list_indices(%{index_type: to_string(@index_type), enabled: true})
  end

  def chunks_kwnowledge(%{"path" => file_path}) do
    python = Application.get_env(:td_ai, :python)
    python_script = Path.join([:code.priv_dir(:td_ai), "python", "src", "docling_parser.py"])

    case System.cmd(python, [python_script, file_path]) do
      {output, 0} ->
        Logger.debug("Python script output: #{String.slice(output, 0, 200)}...")

        output
        |> String.trim()
        |> Jason.decode!()

      {error_output, exit_code} ->
        Logger.error(
          "Error executing docling parser (exit #{exit_code}): #{String.trim(error_output)}"
        )

        raise "Docling parser failed"
    end
  end

  defp add_embeddings(chunks, collections) do
    Logger.info(
      "Calculating embeddings for #{length(chunks)} chunks of #{Enum.at(chunks, 0).filename}"
    )

    start_time = System.monotonic_time(:millisecond)

    result =
      chunks
      |> Enum.chunk_every(128)
      |> Enum.flat_map(&add_embeddings_to_batch(&1, collections))

    elapsed_ms = System.monotonic_time(:millisecond) - start_time

    Logger.info(
      "Finished calculating embeddings for #{length(chunks)} chunks in #{elapsed_ms} ms"
    )

    result
  end

  defp add_embeddings_to_batch(batch_chunks, collections) do
    texts = Enum.map(batch_chunks, & &1.text)
    batch_embeddings_by_collection = build_batch_embeddings(texts, collections)

    Enum.with_index(batch_chunks)
    |> Enum.map(fn {chunk, index} ->
      chunk_embeddings = build_chunk_embeddings(batch_embeddings_by_collection, index)
      %{chunk | embedding: chunk_embeddings}
    end)
  end

  defp build_batch_embeddings(texts, collections) do
    Enum.reduce(collections, %{}, fn %{collection_name: collection_name}, acc ->
      case @vector_generator.generate_vector(texts, @index_type, collection_name) do
        {^collection_name, embeddings} when is_list(embeddings) ->
          Map.put(acc, collection_name, embeddings)

        _ ->
          acc
      end
    end)
  end

  defp build_chunk_embeddings(batch_embeddings_by_collection, index) do
    Enum.reduce(batch_embeddings_by_collection, %{}, fn {collection_name, embeddings_list}, acc ->
      embedding = Enum.at(embeddings_list, index)
      Map.put(acc, "vector_#{collection_name}", embedding)
    end)
  end

  defp delete_tmp_file(file_path) do
    if File.exists?(file_path) do
      File.rm(file_path)
    end
  end

  defp update_knowledge_status(md5, status, n_chunks) do
    case Repo.get_by(Knowledge, md5: md5) do
      nil ->
        Logger.error("Knowledge with md5 #{md5} not found in database")
        :error

      knowledge ->
        knowledge
        |> Knowledge.changeset(%{status: status, n_chunks: n_chunks})
        |> Repo.update()
        |> case do
          {:ok, _} ->
            :ok

          {:error, changeset} ->
            Logger.error("Failed to update knowledge status: #{inspect(changeset)}")
            :error
        end
    end
  end
end
