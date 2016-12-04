defmodule Lambduh.Main do
  @moduledoc """
  Elixir on AWS Lambda.
  """

  def main(_args) do
    stream = IO.stream(:stdio, :line)
    for line <- stream, into: stream do
      """
      {"value":{"hello":""}}
      """
    end
  end
end
