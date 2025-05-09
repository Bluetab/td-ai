defmodule TdAi.Indices do
  @moduledoc """
  The Indices context.
  """

  import Ecto.Query, warn: false
  alias TdAi.Repo

  alias TdAi.Embeddings.Server
  alias TdAi.Indices.Index

  defdelegate authorize(action, user, params), to: __MODULE__.Policy

  @doc """
  Returns the list of indices.

  ## Examples

      iex> list_indices(%{enabled: true})
      [%Index{}, ...]

  """
  def list_indices(args \\ %{}) do
    args
    |> Enum.reduce(Index, fn
      {:enabled, true}, q -> where(q, [i], not is_nil(i.enabled_at))
      {:enabled, false}, q -> where(q, [i], is_nil(i.enabled_at))
      _, q -> q
    end)
    |> Repo.all()
  end

  @doc """
  Gets a single index.

  Raises `Ecto.NoResultsError` if the Index does not exist.

  ## Examples

      iex> get_index!(123)
      %Index{}

      iex> get_index!(456)
      ** (Ecto.NoResultsError)

  """
  def get_index!(id), do: Repo.get!(Index, id)

  @doc """
  Creates a index.

  ## Examples

      iex> create_index(%{field: value})
      {:ok, %Index{}}

      iex> create_index(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_index(attrs \\ %{}) do
    %Index{}
    |> Index.changeset(attrs)
    |> Repo.insert()
    |> tap(&add_serving/1)
  end

  @doc """
  Updates a index.

  ## Examples

      iex> update_index(index, %{field: new_value})
      {:ok, %Index{}}

      iex> update_index(index, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_index(%Index{} = index, attrs) do
    index
    |> Index.changeset(attrs)
    |> Repo.update()
    |> tap(&add_serving/1)
  end

  @doc """
  Deletes a index.

  ## Examples

      iex> delete_index(index)
      {:ok, %Index{}}

      iex> delete_index(index)
      {:error, %Ecto.Changeset{}}

  """
  def delete_index(%Index{} = index) do
    index
    |> Repo.delete()
    |> tap(&remove_serving/1)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking index changes.

  ## Examples

      iex> change_index(index)
      %Ecto.Changeset{data: %Index{}}

  """
  def change_index(%Index{} = index, attrs \\ %{}) do
    Index.changeset(index, attrs)
  end

  def enable(%Index{enabled_at: nil} = index) do
    index
    |> Index.changeset(%{enabled_at: DateTime.utc_now()})
    |> Repo.update()
    |> tap(&add_serving/1)
  end

  def enable(index), do: {:ok, index}

  def disable(%Index{enabled_at: enabled_at} = index) when not is_nil(enabled_at) do
    index
    |> Index.changeset(%{enabled_at: nil})
    |> Repo.update()
    |> tap(&remove_serving/1)
  end

  def disable(index), do: {:ok, index}

  def first_enabled do
    Index
    |> where([i], not is_nil(i.enabled_at))
    |> order_by(asc: :enabled_at)
    |> limit(1)
    |> Repo.one()
  end

  defp add_serving({:ok, %Index{enabled_at: enabled_at} = index}) when not is_nil(enabled_at) do
    Server.add_serving(index)
  end

  defp add_serving(_other), do: :noop

  defp remove_serving({:ok, %Index{enabled_at: nil} = index}) do
    Server.remove_serving(index)
  end

  defp remove_serving(_other), do: :noop
end
