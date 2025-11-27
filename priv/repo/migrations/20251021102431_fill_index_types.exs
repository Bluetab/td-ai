defmodule TdAi.Repo.Migrations.FillIndexTypes do
  use Ecto.Migration
  import Ecto.Query
  alias TdAi.Indices.Index

  def change do
    Index
    |> where([i], is_nil(i.index_type) or i.index_type == "")
    |> TdAi.Repo.update_all(set: [index_type: "suggestions"])
  end
end
