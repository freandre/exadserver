# bench/basic_bench.exs
defmodule ExAdServerBench do
  use Benchfella

  @numberOfAds 20000

  setup_all do
    {:ok, configserver} = ExConfServer.start_link(:configServer, {"./test/resources/targetingData.json", @numberOfAds})
    {:ok, adserver} = ExAdServer.start_link(:adServer, ExConfServer.getMetadata(configserver))

    ExConfServer.getAd(configserver)
    |> Enum.each(&ExAdServer.loadAd(adserver, &1))

    {:ok, [configServer: configserver, adServer: adserver]}
  end

  teardown_all keywords do
    ExAdServer.stop(keywords[:adServer])
    ExConfServer.stop(keywords[:configServer])
  end

  before_each_bench bench_context do
    config = bench_context[:configServer]

    val = ["country", "language", "iab", "hour", "minute"]
    |> Enum.reduce(%{}, &(Map.put(&2, &1, pickValue(ExConfServer.getMetadata(config, &1)["distinctvalues"]))))

    {:ok, [config: val, adServer: bench_context[:adServer]]}
  end

  defp pickValue(distinctValues) do
    Enum.at(distinctValues, :rand.uniform(length(distinctValues)) -1 )
  end

  bench "AdServer filtering on 2 targets (1 finite 1 inifinite) on #{@numberOfAds} ads inventory" do
    cfg = bench_context[:config]
    ExAdServer.filterAd(bench_context[:adServer], %{"country" => cfg["country"],
                                                    "support" => "google.com"})
    :ok
  end

  bench "AdServer filtering on 3 targets (2 finite 1 inifinite) on #{@numberOfAds} ads inventory" do
    cfg = bench_context[:config]
    ExAdServer.filterAd(bench_context[:adServer], %{"country" => cfg["country"],
                                                    "language" => cfg["language"],
                                                    "support" => "google.com"})
    :ok
  end

  bench "AdServer filtering on 4 targets (3 finite 1 inifinite) on #{@numberOfAds} ads inventory" do
    cfg = bench_context[:config]
    ExAdServer.filterAd(bench_context[:adServer], %{"country" => cfg["country"],
                                                    "language" => cfg["language"],
                                                    "hour" => cfg["hour"],
                                                    "support" => "google.com"})
    :ok
  end

  bench "AdServer filtering on 5 targets (4 finite 1 inifinite) on #{@numberOfAds} ads inventory" do
    cfg = bench_context[:configServer]
    ExAdServer.filterAd(bench_context[:adServer], %{"country" => cfg["country"],
                                                    "language" => cfg["language"],
                                                    "hour" => cfg["hour"],
                                                    "minute" => cfg["minute"],
                                                    "support" => "google.com"})
    :ok
  end

  bench "AdServer filtering on 6 targets (5 finite 1 inifinite) on #{@numberOfAds} ads inventory" do
    cfg = bench_context[:configServer]
    ExAdServer.filterAd(bench_context[:adServer], %{"country" => cfg["country"],
                                                    "language" => cfg["language"],
                                                    "iab" => cfg["iab"],
                                                    "hour" => cfg["hour"],
                                                    "minute" => cfg["minute"],
                                                    "support" => "google.com"})
    :ok
  end
end
