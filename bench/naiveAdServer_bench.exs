# bench/basic_bench.exs
defmodule NaiveAdServerBench do
  use Benchfella
  alias ExAdServer.Config.ConfigServer
  alias ExAdServer.Naive.AdServer, as: NaiveAdServer

  @numberOfAds 1000

  setup_all do
    {:ok, configserver} = ConfigServer.start_link({"./test/resources/targetingData.json", @numberOfAds})
    {:ok, adserver} = NaiveAdServer.start_link

    ConfigServer.getAd(configserver)
    |> Enum.each(&NaiveAdServer.loadAd(adserver, &1))

    {:ok, [configServer: configserver, adServer: adserver]}
  end

  before_each_bench bench_context do
    config = bench_context[:configServer]

    val = ["country", "language", "hour", "minute"]
    |> Enum.reduce(%{}, &(Map.put(&2, &1, pickValue(ConfigServer.getMetadata(config, &1)["distinctvalues"]))))

    {:ok, [config: val, adServer: bench_context[:adServer]]}
  end

  defp pickValue(distinctValues) do
    Enum.at(distinctValues, :rand.uniform(length(distinctValues)) -1 )
  end

  bench "Naive filtering on 2 targets on #{@numberOfAds} ads inventory" do
    cfg = bench_context[:config]
    NaiveAdServer.filterAd(bench_context[:adServer], %{"country" => cfg["country"],
                                                       "support" => "google.com"})
    :ok
  end

  bench "Naive filtering on 3 targets on #{@numberOfAds} ads inventory" do
    cfg = bench_context[:config]
    NaiveAdServer.filterAd(bench_context[:adServer], %{"country" => cfg["country"],
                                                       "language" => cfg["country"],
                                                       "support" => "google.com"})
    :ok
  end

  bench "Naive filtering on 4 targets on #{@numberOfAds} ads inventory" do
    cfg = bench_context[:config]
    NaiveAdServer.filterAd(bench_context[:adServer], %{"country" => cfg["country"],
                                                       "language" => cfg["language"],
                                                       "hour" => cfg["hour"],
                                                       "support" => "google.com"})
    :ok
  end

  bench "Naive filtering on 5 targets on #{@numberOfAds} ads inventory" do
    cfg = bench_context[:config]
    NaiveAdServer.filterAd(bench_context[:adServer], %{"country" => cfg["country"],
                                                       "language" => cfg["language"],
                                                       "hour" => cfg["hour"],
                                                       "minute" => cfg["minute"],
                                                       "support" => "google.com"})
    :ok
  end
end
