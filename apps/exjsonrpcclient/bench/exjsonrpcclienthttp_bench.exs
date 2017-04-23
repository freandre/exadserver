# bench/basic_bench.exs
defmodule ExJSONRPCClientHTTPBench do
  use Benchfella

  ## This bench must be run with an additional iex -s mix process
  ## Do not forget to load a set of conf before benchmarking the rpc
  ## Enum.each(ExConfServer.getConf(ConfServer), &(ExAdServer.loadAd(AdServer, &1)))

  @address "http://localhost:8080/"

  setup_all do
    Application.ensure_all_started(:hackney)
    Application.ensure_all_started(:jsonrpc2)

    ExJSONRPCClientHTTP.hello(@address, "Bench")

    # ok just use the local instance to generate data from metadata
    # we should definitely use distribution here
    ExConfServer.start_link(:configServer, {"./test/resources/targetingData.json", 0})

    {:ok, []}
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
    Enum.at(distinctValues, :rand.uniform(length(distinctValues)) - 1)
  end

  bench "Filtering on 6 targets on 5000 ads inventory " do
    cfg = bench_context[:config]
    ExJSONRPCClientHTTP.filterAd(@address,  %{"country" => cfg["country"],
                                              "language" => cfg["language"],
                                              "iab" => cfg["iab"],
                                              "hour" => cfg["hour"],
                                              "minute" => cfg["minute"],
                                              "support" => "google.com"})
    :ok
  end

end
