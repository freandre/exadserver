# bench/basic_bench.exs
defmodule ExJSONRPCClientBench do
  use Benchfella

  setup_all do
    Application.ensure_all_started(:shackle)
    ExJSONRPCClient.start("localhost", 8181)

    # ok just use the local instance to generate data from metadata
    # we should definitely use distribution here
    ExConfServer.start_link(:configServer, {"./test/resources/targetingData.json", 0})
  end

  teardown_all _ do
    ExConfServer.stop(:configServer)
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
    ExJSONRPCClient.filterAd(%{"country" => cfg["country"],
                               "support" => "google.com"})
    :ok
  end
end
