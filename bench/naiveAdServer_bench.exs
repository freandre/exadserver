# bench/basic_bench.exs
defmodule AdServerBench do
  use Benchfella
  alias ExAdServer.Naive.AdServer, as: NaiveAdServer
  alias ExAdServer.Config.ConfigServer

  @numberOfAds 1000

  setup_all do
    {:ok, configserver} = ConfigServer.start_link({"./test/resources/targetingData.json", @numberOfAds})
    {:ok, adserver} = NaiveAdServer.start_link

    ConfigServer.getAd(configserver)
    |> Enum.each(&NaiveAdServer.loadAd(adserver, &1))

    {:ok, [configServer: configserver, adServer: adserver]}
  end

  bench "Naive filtering on 3 targets on #{@numberOfAds} ads inventory" do
    NaiveAdServer.filterAd(bench_context[:adServer], %{"country" => "FR", "language" => "fr", "support" => "google.com"})
    :ok
  end

  bench "Naive filtering on 4 targets on #{@numberOfAds} ads inventory" do
    NaiveAdServer.filterAd(bench_context[:adServer], %{"hour" => 14, "country" => "FR", "language" => "fr", "support" => "google.com"})
    :ok
  end
end
