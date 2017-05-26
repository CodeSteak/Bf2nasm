defmodule Bf2nasm.Parser.Parser do
  alias Bf2nasm.Parser.SourcePos, as: Pos

  def parse_ast(code) do
    {:eof, "", out, pos} = parse_ast(code, [], Pos.begin())
    out
  end

  def parse_ast("<"<>code, out, pos) do
    parse_ast(code,
      out ++ [{:incptr, :_, pos}],
      Pos.next(pos)
    )
  end

  def parse_ast(">"<>code, out, pos) do
    parse_ast(code,
      out ++ [{:decptr, :_, pos}],
      Pos.next(pos)
    )
  end

  def parse_ast("+"<>code, out, pos) do
    parse_ast(code,
      out ++ [{:inc, :_, pos}],
      Pos.next(pos)
    )
  end

  def parse_ast("-"<>code, out, pos) do
    parse_ast(code,
      out ++ [{:dec, :_, pos}],
      Pos.next(pos)
    )
  end

  def parse_ast("."<>code, out, pos) do
    parse_ast(code,
      out ++ [{:write, :_, pos}],
      Pos.next(pos)
    )
  end

  def parse_ast(","<>code, out, pos) do
    parse_ast(code,
      out ++ [{:read, :_, pos}],
      Pos.next(pos)
    )
  end

  def parse_ast("["<>code, out, pos) do
    {:close_bracket, rest, inner, new_pos} = parse_ast(code, [], Pos.next(pos))
    parse_ast(rest,out++[inner], new_pos)
  end

  def parse_ast("]"<>code, out, pos) do
      {:close_bracket, code, out, Pos.next(pos)}
  end

  def parse_ast("\n"<>code, out, pos) do
    parse_ast(code,
      out,
      Pos.new_line(pos)
    )
  end

  def parse_ast(<<_, code :: binary>>, out, pos) do
    parse_ast(code,
      out,
      Pos.next(pos)
    )
  end

  def parse_ast("", out, pos) do
    {:eof, "", out, pos}
  end
end
