defmodule Bf2nasm.Optimizer do

  def optimize(ast) do
    ast
    |> pattern()
  end

  #optimize by pattern matching
  def pattern(ast) do
     pattern([], ast)
  end

  def pattern(processed, []) do
    processed
  end

  def pattern(processed, [{:incptr, v1, pos1}, {:incptr, v2, _pos2} | tail]) do
     pattern(processed, [{:incptr, v1+v2, pos1} | tail])
  end

  def pattern(processed, [{:inc, v1, pos1}, {:inc, v2, _pos2} | tail]) do
     pattern(processed, [{:inc, v1+v2, pos1} | tail])
  end

  def pattern(processed, [[{:inc, -1, pos}]| tail]) do
    pattern(processed++[{:set, 0, pos}], tail)
  end

  def pattern(processed, [inner | tail]) when is_list(inner) do
     pattern( processed ++ [ pattern(inner) ], tail)
  end

  def pattern(processed, [head|tail]) do
    pattern(processed++[head], tail)
  end
end
