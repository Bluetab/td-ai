defmodule TdAiWeb.ActionJSON do
  alias TdCache.UserCache

  @fields [
    :id,
    :name,
    :user_id,
    :type,
    :dynamic_content,
    :is_enabled,
    :deleted_at,
    :updated_at
  ]

  def index(%{actions: actions}),
    do: %{data: Enum.map(actions, fn action -> action(action) end)}

  def show(%{action: action}), do: %{data: action(action)}

  def action(%{user_id: user_id} = action) do
    {_, user} = UserCache.get(user_id)

    action
    |> Map.take(@fields)
    |> Map.put(:user, %{id: user_id, full_name: user_full_name(user)})
  end

  defp user_full_name(%{full_name: full_name}) do
    full_name
  end

  defp user_full_name(_), do: ""
end
