defmodule TdAi.Completion.ProviderProperties.Schema do
  @moduledoc """
  Generic Ecto Schema module for ProviderProperties embed
  """
  defmacro __using__(opts) do
    required_fields = Keyword.get(opts, :required_fields, [])
    optional_fields = Keyword.get(opts, :optional_fields, [])
    secret_fields = Keyword.get(opts, :secret_fields, [])

    quote do
      use Ecto.Schema

      import Ecto.Changeset

      @primary_key false
      embedded_schema do
        unquote(required_fields)
        |> Kernel.++(unquote(optional_fields))
        |> Kernel.++(unquote(secret_fields))
        |> then(
          &for {key, type} <- &1 do
            field key, type
          end
        )
      end

      def changeset(%__MODULE__{} = struct, %{} = params) do
        required = fields_keys(unquote(required_fields))
        optional = fields_keys(unquote(optional_fields))

        struct
        |> cast(params, required ++ optional)
        |> validate_required(required)
      end

      def secrets_changeset(_struct, %{} = params) do
        cast(%__MODULE__{}, params, fields_keys(unquote(secret_fields)))
      end

      def all_fields_changeset(struct, %{} = params) do
        required = fields_keys(unquote(required_fields))
        optional = fields_keys(unquote(optional_fields))
        secret = fields_keys(unquote(secret_fields))

        cast(struct, params, required ++ optional ++ secret)
      end

      def take_secrets(map) do
        Map.take(map, fields_keys(unquote(secret_fields)))
      end

      def json(%__MODULE__{} = struct) do
        required = fields_keys(unquote(required_fields))
        optional = fields_keys(unquote(optional_fields))

        Map.take(struct, required ++ optional)
      end

      defp fields_keys(fields), do: Enum.map(fields, fn {key, _} -> key end)
    end
  end
end
