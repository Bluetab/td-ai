defmodule TdAi.MixProject do
  use Mix.Project

  def project do
    [
      app: :td_ai,
      version:
        case System.get_env("APP_VERSION") do
          nil -> "6.12.0-local"
          v -> v
        end,
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [
        td_ai: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent],
          steps: [:assemble, &copy_bin_files/1, :tar]
        ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {TdAi.Application, []},
      extra_applications: [:logger, :runtime_tools, :vaultex]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]

  defp copy_bin_files(release) do
    File.cp_r("rel/bin", Path.join(release.path, "bin"))
    release
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.18"},
      {:phoenix_ecto, "~> 4.6.3"},
      {:plug_cowboy, "~> 2.7"},
      {:ecto_sql, "~> 3.12.1"},
      {:postgrex, "~> 0.19.3"},
      {:bodyguard, "~> 2.4.3"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.1.0"},
      {:jason, "~> 1.4.4"},
      {:vaultex, "~> 1.0.1"},
      {:httpoison, "~> 2.2.1", override: true},
      {:td_core, git: "https://github.com/Bluetab/td-core.git", branch: "feature/td-6911"},
      {:scholar, "~> 0.3.1"},
      {:exla, "~> 0.9.2"},
      {:bumblebee, "~> 0.6.0"},
      {:req, "~> 0.5.8"},
      {:openai, "~> 0.6.2"},
      {:ex_aws, "~> 2.5.8 "},
      {:ex_aws_bedrock, "~> 2.5.1"},
      {:credo, "~> 1.7.10", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4.5", only: :dev, runtime: false},
      {:ex_machina, "~> 2.8", only: :test},
      {:mox, "~> 1.2.0", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
