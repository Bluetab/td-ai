Mox.defmock(MockClusterHandler, for: TdCluster.ClusterHandler)
Mox.defmock(TdAi.Provider.Mock, for: TdAi.Provider)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(TdAi.Repo, :manual)
