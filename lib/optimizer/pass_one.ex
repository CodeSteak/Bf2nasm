defmodule Bf2nasm.Optimizer.PassOne do
  use Bf2nasm.Optimizer.Template

  def pattern(processed, [{:incptr, v1, pos1}, {:incptr, v2, _pos2} | tail]) do
     pattern(processed, [{:incptr, v1+v2, pos1} | tail])
  end

  def pattern(processed, [{:inc, v1, pos1}, {:inc, v2, _pos2} | tail]) do
     pattern(processed, [{:inc, v1+v2, pos1} | tail])
  end

  def pattern(processed, [{:inc, 0, pos}| tail]) do
    pattern(processed, tail)
  end

  def pattern(processed, [{:incptr, 0, pos}| tail]) do
    pattern(processed, tail)
  end

  Bf2nasm.Optimizer.Template.end_use_template
end
