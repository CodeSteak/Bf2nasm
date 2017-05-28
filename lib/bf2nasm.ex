defmodule Bf2nasm do
  alias Bf2nasm.Parser, as: Parser
  alias Bf2nasm.Compiler, as: Compiler
  alias Bf2nasm.Optimizer, as: Optimizer

  def main(args) do
    case parse_args(args) do
      {:ok, {input, options}} ->
        run(input, options)
      _ ->
        help()
    end
  end

  def run(_inputfile, %{:help => true}), do: help()

  def run(inputfile, %{:output => _outputfile, :target => _target} = options) do
    file_content = case File.read(inputfile) do
      {:ok, content} ->
        content
      {:error, r} ->
        IO.warn("Could not open inputfile #{inspect(r)}")
        System.halt(1)
    end

    file_content
    |> Parser.parse_ast(options)
    |> Optimizer.optimize(options)
    |> Compiler.compile(options)
    :ok
  end

  #supply defaults
  def run(inputfile, opts) do
     cond do
       opts[:target] == nil ->
         run inputfile, Map.put(opts, :target, "x86_64")
       opts[:output] == nil ->
         outfile = inputfile <> "." <> opts[:target]
         run inputfile, Map.put(opts, :output, outfile)
       true ->
         throw "Argument error! This should not be reached."
     end
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
      {_, _, [{option, _} | _tail] } ->
        IO.warn "#{option} : Unknown option or bad argument."
        {:error, :wrong_option}

      {_, [_, b | _tail], _} ->
        IO.warn "Don't know how to deal with '#{b}'. "<>
                "For output file please use -o <output>"
        {:error, :double_arg}

      {options, [], _} ->
        unless Keyword.get(options, :help) do
          IO.warn("No input specified.")
        end
        {:error, :no_input}

      {options, [inputfile], _} ->
        {:ok, {inputfile,
               options |> Map.new }}

      _ ->
        IO.warn("Wrong arguments")
        {:error, :wtf}

    end
  end
end
