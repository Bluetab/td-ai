defmodule TdAi.Completion.Message do
  @moduledoc """
  Ecto Schema module for Completion Message
  """

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :role, :string
    field :content, :string
  end

  def changeset(%__MODULE__{} = struct, %{} = params) do
    struct
    |> cast(params, [:role, :content])
    |> validate_required([:role, :content])
  end

  def json(%__MODULE__{role: role, content: content}) do
    %{role: role, content: content}
  end
end

defmodule TdAi.Completion.Messages do
  @moduledoc """
  Ecto Schema module for Completion Messages
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias TdAi.Completion.Message

  @primary_key false
  embedded_schema do
    embeds_many(:messages, Message, on_replace: :delete)
  end

  def changeset(%__MODULE__{} = struct, %{} = params) do
    struct
    |> cast(params, [])
    |> cast_embed(:messages, required: true)
  end

  def new(messages) do
    %__MODULE__{}
    |> changeset(%{messages: messages})
    |> case do
      %{valid?: true} = changeset -> {:ok, apply_changes(changeset)}
      error -> {:error, error}
    end
  end

  def simple_prompt(system_prompt, user_prompt) do
    %__MODULE__{
      messages: [
        %Message{role: "system", content: system_prompt},
        %Message{role: "user", content: user_prompt}
      ]
    }
  end

  def json(%__MODULE__{messages: messages}) do
    Enum.map(messages, &Message.json/1)
  end
end
