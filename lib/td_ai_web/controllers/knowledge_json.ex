defmodule TdAiWeb.KnowledgeJSON do
  @doc """
  Renders a list of knowledges.
  """
  def index(%{knowledges: knowledges}) do
    %{data: for(knowledge <- knowledges, do: data(knowledge))}
  end

  def index_jobs(%{knowledges_jobs: knowledges_jobs}) do
    %{
      data:
        Enum.map(knowledges_jobs, fn {knowledge, job} ->
          %{
            knowledge: data(knowledge),
            job: data(job)
          }
        end)
    }
  end

  @doc """
  Renders a single knowledge.
  """
  def show(%{knowledge: knowledge}), do: %{data: data(knowledge)}

  def show(%{knowledges_job: knowledges_job}), do: %{data: data(knowledges_job)}

  defp data(%Oban.Job{} = knowledges_job) do
    %{
      task_reference: knowledges_job.id,
      status: knowledges_job.state
    }
  end

  defp data(%TdAi.Knowledges.Knowledge{} = knowledge) do
    %{
      id: knowledge.id,
      name: knowledge.name,
      description: knowledge.description,
      filename: knowledge.filename,
      format: knowledge.format,
      md5: knowledge.md5,
      n_chunks: knowledge.n_chunks,
      status: knowledge.status,
      inserted_at: knowledge.inserted_at,
      updated_at: knowledge.updated_at
    }
  end

  defp data({%TdAi.Knowledges.Knowledge{} = knowledge, %Oban.Job{} = job}) do
    %{
      knowledge: data(knowledge),
      job: data(job)
    }
  end
end
