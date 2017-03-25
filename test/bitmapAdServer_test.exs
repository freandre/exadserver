defmodule BitmapAdServerTest do
  use AdServerCase, async: true
  alias ExAdServer.Bitmap.AdServer, as: BitmapAdServer
  alias ExAdServer.Config.ConfigServer

  test "That our adServer can load some basic data", context do
    number = 1
    {:ok, configserver} = ConfigServer.start_link({"./test/resources/targetingData.json", number})
    {:ok, adserver} = BitmapAdServer.start_link(ConfigServer.getMetadata(configserver))

    Enum.each(context.simpleAdsData, &BitmapAdServer.loadAd(adserver, &1))
    Enum.each(context.simpleAdsData,
              fn(ad) ->
                returned = BitmapAdServer.getAd(adserver, ad["adid"])
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
end
