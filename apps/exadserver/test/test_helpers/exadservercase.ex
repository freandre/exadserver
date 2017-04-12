defmodule ExAdServerCase do
  use ExUnit.CaseTemplate

  setup_all do
    simpleAdsData = File.read!("./test/resources/simpleAds.json")
                    |> Poison.decode!
    adsFilterData = File.read!("./test/resources/adsFilter.json")
                    |> Poison.decode!
    {:ok, simpleAdsData: simpleAdsData, adsFilterData: adsFilterData}
  end
end
