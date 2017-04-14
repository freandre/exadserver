# bench/basic_bench.exs
defmodule ExJSONRPCClientTCPBench do
  use Benchfella

  @address "localhost"
  @tcp_port 8181

  setup_all do
    Application.ensure_all_started(:shackle)
    Application.ensure_all_started(:jsonrpc2)

    :ok = ExJSONRPCClientTCP.start(@address, @tcp_port)

    ExJSONRPCClientTCP.hello("Bench")

    # ok just use the local instance to generate data from metadata
    # we should definitely use distribution here
    ExConfServer.start_link(:configServer, {"./test/resources/targetingData.json", 0})

    {:ok, []}
  end

  teardown_all _ do
    ExConfServer.stop(:configServer)
    ExJSONRPCClientTCP.stop()
  end

  before_each_bench _ do
    val = ["country", "language", "iab", "hour", "minute"]
    |> Enum.reduce(%{}, &(Map.put(&2, &1, pickValue(ExConfServer.getMetadata(:configServer, &1)["distinctvalues"]))))

    {:ok, [config: val]}
  end

  defp pickValue(distinctValues) do
    Enum.at(distinctValues, :rand.uniform(length(distinctValues)) -1 )
  end

  bench "AdServer filtering on 2 targets (1 finite 1 inifinite) on ads 20000 inventory" do
    cfg = bench_context[:config]
    ExJSONRPCClientTCP.filterAd(%{"country" => cfg["country"],
                               "support" => "google.com"})
    :ok
  end
end
