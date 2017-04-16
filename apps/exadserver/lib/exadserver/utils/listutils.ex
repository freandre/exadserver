defmodule ExAdServer.Utils.ListUtils do
  @moduledoc """
  List manipulation utility module.
  """

  @doc """
  Intersect two lists.
  Pay attention tu duplicates !!!!
  """
  def intersect(a, b), do: a -- (a -- b)

end
