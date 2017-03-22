defmodule ConfigServerTest do
  use ExUnit.Case, async: true
  alias ExAdServer.Config.ConfigServer

  test "UnitTestConfig init" do
    number = 10
    {:ok, configserver} = ConfigServer.start_link({"./test/resources/targetingData.json", number})
    returned = length(ConfigServer.getAd(configserver))
    assert(returned == number,
          """
          Number of generated ad and returned ones are not identical
          Expected:
          #{number}
          Had:
          #{returned}
          """)
  end

  test "UnitTestConfig MetaData" do
    number = 1
    {:ok, configserver} = ConfigServer.start_link({"./test/resources/targetingData.json", number})
    returned = ConfigServer.getMetadata(configserver, "support")
    assert(returned["distinctvalues"] == nil,
          """
          Support is a not finite type so distinctvalues field is not returned
          Had:
          #{inspect(returned)}
          """)
  end
end
