# bench/basic_bench.exs
defmodule AdServerBench do
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

  defp pickValue(distinctValues) do
    Enum.at(distinctValues, :rand.uniform(length(distinctValues)) -1 )
  end

  bench "Naive filtering on 2 targets on #{@numberOfAds} ads inventory" do
    cfg = bench_context[:configServer]
    NaiveAdServer.filterAd(bench_context[:adServer], %{"country" => pickValue(ConfigServer.getMetadata(cfg, "country")["distinctvalues"]),
                                                       "support" => "google.com"})
    :ok
  end

  bench "Naive filtering on 3 targets on #{@numberOfAds} ads inventory" do
    cfg = bench_context[:configServer]
    NaiveAdServer.filterAd(bench_context[:adServer], %{"country" => pickValue(ConfigServer.getMetadata(cfg, "country")["distinctvalues"]),
                                                       "language" => pickValue(ConfigServer.getMetadata(cfg, "language")["distinctvalues"]),
                                                       "support" => "google.com"})
    :ok
  end

  bench "Naive filtering on 4 targets on #{@numberOfAds} ads inventory" do
    cfg = bench_context[:configServer]
    NaiveAdServer.filterAd(bench_context[:adServer], %{"country" => pickValue(ConfigServer.getMetadata(cfg, "country")["distinctvalues"]),
                                                       "language" => pickValue(ConfigServer.getMetadata(cfg, "language")["distinctvalues"]),
                                                       "hour" => pickValue(ConfigServer.getMetadata(cfg, "hour")["distinctvalues"]),
                                                       "support" => "google.com"})
    :ok
  end

  bench "Naive filtering on 5 targets on #{@numberOfAds} ads inventory" do
    cfg = bench_context[:configServer]
    NaiveAdServer.filterAd(bench_context[:adServer], %{"country" => pickValue(ConfigServer.getMetadata(cfg, "country")["distinctvalues"]),
                                                       "language" => pickValue(ConfigServer.getMetadata(cfg, "language")["distinctvalues"]),
                                                       "hour" => pickValue(ConfigServer.getMetadata(cfg, "hour")["distinctvalues"]),
                                                       "minute" => pickValue(ConfigServer.getMetadata(cfg, "hour")["distinctvalues"]),
                                                       "support" => "google.com"})
    :ok
  end
end
