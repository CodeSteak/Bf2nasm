defmodule Bf2nasm do
  alias Bf2nasm.Parser.Parser, as: Parser
  alias Bf2nasm.Compiler.X86_64, as: Compiler

  def main([file]) do
    res = case File.read(file) do
      {:ok, content} -> Parser.parse_ast(content)
      {:error, r} -> IO.inspect(r)
    end
    #IO.inspect res
    [prefix, "bf"] = String.split(file, ".")
    res |> Compiler.compile(prefix)
    :ok
  end

  def start(_type, _args) do
    main(System.argv())
    System.halt()
  end
end
