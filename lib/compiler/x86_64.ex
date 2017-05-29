defmodule Bf2nasm.Compiler.X86_64 do

  def compile(ast, %{:target => "x86_64",
                    :output => file_prefix,
                    :memory_size => memory_size}) do

    nasm = file_prefix<>".nasm"
    object = file_prefix<>".o"
    executable = file_prefix

    File.open!(nasm, [:write], fn file ->
      IO.write(file, header(memory_size))
      compile_ast(ast, file, {0}, false)
      IO.write(file, footer())
    end)

    case System.cmd("yasm", ["-f", "elf64", "-o", object, nasm]) do
      {_, 0} ->
        :ok
      {err,n} ->
        IO.warn "compiling failed!"
        IO.puts err
        System.halt(n)
    end

    case System.cmd("ld", ["-o", executable, object]) do
      {_, 0} ->
        :ok
      {err,n} ->
        IO.warn "linking failed!"
        IO.puts err
        System.halt(n)
    end
  end

  def compile(ast, opts) do
    cond do
      opts[:memory_size] == nil ->
        compile ast, Map.put(opts, :memory_size, 65536)
      true ->
        throw "Argument error! This should not be reached."
    end
  end

  def compile_ast_info([{cmd, value, pos} | tail], file, meta, dirty) do
    IO.write(file, "\t\t\t\t\t\t;\t#{inspect({cmd, value, pos})}\n")
     compile_ast([{cmd, value, pos} | tail], file, meta, dirty)
  end

  def compile_ast_info(val, file, meta, dirty) do
     compile_ast(val, file, meta, dirty)
  end

  def compile_ast([{:incptr, 1, _pos} | tail], file, meta, dirty) do
    save_value file, !dirty
    IO.write(file, """
      inc POINTER
    """)
    compile_ast_info(tail, file, meta, true)
  end

  def compile_ast([{:incptr, -1, _pos} | tail], file, meta, dirty) do
    save_value file, !dirty
    IO.write(file, """
      dec POINTER
    """)
    compile_ast_info(tail, file, meta, true)
  end

  def compile_ast([{:incptr, value, _pos} | tail], file, meta, dirty) do
    save_value file, !dirty
    IO.write(file, """
      add POINTER, #{value}
    """)
    compile_ast_info(tail, file, meta, true)
  end

  def compile_ast([{:inc, 1, _pos} | tail], file, meta, dirty) do
    clean_value file, dirty
    IO.write(file, """
      inc VALUE
    """)
    compile_ast_info(tail, file, meta, false)
  end

  def compile_ast([{:dec, 1, _pos} | tail], file, meta, dirty) do
    clean_value file, dirty
    IO.write(file, """
      dec VALUE
    """)
    compile_ast_info(tail, file, meta, false)
  end

  def compile_ast([{:inc, value, _pos} | tail], file, meta, dirty) do
    clean_value file, dirty
    IO.write(file, """
      add VALUE, byte #{value}
    """)
    compile_ast_info(tail, file, meta, false)
  end

  def compile_ast([{:set, value, _pos} | tail], file, meta, _dirty) do
    IO.write(file, """
      mov VALUE, byte #{value}
    """)
    compile_ast_info(tail, file, meta, false)
  end

  def compile_ast([{:add_to_next_and_set_to_zero, offset, _pos} | tail],
                  file,
                  meta, dirty) do
    clean_value file, dirty
    IO.write(file, """
      add [POINTER#{n(offset)}], VALUE
      mov VALUE, 0
    """)
    compile_ast_info(tail, file, meta, false)
  end

  def compile_ast([{:sub_to_next_and_set_to_zero, offset, _pos} | tail],
                  file,
                  meta, dirty) do
    clean_value file, dirty
    IO.write(file, """
      sub [POINTER#{n(offset)}], VALUE
      mov VALUE, 0
    """)
    compile_ast_info(tail, file, meta, false)
  end

  def compile_ast([{:multiply_to_next_and_set_to_zero,
                      {offset, factor}, _pos} | tail], file, meta, dirty) do
    clean_value file, dirty
    IO.write(file, """
      mov TEMP, #{factor}
      mul TEMP
      add [POINTER#{n(offset)}], VALUE
      mov VALUE, 0
    """)
    compile_ast_info(tail, file, meta, false)
  end

  #copy loop
  def compile_ast([{:multiply_to_two_and_set_to_zero,
                      {offset1, 1, offset2, 1}, _pos} | tail],
                      file, meta, dirty) do
    clean_value file, dirty
    IO.write(file, """
      add [POINTER#{n(offset1)}], VALUE
      add [POINTER#{n(offset2)}], VALUE
      mov VALUE, 0
    """)
    compile_ast_info(tail, file, meta, false)
  end

  # TODO: deduplicate code
  def compile_ast([{:multiply_to_two_and_set_to_zero,
                      {offset1, factor1, offset2, factor2}, _pos} | tail],
                  file,
                  meta, dirty) do
    clean_value file, dirty
    IO.write(file, """
      xor ax, ax
      mov bx, ax
      mov dx, #{factor1}
      mov cx, #{factor2}
      imul bx, dx
      imul ax, cx
      add [POINTER#{n(offset1)}], bl
      add [POINTER#{n(offset2)}], al
      mov VALUE, 0
    """)
    compile_ast_info(tail, file, meta, false)
  end


  def compile_ast([{:add_to_offset, {value, offset}, _pos} | tail],
                  file,
                  meta, dirty) do
    IO.write(file, """
      add byte [POINTER#{n(offset)}], byte #{value}
    """)
    compile_ast_info(tail, file, meta, dirty)
  end

  def compile_ast([{:write, _, _pos} | tail], file, meta, dirty) do
    clean_value file, dirty
    IO.write(file, """
      mov [buffer], VALUE
      mov VALUE_SAVE, rax
      mov rax, sys_write
      mov rdi, stdout
      mov rsi, buffer
      mov rdx, 1         ; length
      syscall
      mov rax, VALUE_SAVE
    """)
    compile_ast_info(tail, file, meta, dirty)
  end

  def compile_ast([{:read, _, _pos} | tail], file, meta, dirty) do
    clean_value file, dirty
    IO.write(file, """
      mov rax, sys_read
      mov rdi, stdin
      mov rsi, buffer ; into
      mov rdx, 1
      syscall
      mov VALUE, byte [buffer]
    """)
    compile_ast_info(tail, file, meta, false)
  end

  def compile_ast([inner|tail], file, {jmp}, dirty) when is_list(inner) do
    clean_value file, dirty
    IO.write(file, """
bracket_open_#{jmp}:
      cmp VALUE, 0
      je bracket_close_#{jmp}
    """)

    {:ok, _, meta, dirty2} = compile_ast_info(inner, file, {jmp+1}, false)

    clean_value file, dirty2
    IO.write(file, """
      jmp bracket_open_#{jmp}
bracket_close_#{jmp}:
    """)

    compile_ast_info(tail, file, meta, false)
  end

  def compile_ast([], file, meta, dirty) do
    {:ok, file, meta, dirty}
  end

  # pseudo nomalize
  defp n(offset) do
    if offset == 0 do
      throw "illegal offset"
    end

    if offset > 0 do
      "+#{offset}"
    else
      "-#{-offset}"
    end
  end

  def header(mem_size) do
    """
    %define sys_write    1
    %define sys_read     0
    %define sys_exit     60

    %define stdin        0
    %define stdout       1
    %define POINTER      r14
    %define VALUE_SAVE   r15
    %define TEMP         cl
    %define TEMP2        dl
    %define TEMP3        bl
    %define VALUE        al

    section .bss
      align 8
      buffer resb 8
      memory resb #{mem_size}

    section .text
      global _start

    _start
      xor rax, rax
      mov POINTER, memory
    """
  end

  def footer do
    """
      mov rax, sys_exit
      mov rdi, 0        ; exit code
      syscall
    """
  end

  def clean_value(file, true) do
    IO.write file, """
      mov VALUE, byte [POINTER]
    """
  end

  def clean_value(_, false) do
    nil
  end

  def save_value(file, true) do
    IO.write file,  """
      mov [POINTER], VALUE
    """
  end

  def save_value(_, false) do
    nil
  end
end
