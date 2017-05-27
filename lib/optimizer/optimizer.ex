defmodule Bf2nasm.Optimizer do
  def optimize(ast, options) do
    if Keyword.get(options, :no_optimization, false) do
      ast
    else
      ast
      |> Bf2nasm.Optimizer.PassOne.pattern()
      |> Bf2nasm.Optimizer.PassTwo.pattern()
      |> Bf2nasm.Optimizer.PassThree.pattern()
    end
  end
end
