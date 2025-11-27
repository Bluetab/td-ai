defmodule TdAi.Jobs.CleanupUploadsJob do
  @moduledoc """
  Job to clean temporary uploads folder using Quantum scheduler.
  """

  require Logger

  @doc """
  Function that will be executed by Quantum to clean the uploads folder.
  """
  def perform do
    uploads_folder = Application.get_env(:td_ai, TdAi.Knowledges)[:uploads_tmp_folder]

    if File.exists?(uploads_folder) do
      case File.rm_rf(uploads_folder) do
        {:ok, _} ->
          Logger.info("Uploads cleaned correctly")
          :ok

        {:error, reason, _} ->
          Logger.error("Error cleanning uploads")
          {:error, reason}
      end
    end
  end
end
