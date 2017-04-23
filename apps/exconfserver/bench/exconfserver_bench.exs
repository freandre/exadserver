# bench/basic_bench.exs
defmodule ExConfServerBench do
  use Benchfella

  bench "ConfServer generating 1000 confs" do
    ExConfServer.start_link(:configServer, {"./test/resources/targetingData.json", 1_000})
    ExConfServer.stop(:configServer)
    :ok
  end

  bench "ConfServer generating 2000 confs" do
    ExConfServer.start_link(:configServer, {"./test/resources/targetingData.json", 2_000})
    ExConfServer.stop(:configServer)
    :ok
  end

  bench "ConfServer generating 5000 confs" do
    ExConfServer.start_link(:configServer, {"./test/resources/targetingData.json", 5_000})
    ExConfServer.stop(:configServer)
    :ok
  end

  bench "ConfServer generating 10000 confs" do
    ExConfServer.start_link(:configServer, {"./test/resources/targetingData.json", 10_000})
    ExConfServer.stop(:configServer)
    :ok
  end

  bench "ConfServer generating 15000 confs" do
    ExConfServer.start_link(:configServer, {"./test/resources/targetingData.json", 15_000})
    ExConfServer.stop(:configServer)
    :ok
  end

  bench "ConfServer generating 20000 confs" do
    ExConfServer.start_link(:configServer, {"./test/resources/targetingData.json", 20_000})
    ExConfServer.stop(:configServer)
    :ok
  end
end
