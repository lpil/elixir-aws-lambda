defmodule Hello.Mixfile do
  use Mix.Project

  def project do
    [app: :hello,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger],
     mod: {Hello, []}]
  end

  defp deps do
    [# Release build lib
     {:distillery, "~> 0.0", only: [:dev]},
     # JSON decoder
     {:poison, "~> 3.0"}]
  end
end
