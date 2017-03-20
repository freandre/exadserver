defmodule AdServerCase do
  use ExUnit.CaseTemplate

  setup_all do
    simpleAdsData = File.read!("./test/resources/simpleAds.json") |>
                    Poison.decode!
    adsFilterData = File.read!("./test/resources/adsFilter.json") |>
                    Poison.decode!
    {:ok, simpleAdsData: simpleAdsData, adsFilterData: adsFilterData}
  end
end

defmodule AdServerTest do
  use AdServerCase, async: true
  alias ExAdServer.Naive.AdServer, as: NaiveAdServer

  test "That our adServer can load some basic data", context do
    {:ok, adserver} = NaiveAdServer.start_link
    Enum.each(context.simpleAdsData, &NaiveAdServer.loadAd(adserver, &1))
    Enum.each(context.simpleAdsData,
              fn(ad) ->
                returned = NaiveAdServer.getAd(adserver, ad["adid"])
                assert(returned == ad,
                      """
                      Ads are not identical
                      Expected:
                      #{inspect(ad)}
                      Had:
                      #{inspect(returned)}
                      """)
              end
            )
  end

  test "That our adServer can update some basic data", context do
    {:ok, adserver} = NaiveAdServer.start_link
    Enum.each(context.simpleAdsData, &NaiveAdServer.loadAd(adserver, &1))

    [ad | _] = context.simpleAdsData
    adMod = Map.put(ad, "test", "test")

    NaiveAdServer.loadAd(adserver, adMod)
    returned = NaiveAdServer.getAd(adserver, ad["adid"])

    assert(returned != ad,
          """
          Ads are identical
          Expected:
          #{inspect(adMod)}
          Had:
          #{inspect(returned)}
          """)
  end

  test "That our adServer returns :notfound", context do
    {:ok, adserver} = NaiveAdServer.start_link
    Enum.each(context.simpleAdsData, &NaiveAdServer.loadAd(adserver, &1))

    returned = NaiveAdServer.getAd(adserver, 42)

    assert(returned == :notfound,
          """
          Unable to handle :notfound
          Expected:
          :notfound
          Had:
          #{inspect(returned)}
          """)
  end

  test "That our adServer filter check args", context do
    {:ok, adserver} = NaiveAdServer.start_link
    Enum.each(context.simpleAdsData, &NaiveAdServer.loadAd(adserver, &1))

    {status, reason} = NaiveAdServer.filterAd(adserver, %{"anything" => "anything"})

    assert(status == :badArgument,
          """
          Unable to handle :notfound
          Expected:
          :badArgument
          Had:
          #{status}
          #{reason}
          """)
  end

  test "That our adServer filter ads properly", context do
    {:ok, adserver} = NaiveAdServer.start_link
    Enum.each(context.simpleAdsData, &NaiveAdServer.loadAd(adserver, &1))

    Enum.each(context.adsFilterData,
              fn(%{"request" => request, "expected" => expected}) ->
                  returned = NaiveAdServer.filterAd(adserver, request)
                  assert(returned == MapSet.new(expected),
                        """
                        Unable to handle filtering on request
                        #{inspect(request)}
                        Expected:
                        #{inspect(expected)}
                        Had:
                        #{inspect(returned)}
                        """)
              end)
  end
end
