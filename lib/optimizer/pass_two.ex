defmodule Bf2nasm.Optimizer.PassTwo do
  use Bf2nasm.Optimizer.Template

  # Set to zero
  # [-]
  def pattern(processed, [[{:inc, -1, pos}]| tail]) do
    pattern(processed, [{:set, 0, pos}|tail])
  end

  # Add two numbers
  # [->+<]
  # next   += current
  # current = 0
  def pattern(processed, [[{:inc, -1, pos},
                          {:incptr, offset1, _pos1},
                          {:inc, 1, _pos2},
                          {:incptr, offset2, _pos3}]| tail]) when offset1 == -offset2 do
    pattern(processed, [{:add_to_next_and_set_to_zero, offset1, pos} | tail])
  end

  Bf2nasm.Optimizer.Template.end_use_template
end
