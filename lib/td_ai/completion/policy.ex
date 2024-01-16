defmodule TdAi.Completion.Policy do
  @moduledoc "Authorization rules for TdAi.Completion"

  alias TdCore.Auth.Permissions

  @behaviour Bodyguard.Policy

  # Admin accounts can do anything with data sets
  def authorize(_action, %{role: "admin"}, _params), do: true

  def authorize(:request_suggestion, %{} = claims, {"business_concept", domain_ids}) do
    Permissions.all_authorized?(claims, :ai_business_concepts, domain_ids)
  end

  # No other users can do nothing
  def authorize(_action, _claims, _params), do: false
end
