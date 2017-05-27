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

  # Sub two numbers
  # [->-<]
  # next   --= current
  # current = 0
  def pattern(processed, [[{:inc, -1, pos},
                          {:incptr, offset1, _pos1},
                          {:inc, -1, _pos2},
                          {:incptr, offset2, _pos3}]| tail]) when offset1 == -offset2 do
    pattern(processed, [{:sub_to_next_and_set_to_zero, offset1, pos} | tail])
  end

  # Multiply One
  # [->++<]
  def pattern(processed, [[{:inc, -1, pos},
                          {:incptr, offset1, _pos1},
                          {:inc, factor1, _pos2},
                          {:incptr, offset2, _pos3}]| tail]) when offset1 == -offset2 and factor1 > 1 do
    pattern(processed, [{:multiply_to_next_and_set_to_zero, {offset1, factor1}, pos} | tail])
  end

  # TODO Improve into One
  # Multiply Two
  # [->++<++>>]
  def pattern(processed, [[{:inc, -1, pos},
                          {:incptr, offset1, _pos1},
                          {:inc, factor1, _pos2},
                          {:incptr, offset2, _pos3},
                          {:inc, factor2, _pos4},
                          {:incptr, offset3, _pos5}]| tail])
                          when offset1 + offset2 - offset3 == 0
                              and factor1 > 1
                              and factor2 > 1 do
    pattern(processed, [{:multiply_to_two_and_set_to_zero, {offset1, factor1, offset2, factor2}, pos} | tail])
  end


  Bf2nasm.Optimizer.Template.end_use_template
end
