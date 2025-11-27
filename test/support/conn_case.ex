defmodule TdAiWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use TdAiWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  import TdCore.TestSupport.Authentication, only: :functions

  using do
    quote do
      # The default endpoint for testing
      @endpoint TdAiWeb.Endpoint

      use TdAiWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import TdAiWeb.ConnCase

      import TdAi.Factory
      import TdAi.TestOperators

      def upload(path) do
        %Plug.Upload{path: path, filename: Path.basename(path)}
      end
    end
  end

  setup tags do
    TdAi.DataCase.setup_sandbox(tags)

    case tags[:authentication] do
      nil ->
        [conn: Phoenix.ConnTest.build_conn()]

      auth_opts ->
        Phoenix.ConnTest.build_conn()
        |> put_user_auth(auth_opts)
        |> assign_permissions(auth_opts[:permissions])
    end
  end
end
