defmodule  ExAdServer.Config.BehaviorConfigProcessor do
  # init with a single parameter
  @callback init(any) :: any

  # find an ad by state / id
  @callback getAd(any, any) :: any
end
