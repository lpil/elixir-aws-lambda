defmodule Lambduh.Mixfile do
  use Mix.Project

  def project do
    [app: :lambduh,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     escript: escript()]
  end

  def application do
    [applications: [:logger]]
  end

  def escript do
    [main_module: Lambduh.Main,
     name: "main"]
  end

  defp deps do
    []
  end
end
