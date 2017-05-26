defmodule Bf2nasm.Parser.Parser do
  alias Bf2nasm.Parser.SourcePos, as: Pos

  def parse_ast(code) do
    {:eof, "", out, _pos} = parse_ast(code, [], _pos.begin())
    out
  end

  def parse_ast("<"<>code, out, _pos) do
    parse_ast(code,
      out ++ [{:incptr, :_, _pos}],
      _pos.next(_pos)
    )
  end

  def parse_ast(">"<>code, out, _pos) do
    parse_ast(code,
      out ++ [{:decptr, :_, _pos}],
      _pos.next(_pos)
    )
  end

  def parse_ast("+"<>code, out, _pos) do
    parse_ast(code,
      out ++ [{:inc, :_, _pos}],
      _pos.next(_pos)
    )
  end

  def parse_ast("-"<>code, out, _pos) do
    parse_ast(code,
      out ++ [{:dec, :_, _pos}],
      _pos.next(_pos)
    )
  end

  def parse_ast("."<>code, out, _pos) do
    parse_ast(code,
      out ++ [{:write, :_, _pos}],
      _pos.next(_pos)
    )
  end

  def parse_ast(","<>code, out, _pos) do
    parse_ast(code,
      out ++ [{:read, :_, _pos}],
      _pos.next(_pos)
    )
  end

  def parse_ast("["<>code, out, _pos) do
    {:close_bracket, rest, inner, new__pos} = parse_ast(code, [], _pos.next(_pos))
    parse_ast(rest,out++[inner], new__pos)
  end

  def parse_ast("]"<>code, out, _pos) do
      {:close_bracket, code, out, _pos.next(_pos)}
  end

  def parse_ast("\n"<>code, out, _pos) do
    parse_ast(code,
      out,
      _pos.new_line(_pos)
    )
  end

  def parse_ast(<<_, code :: binary>>, out, _pos) do
    parse_ast(code,
      out,
      _pos.next(_pos)
    )
  end

  def parse_ast("", out, _pos) do
    {:eof, "", out, _pos}
  end
end
