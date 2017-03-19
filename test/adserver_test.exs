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

  test "That our adServer can load some basic data", context do
    {:ok, adserver} = Server.AdServer.start_link
    Enum.each(context.simpleAdsData, &Server.AdServer.loadAd(adserver, &1))
    Enum.each(context.simpleAdsData,
              fn(ad) ->
                returned = Server.AdServer.getAd(adserver, ad["adid"])
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
    {:ok, adserver} = Server.AdServer.start_link
    Enum.each(context.simpleAdsData, &Server.AdServer.loadAd(adserver, &1))

    [ad | _] = context.simpleAdsData
    adMod = Map.put(ad, "test", "test")

    Server.AdServer.loadAd(adserver, adMod)
    returned = Server.AdServer.getAd(adserver, ad["adid"])

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
    {:ok, adserver} = Server.AdServer.start_link
    Enum.each(context.simpleAdsData, &Server.AdServer.loadAd(adserver, &1))

    returned = Server.AdServer.getAd(adserver, 42)

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
    {:ok, adserver} = Server.AdServer.start_link
    Enum.each(context.simpleAdsData, &Server.AdServer.loadAd(adserver, &1))

    {status, reason} = Server.AdServer.filterAd(adserver, %{"anything" => "anything"})

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
    {:ok, adserver} = Server.AdServer.start_link
    Enum.each(context.simpleAdsData, &Server.AdServer.loadAd(adserver, &1))

    Enum.each(context.adsFilterData,
              fn(%{"request" => request, "expected" => expected}) ->
                  returned = Server.AdServer.filterAd(adserver, request)
                  assert(returned == expected,
                        """
                        Unable to handle filtering
                        Expected:
                        #{inspect(expected)}
                        Had:
                        #{inspect(returned)}
                        """)
              end)
  end
end
