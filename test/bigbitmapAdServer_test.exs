defmodule BigBitmapAdServerTest do
  use AdServerCase, async: true
  alias ExAdServer.BigBitmap.AdServer, as: BigBitmapAdServer
  alias ExAdServer.Config.ConfigServer

  test "That our adServer can load some basic data", context do
    number = 1
    {:ok, configserver} = ConfigServer.start_link({"./test/resources/targetingData.json", number})
    {:ok, adserver} = BigBitmapAdServer.start_link(ConfigServer.getMetadata(configserver))

    Enum.each(context.simpleAdsData, &BigBitmapAdServer.loadAd(adserver, &1))
    Enum.each(context.simpleAdsData,
              fn(ad) ->
                returned = BigBitmapAdServer.getAd(adserver, ad["adid"])
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

  test "That our adServer filter ads properly", context do
    number = 1
    {:ok, configserver} = ConfigServer.start_link({"./test/resources/targetingData.json", number})
    {:ok, adserver} = BigBitmapAdServer.start_link(ConfigServer.getMetadata(configserver))

    Enum.each(context.simpleAdsData, &BigBitmapAdServer.loadAd(adserver, &1))

    Enum.each(context.adsFilterData,
              fn(%{"request" => request, "expected" => expected}) ->
                  returned = BigBitmapAdServer.filterAd(adserver, request)
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
