defmodule TdAiWeb.PingController do
  use TdAiWeb, :controller

  def ping(conn, _params) do
    send_resp(conn, :ok, "pong")
  end
end
