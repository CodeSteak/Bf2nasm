defmodule Bf2nasm do
  alias Bf2nasm.Parser.Parser, as: Parser
  alias Bf2nasm.Compiler.X86_64, as: Compiler

  def main([file]) do
    res = case File.read(file) do
      {:ok, content} -> Parser.parse_ast(content)
      {:error, r} -> IO.inspect(r)
    end

    [prefix, "bf"] = String.split(file, ".")
    res |> Compiler.compile(prefix)
    :ok
  end

  def main(_) do
    IO.puts "usage: bf2nasm <file.bf>"
  end
end
