defmodule Bf2nasm.Optimizer.PassTwo do

  def pattern(ast) do
     pattern([], ast)
  end

  def pattern(processed, []) do
    processed
  end

  def pattern(processed, [inner | tail]) when is_list(inner) do
    cond do
      is_closed(inner)->
        new_inner = optimize_closed(inner)
        pattern( processed, new_inner ++ tail)
      true  ->
        new_inner = pattern(inner)
        pattern( processed ++ [ new_inner ], tail)
    end
  end

  def pattern(processed, [head | tail]) do
    pattern(processed ++ [ head ], tail)
  end

  defp is_closed(inner) do
    is_closed(inner, 0, 0)
  end

  def is_closed([{:inc, n, _pos}|tail], 0, inc) do
    is_closed(tail, 0, inc+n)
  end

  def is_closed([{:inc, _n, _pos}|tail], pointer_pos, inc) do
    is_closed(tail, pointer_pos, inc)
  end

  def is_closed([{:incptr, n, _pos}|tail], pointer_pos, inc) do
    is_closed(tail, pointer_pos+n, inc)
  end

  def is_closed([], 0, -1) do
    true
  end

  def is_closed(_, _, _) do
    false
  end

  def optimize_closed(inner) do
    env = Map.new()
    optimize_closed(inner, env, 0)
  end

  def optimize_closed(list = [{_cmd, _args, pos} | _], env, offset) do
    optimize_closed(list, env, offset, pos)
  end

  def optimize_closed([{:inc, n, _pos} | tail], env, offset, pos) do
    delta = Map.get(env, offset, 0)
    env   = Map.put(env, offset, delta+n)
    optimize_closed(tail, env, offset, pos)
  end

  def optimize_closed([{:incptr, n, _pos} | tail], env, offset, pos) do
    optimize_closed(tail, env, offset+n, pos)
  end

  def optimize_closed([], env = %{0 => -1}, 0, pos) do
    (env
     |> Map.to_list()
     |> Enum.with_index()
     |> Enum.flat_map(fn x ->
       env_to_instr(x, pos)
     end)
    )++ [{:set, 0, pos}]
  end

  defp env_to_instr({{0, -1}, _}, _pos) do
    []
  end

  defp env_to_instr({{offset, 1}, _}, pos) do
    [{:add_value_to, offset, pos}]
  end

  defp env_to_instr({{offset, -1}, _}, pos) do
    [{:sub_value_to, offset, pos}]
  end

  defp env_to_instr({{offset, n}, i}, pos) do
    [{:add_multiple_of_value_to, {offset, n, rem(i,2)}, pos}]
  end
end
