defmodule Bf2nasm do
  alias Bf2nasm.Parser, as: Parser
  alias Bf2nasm.Compiler.X86_64, as: Compiler
  alias Bf2nasm.Optimizer, as: Optimizer

  def main([file]) do
    res = case File.read(file) do
      {:ok, content} -> Parser.parse_ast(content)
      {:error, r} -> IO.inspect(r)
    end

    [prefix, "bf"] = String.split(file, ".")
    res
     |> Optimizer.optimize()
     |> Compiler.compile(prefix)
    :ok
  end

  def main(_) do
    IO.puts "usage: bf2nasm <file.bf>"
  end
end
