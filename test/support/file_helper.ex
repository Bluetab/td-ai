defmodule TdAi.FileHelper do
  @moduledoc """
  Module for file helper functions.
  """

  import ExUnit.Callbacks

  def load_file(path, test_pid) do
    subfolder =
      test_pid
      |> :erlang.pid_to_list()
      |> List.delete_at(0)
      |> List.delete_at(-1)
      |> to_string()

    parent_dir = Path.join(["test", subfolder])

    File.mkdir_p!(parent_dir)

    file_name = Path.basename(path)
    tmp_path = Path.join([parent_dir, file_name])
    File.cp_r!(path, tmp_path)

    on_exit(fn ->
      File.rm_rf!(parent_dir)
    end)

    [
      tmp_path: tmp_path,
      file_name: file_name,
      parent_dir: parent_dir
    ]
  end
end
