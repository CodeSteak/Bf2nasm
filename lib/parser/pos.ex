defmodule Bf2nasm.Parser.SourcePos do

  def begin do
     [line: 1, column: 1, pos: 1]
  end

  def next([line: line, column: column, pos: pos]) do
     [line: line, column: column+1, pos: pos+1]
  end

  def new_line([line: line, column: _column, pos: pos]) do
     [line: line+1, column: 1, pos: pos+1]
  end

end
