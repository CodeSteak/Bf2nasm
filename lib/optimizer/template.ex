defmodule Bf2nasm.Optimizer.Template do
  defmacro __using__(opts) do
    quote do
      def pattern(ast) do
         pattern([], ast)
      end
    end
  end

  defmacro end_use_template do
    quote do
      def pattern(processed, []) do
        processed
      end

      def pattern(processed, [inner | tail]) when is_list(inner) do
        inner = pattern(inner)
        pattern( processed ++ [ inner ], tail)
      end

      def pattern(processed, [head | tail]) do
        pattern(processed++[head], tail)
      end
    end
  end
end
