defmodule TdAi.CacheConfigTest do
  use ExUnit.Case

  setup do
    original_audit_config = Application.get_env(:td_cache, :audit, [])
    original_event_stream_config = Application.get_env(:td_cache, :event_stream, [])

    on_exit(fn ->
      Application.put_env(:td_cache, :audit, original_audit_config)
      Application.put_env(:td_cache, :event_stream, original_event_stream_config)
    end)

    :ok
  end

  describe "td-cache configuration from environment variables" do
    test "reads REDIS_AUDIT_STREAM_MAXLEN from environment" do
      System.put_env("REDIS_AUDIT_STREAM_MAXLEN", "230")

      Application.put_env(:td_cache, :audit,
        service: "td_ai",
        stream: "audit:events",
        maxlen: System.get_env("REDIS_AUDIT_STREAM_MAXLEN", "100")
      )

      audit_config = Application.get_env(:td_cache, :audit)
      assert Keyword.get(audit_config, :maxlen) == "230"

      System.delete_env("REDIS_AUDIT_STREAM_MAXLEN")
    end

    test "reads REDIS_STREAM_MAXLEN from environment" do
      System.put_env("REDIS_STREAM_MAXLEN", "310")

      Application.put_env(:td_cache, :event_stream,
        consumer_id: "default",
        consumer_group: "ai",
        maxlen: System.get_env("REDIS_STREAM_MAXLEN", "100"),
        streams: []
      )

      event_stream_config = Application.get_env(:td_cache, :event_stream)
      assert Keyword.get(event_stream_config, :maxlen) == "310"

      System.delete_env("REDIS_STREAM_MAXLEN")
    end

    test "uses default values when environment variables are not set" do
      System.delete_env("REDIS_AUDIT_STREAM_MAXLEN")
      System.delete_env("REDIS_STREAM_MAXLEN")

      Application.put_env(:td_cache, :audit,
        service: "td_ai",
        stream: "audit:events",
        maxlen: System.get_env("REDIS_AUDIT_STREAM_MAXLEN", "100")
      )

      Application.put_env(:td_cache, :event_stream,
        maxlen: System.get_env("REDIS_STREAM_MAXLEN", "100"),
        streams: []
      )

      audit_config = Application.get_env(:td_cache, :audit)
      event_stream_config = Application.get_env(:td_cache, :event_stream)

      assert Keyword.get(audit_config, :maxlen) == "100"
      assert Keyword.get(event_stream_config, :maxlen) == "100"
    end

    test "configuration preserves AI model events" do
      System.put_env("REDIS_STREAM_MAXLEN", "420")

      Application.put_env(:td_cache, :event_stream,
        consumer_id: "default",
        consumer_group: "ai",
        maxlen: System.get_env("REDIS_STREAM_MAXLEN", "100"),
        streams: [
          [key: "model_training:events", consumer: TdAi.Cache.ModelTrainer],
          [key: "inference:events", consumer: TdAi.Cache.InferenceProcessor],
          [key: "embedding:events", consumer: TdAi.Cache.EmbeddingGenerator]
        ]
      )

      event_stream_config = Application.get_env(:td_cache, :event_stream)

      assert Keyword.get(event_stream_config, :maxlen) == "420"
      assert Keyword.get(event_stream_config, :consumer_group) == "ai"

      streams = Keyword.get(event_stream_config, :streams)
      assert length(streams) == 3

      model_stream = Enum.find(streams, &(Keyword.get(&1, :key) == "model_training:events"))
      assert Keyword.get(model_stream, :consumer) == TdAi.Cache.ModelTrainer

      System.delete_env("REDIS_STREAM_MAXLEN")
    end
  end
end
