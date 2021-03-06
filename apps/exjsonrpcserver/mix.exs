defmodule ExJSONRPCServer.Mixfile do
  use Mix.Project

  def project do
    [app: :exjsonrpcserver,
     version: "0.1.0",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger, :jsonrpc2, :poison, :ranch, :plug, :cowboy],
     mod: {ExJSONRPCServer.Application, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:my_app, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:exadserver, in_umbrella: true},
      {:jsonrpc2, git: "https://github.com/freandre/jsonrpc2-elixir.git"},
      {:poison, "~> 3.1"},
      {:ranch, "~> 1.3"},
      {:plug, "~> 1.3"},
      {:cowboy, "~> 1.1"},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:credo, "~> 0.7", only: [:dev, :test]}
    ]
  end
end
