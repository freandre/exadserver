# bench/basic_bench.exs
defmodule ExJSONRPCClientTCPBench do
  use Benchfella

  ## This bench must be run with an additional iex -s mix process
  ## Do not forget to load a set of conf before benchmarking the rpc
  ## Enum.each(ExConfServer.getConf(ConfServer), &(ExAdServer.loadAd(AdServer, &1)))

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
    Enum.at(distinctValues, :rand.uniform(length(distinctValues)) - 1)
  end

  bench "Filtering on 6 targets on 5000 ads inventory " do
    cfg = bench_context[:config]
    ExJSONRPCClientTCP.filterAd(%{"country" => cfg["country"],
                                  "language" => cfg["language"],
                                  "iab" => cfg["iab"],
                                  "hour" => cfg["hour"],
                                  "minute" => cfg["minute"],
                                  "support" => "google.com"})
    :ok
  end
end
