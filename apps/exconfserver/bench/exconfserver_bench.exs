# bench/basic_bench.exs
defmodule ExConfServerBench do
  use Benchfella

  bench "ConfServer generating 1000 confs" do
    ExConfServer.start_link(:configServer, {"./test/resources/targetingData.json", 1000})
    ExConfServer.stop(:configServer)
    :ok
  end

  bench "ConfServer generating 2000 confs" do
    ExConfServer.start_link(:configServer, {"./test/resources/targetingData.json", 2000})
    ExConfServer.stop(:configServer)
    :ok
  end

  bench "ConfServer generating 5000 confs" do
    ExConfServer.start_link(:configServer, {"./test/resources/targetingData.json", 5000})
    ExConfServer.stop(:configServer)
    :ok
  end

  bench "ConfServer generating 10000 confs" do
    ExConfServer.start_link(:configServer, {"./test/resources/targetingData.json", 10000})
    ExConfServer.stop(:configServer)
    :ok
  end

  bench "ConfServer generating 15000 confs" do
    ExConfServer.start_link(:configServer, {"./test/resources/targetingData.json", 15000})
    ExConfServer.stop(:configServer)
    :ok
  end

  bench "ConfServer generating 20000 confs" do
    ExConfServer.start_link(:configServer, {"./test/resources/targetingData.json", 20000})
    ExConfServer.stop(:configServer)
    :ok
  end
end
