defmodule TdAi.Actions.Actions do
  @moduledoc """
  A context for ai actions
  """

  import Ecto.Query

  alias TdAi.Actions.Action
  alias TdAi.Repo

  defdelegate authorize(action, user, params), to: __MODULE__.Policy

  def create(attrs \\ %{}) do
    %Action{}
    |> Action.changeset(attrs)
    |> Repo.insert()
  end

  def list(params \\ %{}) do
    params
    |> actions_query()
    |> Repo.all()
  end

  def get(id), do: Repo.get(Action, id)

  def update(%Action{} = action, %{} = params) do
    action
    |> Action.changeset(params)
    |> Repo.update()
  end

  def delete(%Action{} = action, opts \\ []),
    do: do_delete(action, Keyword.get(opts, :logical, false))

  defp do_delete(action, true) do
    action
    |> Action.changeset(%{is_enabled: false, deleted_at: DateTime.utc_now()})
    |> Repo.update()
  end

  defp do_delete(action, false), do: Repo.delete(action)

  defp actions_query(params) do
    params
    |> Enum.reduce(Action, fn
      {"id", id}, q ->
        where(q, [a], a.id == ^id)

      {"user_id", user_id}, q ->
        where(q, [a], a.user_id == ^user_id)

      {"types", types}, q ->
        where(q, [a], a.type in ^types)

      {"is_enabled", is_enabled}, q ->
        where(q, [a], a.is_enabled == ^is_enabled)

      {"deleted", false}, q ->
        where(q, [a], is_nil(a.deleted_at))

      {"deleted", true}, q ->
        where(q, [a], not is_nil(a.deleted_at))

      {"deleted", _}, q ->
        q
    end)
  end
end
