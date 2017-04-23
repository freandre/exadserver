defmodule ExAdServerCase do
  @moduledoc """
  Ad Server module for unti testing. Make some testing data available
  """

  use ExUnit.CaseTemplate

  setup_all do
    simple_ads_data = "./test/resources/simpleAds.json"
                    |> File.read!
                    |> Poison.decode!
    ads_filter_data = "./test/resources/adsFilter.json"
                    |> File.read!
                    |> Poison.decode!
    {:ok, simpleAdsData: simple_ads_data, adsFilterData: ads_filter_data}
  end
end
