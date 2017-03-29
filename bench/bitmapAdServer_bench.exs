# bench/basic_bench.exs
defmodule BitmapAdServerBench do
  use Benchfella
  alias ExAdServer.Config.ConfigServer
  alias ExAdServer.Bitmap.AdServer, as: BitmapAdServer

  @numberOfAds 1000

  setup_all do
    {:ok, configserver} = ConfigServer.start_link({"./test/resources/targetingData.json", @numberOfAds})
    {:ok, adserver} = BitmapAdServer.start_link(ConfigServer.getMetadata(configserver))

    ConfigServer.getAd(configserver)
    |> Enum.each(&BitmapAdServer.loadAd(adserver, &1))

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

  bench "Bitmap filtering on 2 targets (1 finite 1 inifinite) on #{@numberOfAds} ads inventory" do
    cfg = bench_context[:config]
    BitmapAdServer.filterAd(bench_context[:adServer], %{"country" => cfg["country"],
                                                       "support" => "google.com"})
    :ok
  end

  bench "Bitmap filtering on 3 targets (2 finite 1 inifinite) on #{@numberOfAds} ads inventory" do
    cfg = bench_context[:config]
    BitmapAdServer.filterAd(bench_context[:adServer], %{"country" => cfg["country"],
                                                       "language" => cfg["language"],
                                                       "support" => "google.com"})
    :ok
  end

  bench "Bitmap filtering on 4 targets (3 finite 1 inifinite) on #{@numberOfAds} ads inventory" do
    cfg = bench_context[:config]
    BitmapAdServer.filterAd(bench_context[:adServer], %{"country" => cfg["country"],
                                                       "language" => cfg["language"],
                                                       "hour" => cfg["hour"],
                                                       "support" => "google.com"})
    :ok
  end

  bench "Bitmap filtering on 5 targets (4 finite 1 inifinite) on #{@numberOfAds} ads inventory" do
    cfg = bench_context[:configServer]
    BitmapAdServer.filterAd(bench_context[:adServer], %{"country" => cfg["country"],
                                                       "language" => cfg["language"],
                                                       "hour" => cfg["hour"],
                                                       "minute" => cfg["minute"],
                                                       "support" => "google.com"})
    :ok
  end
end
