defmodule ExAdServerTest do
  use ExAdServerCase, async: true

  test "That our adServer can load some basic data", context do
    {:ok, configserver} = ExConfServer.start_link(:confserver, {"./test/resources/simpleTargetingData.json", 0})
    {:ok, adserver} = ExAdServer.start_link(:adserver, ExConfServer.getMetadata(configserver))

    Enum.each(context.simpleAdsData, &ExAdServer.loadAd(adserver, &1))
    Enum.each(context.simpleAdsData,
              fn(ad) ->
                returned = ExAdServer.getAd(adserver, ad["adid"])
                assert(returned == ad,
                      """
                      Ads are not identical
                      Expected:
                      #{inspect(ad)}
                      Had:
                      #{inspect(returned)}
                      """)
              end)
    ExAdServer.stop(adserver)
    ExConfServer.stop(configserver)
  end

  test "That our adServer can update some basic data", context do
    {:ok, configserver} = ExConfServer.start_link(:confserver, {"./test/resources/simpleTargetingData.json", 0})
    {:ok, adserver} = ExAdServer.start_link(:adserver, ExConfServer.getMetadata(configserver))

    Enum.each(context.simpleAdsData, &ExAdServer.loadAd(adserver, &1))

    [ad | _] = context.simpleAdsData
    adMod = Map.put(ad, "test", "test")

    ExAdServer.loadAd(adserver, adMod)
    returned = ExAdServer.getAd(adserver, ad["adid"])

    assert(returned != ad,
          """
          Ads are identical
          Expected:
          #{inspect(adMod)}
          Had:
          #{inspect(returned)}
          """)
    ExAdServer.stop(adserver)
    ExConfServer.stop(configserver)
  end

  test "That our adServer returns :notfound", context do
    {:ok, configserver} = ExConfServer.start_link(:confserver, {"./test/resources/simpleTargetingData.json", 0})
    {:ok, adserver} = ExAdServer.start_link(:adserver, ExConfServer.getMetadata(configserver))

    Enum.each(context.simpleAdsData, &ExAdServer.loadAd(adserver, &1))

    returned = ExAdServer.getAd(adserver, 42)

    assert(returned == :notfound,
          """
          Unable to handle :notfound
          Expected:
          :notfound
          Had:
          #{inspect(returned)}
          """)
    ExAdServer.stop(adserver)
    ExConfServer.stop(configserver)
  end

  test "That our adServer filter ads properly", context do
    {:ok, configserver} = ExConfServer.start_link(:confserver, {"./test/resources/simpleTargetingData.json", 0})
    {:ok, adserver} = ExAdServer.start_link(:adserver, ExConfServer.getMetadata(configserver))

    Enum.each(context.simpleAdsData, &ExAdServer.loadAd(adserver, &1))

    Enum.each(context.adsFilterData,
              fn(%{"request" => request, "expected" => expected}) ->
                  returned = ExAdServer.filterAd(adserver, request)
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
    ExAdServer.stop(adserver)
    ExConfServer.stop(configserver)
  end

  test "Stop adServer properly" do
    {:ok, configserver} = ExConfServer.start_link(:confserver, {"./test/resources/simpleTargetingData.json", 0})
    {:ok, adserver} = ExAdServer.start_link(:adserver, ExConfServer.getMetadata(configserver))

    assert(:ok == ExAdServer.stop(adserver),
          """
          Unable to stop properly the server
          """)
  end
end
