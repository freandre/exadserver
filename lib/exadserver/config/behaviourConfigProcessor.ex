defmodule  ExAdServer.Config.BehaviorConfigProcessor do
  ## init with a single parameter
  @callback init(any) :: any

  ## find an ad by state / id
  ## :all can be provided to get a full list
  @callback getAd(any, String.t | Atom.t) :: any

  ## get target metadata based on state / target name
  ## :all can be provided to get a full list of {target name / metadata}
  @callback getMetadata(any, String.t | Atom.t) :: any
end
