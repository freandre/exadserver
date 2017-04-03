defmodule TypedSetAdServerTest do
  use AdServerCase, async: true
  alias ExAdServer.TypedSet.AdServer, as: TypedSetAdServer
  alias ExAdServer.Config.ConfigServer

  
  test "That our adServer filter ads properly", context do
    {:ok, configserver} = ConfigServer.start_link({"./test/resources/simpleTargetingData.json", 0})
    {:ok, adserver} = TypedSetAdServer.start_link(ConfigServer.getMetadata(configserver))

    Enum.each(context.simpleAdsData, &TypedSetAdServer.loadAd(adserver, &1))

    Enum.each(context.adsFilterData,
              fn(%{"request" => request, "expected" => expected}) ->
                  returned = TypedSetAdServer.filterAd(adserver, request)
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
