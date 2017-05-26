defmodule Bf2nasm.Optimizer.PassThree do
  use Bf2nasm.Optimizer.Template

  def pattern(processed, [{:incptr, inc1, pos},
                          {:inc, val, _pos2},
                          {:incptr, inc2, pos3}| tail]) when inc1+inc2 != 0 do
    pattern(processed, [{:add_to_offset, {val, inc1}, pos}, {:incptr, inc1+inc2, pos3} | tail])
  end

  def pattern(processed, [{:incptr, 0, pos}| tail]) do
    pattern(processed, tail)
  end

  Bf2nasm.Optimizer.Template.end_use_template
end
