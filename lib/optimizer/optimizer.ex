defmodule Bf2nasm.Optimizer do
  def optimize(ast) do
    ast
    |> Bf2nasm.Optimizer.PassOne.pattern()
    |> Bf2nasm.Optimizer.PassTwo.pattern()
    |> Bf2nasm.Optimizer.PassThree.pattern()
  end
end
