defmodule Bf2nasm.Compiler do
  def compile(ast, %{:target => "x86_64"} = options) do
    Bf2nasm.Compiler.X86_64.compile(ast, options)
  end

  def compile(_ast, %{:target => target}) do
    throw "Target '#{target}' is not supported."
  end
end
