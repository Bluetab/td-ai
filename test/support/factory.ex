defmodule TdAi.Factory do
  @moduledoc """
  An `ExMachina` factory for data quality tests.
  """

  use ExMachina.Ecto, repo: TdAi.Repo

  alias TdAi.Completion.Prompt
  alias TdAi.Completion.Provider
  alias TdAi.Completion.ProviderProperties
  alias TdAi.Completion.ResourceMapping
  alias TdAi.Completion.Suggestion
  alias TdAi.Indices.Index
  alias TdAi.Predictions.Prediction

  def index_factory(attrs \\ %{}) do
    %Index{
      collection_name: sequence(:index_collection_name, &"Collection#{&1}"),
      embedding: "some embedding",
      mapping: ["option1", "option2"],
      index_type: "some index_type",
      metric_type: "some metric_type"
    }
    |> merge_attributes(attrs)
  end

  def prediction_factory(attrs \\ %{}) do
    %Prediction{
      result: [],
      mapping: ["option1", "option2"],
      data_structure_id: sequence(:data_structure_id, & &1)
    }
    |> merge_attributes(attrs)
  end

  def resource_mapping_factory(attrs \\ %{}) do
    %ResourceMapping{
      name: sequence(:resource_mapping_name, &"Name#{&1}"),
      fields: [%{source: "source.field"}],
      resource_type: "resource_type",
      selector: %{}
    }
    |> merge_attributes(attrs)
  end

  def prompt_factory(attrs \\ %{}) do
    %Prompt{
      active: false,
      name: sequence(:prompt_mapping_name, &"Name#{&1}"),
      language: "some language",
      resource_type: "some resource_type",
      system_prompt: "some system_prompt",
      user_prompt_template: "some user_prompt_template",
      provider: build(:provider)
    }
    |> merge_attributes(attrs)
  end

  def prompt_params_for_factory(attrs \\ %{}) do
    %Prompt{
      active: false,
      name: sequence(:prompt_mapping_name, &"Name#{&1}"),
      language: "some language",
      resource_type: "some resource_type",
      system_prompt: "some system_prompt",
      user_prompt_template: "some user_prompt_template",
      provider: build(:provider_params_for)
    }
    |> merge_attributes(attrs)
  end

  def suggestion_factory(attrs \\ %{}) do
    %Suggestion{
      response: %{},
      resource_id: sequence(:sugestion_resource_id, & &1),
      generated_prompt: sequence(:generated_prompt, &"Prompt#{&1}"),
      request_time: 42,
      requested_by: 42,
      prompt: build(:prompt),
      resource_mapping: build(:resource_mapping),
      status: "ok"
    }
    |> merge_attributes(attrs)
  end

  def provider_factory(attrs \\ %{}) do
    %Provider{
      name: "provider_name",
      type: "mock",
      properties: build(:provider_properties)
    }
    |> merge_attributes(attrs)
  end

  def provider_params_for_factory(attrs \\ %{}) do
    %Provider{
      name: "provider_name",
      type: "mock",
      properties: build(:provider_properties_mock_factory)
    }
    |> merge_attributes(attrs)
  end

  def provider_properties_factory(%{mock: %{} = mock}),
    do: %ProviderProperties{mock: mock}

  def provider_properties_factory(_),
    do: %ProviderProperties{mock: build(:provider_properties_mock)}

  def provider_properties_mock_factory(attrs) do
    %ProviderProperties.Mock{
      model: "some model"
    }
    |> merge_attributes(attrs)
  end
end
