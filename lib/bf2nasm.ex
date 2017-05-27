defmodule Bf2nasm do
  alias Bf2nasm.Parser, as: Parser
  alias Bf2nasm.Compiler.X86_64, as: Compiler
  alias Bf2nasm.Optimizer, as: Optimizer

  def main(args) do
    case parse_args(args) do
      {:ok, {input, options}} ->
        if Keyword.get(options, :help) do
          help()
        else
          run(input, options)
        end
      _ ->
        help()
    end
  end

  def run(inputfile, options) do
    res = case File.read(inputfile) do
      {:ok, content} ->
        Parser.parse_ast(content)
      {:error, r} ->
        IO.warn("Could not open inputfile #{inspect(r)}")
        System.halt(1)
    end

    options = if Keyword.has_key?(options, :output) do
      options
    else
      Keyword.put(options, :output, inputfile<>"."<>Keyword.get(options, :target, "x86_64"))
    end

    res
    |> Optimizer.optimize(options)
    |> Compiler.compile(options)
    :ok
  end

  def help do
    IO.puts """
      usage: bf2nasm [options] <inputfile>"

      options:
        --help, -h
                      Print this help page.
        --no-optimization, -n
                      Do not optimize the compiled code.
        --memory-size <number>, -m <number>
                      Sets the minimum number of cells of the brainfuck programm.
                      Defaults to 65536.
        --output <file>, -o <file>
                      Sets the output file.
        --target x86_64
                      Sets the target. Currently only "x86_64" is valid.
    """
  end

  @switches  [no_optimization: :boolean,
              memory_size: :integer,
              output: :string,
              target: :string,
              help: :boolean]

  @aliases    [n: :no_optimization,
               m: :memory_size,
               o: :output,
               t: :target,
               h: :help]

  def parse_args(args) do
    opts = args
    |> OptionParser.parse(
      switches: @switches,
      aliases: @aliases)

    case opts do
      {_, _, [{option, _}|_tail] } ->
        IO.warn("#{option} : Unknown option or bad argument.")
        {:error, :wrong_option}
      {_, [_,b|_tail],_} ->
        IO.warn("Don't know how to deal with '#{b}'. For output file please use -o <output>")
        {:error, :double_arg}
      {options, [],_} ->
        unless Keyword.get(options, :help) do
          IO.warn("No input specified.")
        end
        {:error, :double_arg}
      {options, [inputfile], _} ->
        {:ok, {inputfile, options}}
      _ ->
        IO.warn("Wrong arguments")
        {:error, :wtf}
    end
  end
end
