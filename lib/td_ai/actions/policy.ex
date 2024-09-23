defmodule TdAi.Actions.Actions.Policy do
  @moduledoc "Authorization rules for TdAi.Actions.Actions"

  @behaviour Bodyguard.Policy

  # Admin accounts can do anything with data sets
  def authorize(_action, %{role: "admin"}, _params), do: true

  def authorize(:search, %{role: "agent"}, _params), do: true

  # No other users can do nothing
  def authorize(_action, _claims, _params), do: false
end
