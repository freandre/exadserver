defmodule ExconfserverTest do
  use ExUnit.Case, async: true

  test "UnitTestConfig init", context do
    number = 10
    {:ok, configserver} = ExConfServer.start_link(context.test, {"./test/resources/simpleTargetingData.json", number})
    returned = length(ExConfServer.getAd(configserver))
    assert(returned == number,
          """
          Number of generated ad and returned ones are not identical
          Expected:
          #{number}
          Had:
          #{returned}
          """)
  end

  test "UnitTestConfig MetaData", context do
    number = 1
    {:ok, configserver} = ExConfServer.start_link(context.test, {"./test/resources/simpleTargetingData.json", number})
    returned = ExConfServer.getMetadata(configserver, "support")
    assert(returned["distinctvalues"] == nil,
          """
          Support is a not finite type so distinctvalues field is not returned
          Had:
          #{inspect(returned)}
          """)
  end

  test "Stop adServer properly", context do
    number = 1
    {:ok, configserver} = ExConfServer.start_link(context.test, {"./test/resources/simpleTargetingData.json", number})

    assert(:ok == ExConfServer.stop(configserver),
          """
          Unable to stop properly the server
          """)
  end
end
