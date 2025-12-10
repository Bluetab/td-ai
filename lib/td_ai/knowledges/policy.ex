defmodule TdAi.Knowledges.Policy do
  @moduledoc "Authorization rules for TdAi.Knowledges"

  @behaviour Bodyguard.Policy

  # Admin accounts can do anything with data sets
  def authorize(_action, %{role: "admin"}, _params), do: true

  # No other users can do nothing
  def authorize(_action, _claims, _params), do: false
end
