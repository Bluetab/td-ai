defmodule TdAi.Completion do
  @moduledoc """
  The Completion context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias TdAi.Repo
  alias TdAi.Vault

  alias TdAi.Completion.ResourceMapping

  defdelegate authorize(action, user, params), to: __MODULE__.Policy

  @doc """
  Returns the list of resource_mappings.

  ## Examples

      iex> list_resource_mappings()
      [%ResourceMapping{}, ...]

  """
  def list_resource_mappings do
    ResourceMapping
    |> order_by([r], r.id)
    |> Repo.all()
  end

  @doc """
  Gets a single resource_mapping.

  Raises `Ecto.NoResultsError` if the Resource mapping does not exist.

  ## Examples

      iex> get_resource_mapping!(123)
      %ResourceMapping{}

      iex> get_resource_mapping!(456)
      ** (Ecto.NoResultsError)

  """
  def get_resource_mapping!(id), do: Repo.get!(ResourceMapping, id)

  def get_resource_mapping_by_selector(resource_type, selector \\ %{}) do
    ResourceMapping
    |> where([rm], rm.resource_type == ^resource_type and rm.selector == ^selector)
    |> limit(1)
    |> Repo.all()
    |> Enum.at(0)
  end

  @doc """
  Creates a resource_mapping.

  ## Examples

      iex> create_resource_mapping(%{field: value})
      {:ok, %ResourceMapping{}}

      iex> create_resource_mapping(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_resource_mapping(attrs \\ %{}) do
    %ResourceMapping{}
    |> ResourceMapping.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a resource_mapping.

  ## Examples

      iex> update_resource_mapping(resource_mapping, %{field: new_value})
      {:ok, %ResourceMapping{}}

      iex> update_resource_mapping(resource_mapping, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_resource_mapping(%ResourceMapping{} = resource_mapping, attrs) do
    resource_mapping
    |> ResourceMapping.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a resource_mapping.

  ## Examples

      iex> delete_resource_mapping(resource_mapping)
      {:ok, %ResourceMapping{}}

      iex> delete_resource_mapping(resource_mapping)
      {:error, %Ecto.Changeset{}}

  """
  def delete_resource_mapping(%ResourceMapping{} = resource_mapping) do
    Repo.delete(resource_mapping)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking resource_mapping changes.

  ## Examples

      iex> change_resource_mapping(resource_mapping)
      %Ecto.Changeset{data: %ResourceMapping{}}

  """
  def change_resource_mapping(%ResourceMapping{} = resource_mapping, attrs \\ %{}) do
    ResourceMapping.changeset(resource_mapping, attrs)
  end

  alias TdAi.Completion.Prompt

  @doc """
  Returns the list of prompts.

  ## Examples

      iex> list_prompts()
      [%Prompt{}, ...]

  """
  def list_prompts do
    Prompt
    |> order_by([p], p.id)
    |> Repo.all()
  end

  @doc """
  Gets a single prompt.

  Raises `Ecto.NoResultsError` if the Prompt does not exist.

  ## Examples

      iex> get_prompt!(123)
      %Prompt{}

      iex> get_prompt!(456)
      ** (Ecto.NoResultsError)

  """
  def get_prompt!(id), do: Repo.get!(Prompt, id)

  @doc """
  Creates a prompt.

  ## Examples

      iex> create_prompt(%{field: value})
      {:ok, %Prompt{}}

      iex> create_prompt(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_prompt(attrs \\ %{}) do
    %Prompt{}
    |> Prompt.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a prompt.

  ## Examples

      iex> update_prompt(prompt, %{field: new_value})
      {:ok, %Prompt{}}

      iex> update_prompt(prompt, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_prompt(%Prompt{} = prompt, attrs) do
    prompt
    |> Prompt.changeset(attrs)
    |> Repo.update()
  end

  def set_prompt_active(%Prompt{language: language, resource_type: resource_type} = prompt) do
    Multi.new()
    |> Multi.update_all(
      :set_all_false,
      fn _ ->
        from(p in Prompt,
          where: p.language == ^language and p.resource_type == ^resource_type,
          update: [set: [active: false]]
        )
      end,
      []
    )
    |> Multi.update(:set_active, fn _ ->
      Prompt.active_changeset(prompt, true)
    end)
    |> Repo.transaction()
    |> handle_set_active_response()
  end

  defp handle_set_active_response({:ok, %{set_active: prompt}}), do: {:ok, prompt}
  defp handle_set_active_response(error), do: error

  @doc """
  Deletes a prompt.

  ## Examples

      iex> delete_prompt(prompt)
      {:ok, %Prompt{}}

      iex> delete_prompt(prompt)
      {:error, %Ecto.Changeset{}}

  """
  def delete_prompt(%Prompt{} = prompt) do
    Repo.delete(prompt)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking prompt changes.

  ## Examples

      iex> change_prompt(prompt)
      %Ecto.Changeset{data: %Prompt{}}

  """
  def change_prompt(%Prompt{} = prompt, attrs \\ %{}) do
    Prompt.changeset(prompt, attrs)
  end

  def get_prompt_by_resource_and_language(resource_type, language) do
    Prompt
    |> Repo.get_by(resource_type: resource_type, language: language, active: true)
    |> maybe_enrich_provider()
  end

  defp maybe_enrich_provider(nil), do: nil

  defp maybe_enrich_provider(prompt),
    do:
      prompt
      |> Repo.preload(:provider)
      |> Map.update(:provider, nil, &enrich_provider_secrets/1)

  alias TdAi.Completion.Suggestion

  @doc """
  Returns the list of suggestions.

  ## Examples

      iex> list_suggestions()
      [%Suggestion{}, ...]

  """
  def list_suggestions do
    Repo.all(Suggestion)
  end

  @doc """
  Gets a single suggestion.

  Raises `Ecto.NoResultsError` if the Suggestion does not exist.

  ## Examples

      iex> get_suggestion!(123)
      %Suggestion{}

      iex> get_suggestion!(456)
      ** (Ecto.NoResultsError)

  """
  def get_suggestion!(id), do: Repo.get!(Suggestion, id)

  @doc """
  Creates a suggestion.

  ## Examples

      iex> create_suggestion(%{field: value})
      {:ok, %Suggestion{}}

      iex> create_suggestion(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_suggestion(attrs \\ %{}) do
    %Suggestion{}
    |> Suggestion.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a suggestion.

  ## Examples

      iex> update_suggestion(suggestion, %{field: new_value})
      {:ok, %Suggestion{}}

      iex> update_suggestion(suggestion, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_suggestion(%Suggestion{} = suggestion, attrs) do
    suggestion
    |> Suggestion.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a suggestion.

  ## Examples

      iex> delete_suggestion(suggestion)
      {:ok, %Suggestion{}}

      iex> delete_suggestion(suggestion)
      {:error, %Ecto.Changeset{}}

  """
  def delete_suggestion(%Suggestion{} = suggestion) do
    Repo.delete(suggestion)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking suggestion changes.

  ## Examples

      iex> change_suggestion(suggestion)
      %Ecto.Changeset{data: %Suggestion{}}

  """
  def change_suggestion(%Suggestion{} = suggestion, attrs \\ %{}) do
    Suggestion.changeset(suggestion, attrs)
  end

  alias TdAi.Completion.Provider

  @doc """
  Returns the list of providers.

  ## Examples

      iex> list_providers()
      [%Provider{}, ...]

  """
  def list_providers do
    Repo.all(Provider)
  end

  @doc """
  Gets a single provider.

  Raises `Ecto.NoResultsError` if the Provider does not exist.

  ## Examples

      iex> get_provider!(123)
      %Provider{}

      iex> get_provider!(456)
      ** (Ecto.NoResultsError)

  """
  def get_provider!(id), do: Repo.get!(Provider, id)

  @doc """
  Creates a provider.

  ## Examples

      iex> create_provider(%{field: value})
      {:ok, %Provider{}}

      iex> create_provider(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_provider(attrs \\ %{}) do
    changeset = Provider.changeset(%Provider{}, attrs)

    Multi.new()
    |> Multi.insert(:provider, changeset)
    |> Multi.run(:secrets, fn _, _ -> Provider.secret_properties(%Provider{}, attrs) end)
    |> Multi.run(:vault, &persist_secrets/2)
    |> Repo.transaction()
    |> case do
      {:ok, %{provider: provider}} ->
        {:ok, provider}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a provider.

  ## Examples

      iex> update_provider(provider, %{field: new_value})
      {:ok, %Provider{}}

      iex> update_provider(provider, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_provider(%Provider{} = provider, attrs) do
    changeset = Provider.changeset(provider, attrs)

    Multi.new()
    |> Multi.update(:provider, changeset)
    |> Multi.run(:secrets, fn _, _ ->
      provider
      |> enrich_provider_secrets()
      |> Provider.secret_properties(attrs)
    end)
    |> Multi.run(:vault, &persist_secrets/2)
    |> Repo.transaction()
    |> case do
      {:ok, %{provider: provider}} ->
        {:ok, provider}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  defp persist_secrets(_, %{provider: provider, secrets: secrets}) do
    provider
    |> Provider.vault_key()
    |> Vault.write_secrets(secrets)
    |> case do
      :ok -> {:ok, nil}
      error -> {:error, error}
    end
  end

  def enrich_provider_secrets(%Provider{} = provider) do
    provider
    |> Provider.vault_key()
    |> Vault.maybe_read_secrets()
    |> Provider.apply_secrets(provider)
  end

  @doc """
  Deletes a provider.

  ## Examples

      iex> delete_provider(provider)
      {:ok, %Provider{}}

      iex> delete_provider(provider)
      {:error, %Ecto.Changeset{}}

  """
  def delete_provider(%Provider{} = provider) do
    Repo.delete(provider)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking provider changes.

  ## Examples

      iex> change_provider(provider)
      %Ecto.Changeset{data: %Provider{}}

  """
  def change_provider(%Provider{} = provider, attrs \\ %{}) do
    Provider.changeset(provider, attrs)
  end
end
