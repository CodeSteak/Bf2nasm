defmodule Bf2nasm.Compiler.X86_64 do

@header """
%define sys_write    1
%define sys_read     0
%define sys_exit     60

%define stdin        0
%define stdout       1
%define POINTER      r14
%define VALUE_SAVE   r15
%define TEMP         cl
%define TEMP2        dl
%define VALUE        al

section .bss
  align 8
  buffer resb 8
  memory resb 65536 * 2

section .text
  global _start

_start
  xor rax, rax
  mov POINTER, memory
  add POINTER, 65536
"""

@footer """
  mov rax, sys_exit
  mov rdi, 0        ; exit code
  syscall
"""

  def compile(ast, file_prefix) do
    nasm = file_prefix<>".nasm"
    object = file_prefix<>".o"
    executable = file_prefix
    File.open!(nasm, [:write], fn file ->
      IO.write(file,@header)
      compile_ast(ast, file, {0})
      IO.write(file,@footer)
    end)
    # `yasm -f elf64 -o #{object} #{nasm}`
    {_, 0} = System.cmd("yasm", ["-f", "elf64", "-o", object, nasm])
    # `ld -o #{object} #{executable}`
    {_, 0} = System.cmd("ld", ["-o", executable, object])
  end

  def compile_ast_info([{cmd, value, pos}|tail], file, meta) do
    IO.write(file, "\t\t\t\t\t\t;\t#{inspect({cmd, value, pos})}\n")
     compile_ast([{cmd, value, pos}|tail], file, meta)
  end

  def compile_ast_info(val, file, meta) do
     compile_ast(val, file, meta)
  end

  def compile_ast([{:incptr, 1, _pos}|tail], file, meta) do
    IO.write(file, """
      inc POINTER
      mov VALUE, byte [POINTER]
    """)
    compile_ast_info(tail, file, meta)
  end

  def compile_ast([{:incptr, -1, _pos}|tail], file, meta) do
    IO.write(file, """
      dec POINTER
      mov VALUE, byte [POINTER]
    """)
    compile_ast_info(tail, file, meta)
  end

  def compile_ast([{:incptr, value, _pos}|tail], file, meta) do
    IO.write(file, """
      add POINTER, #{value}
      mov VALUE, byte [POINTER]
    """)
    compile_ast_info(tail, file, meta)
  end

  def compile_ast([{:inc, 1, _pos}|tail], file, meta) do
    IO.write(file, """
      inc VALUE
      mov [POINTER], byte VALUE
    """)
    compile_ast_info(tail, file, meta)
  end

  def compile_ast([{:dec, 1, _pos}|tail], file, meta) do
    IO.write(file, """
      dec VALUE
      mov [POINTER], byte VALUE
    """)
    compile_ast_info(tail, file, meta)
  end

  def compile_ast([{:inc, value, _pos}|tail], file, meta) do
    IO.write(file, """
      add VALUE, byte #{value}
      mov [POINTER], byte VALUE
    """)
    compile_ast_info(tail, file, meta)
  end

  def compile_ast([{:set, value, _pos}|tail], file, meta) do
    IO.write(file, """
      mov VALUE, byte #{value}
      mov [POINTER], byte VALUE
    """)
    compile_ast_info(tail, file, meta)
  end

  def compile_ast([{:add_to_next_and_set_to_zero, offset, _pos}|tail], file, meta) do
    if offset == 0 do
      throw "add_to_next_and_set_to_zero: illegal argument `offset`"
    end

    IO.write(file, """
      add [POINTER#{n(offset)}], VALUE
      xor VALUE, VALUE
      mov [POINTER], byte VALUE
    """)
    compile_ast_info(tail, file, meta)
  end

  def compile_ast([{:sub_to_next_and_set_to_zero, offset, _pos}|tail], file, meta) do
    IO.write(file, """
      sub [POINTER#{n(offset)}], VALUE
      xor VALUE, VALUE
      mov [POINTER], byte VALUE
    """)
    compile_ast_info(tail, file, meta)
  end

  def compile_ast([{:multiply_to_next_and_set_to_zero, {offset, factor}, _pos}|tail], file, meta) do
    IO.write(file, """
      mov TEMP, #{factor}
      mul TEMP
      add [POINTER#{n(offset)}], VALUE
      xor VALUE, VALUE
      mov [POINTER], byte VALUE
    """)
    compile_ast_info(tail, file, meta)
  end

  #copy loop
  def compile_ast([{:multiply_to_two_and_set_to_zero, {offset1, 1, offset2, 1}, _pos}|tail], file, meta) do
    IO.write(file, """
      add [POINTER#{n(offset1)}], VALUE
      add [POINTER#{n(offset2)}], VALUE
      xor VALUE, VALUE
      mov [POINTER], byte VALUE
    """)
    compile_ast_info(tail, file, meta)
  end

  # TODO: deduplicate code
  def compile_ast([{:multiply_to_two_and_set_to_zero, {offset1, factor1, offset2, factor2}, _pos}|tail], file, meta) do
    IO.write(file, """
      mov TEMP2, VALUE ; save
      mov TEMP, #{factor1}
      mul TEMP
      add [POINTER#{n(offset1)}], VALUE
      mov VALUE, TEMP2 ; restore
      mov TEMP, #{factor2}
      mul TEMP
      add [POINTER#{n(offset2)}], VALUE
      xor VALUE, VALUE
      mov [POINTER], byte VALUE
    """)
    compile_ast_info(tail, file, meta)
  end


  def compile_ast([{:add_to_offset, {value, offset}, _pos}|tail], file, meta) do
    IO.write(file, """
      add byte [POINTER#{n(offset)}], byte #{value}
    """)
    compile_ast_info(tail, file, meta)
  end

  def compile_ast([{:write, _, _pos}|tail], file, meta) do
    IO.write(file, """
      mov [buffer], VALUE
      mov VALUE_SAVE, rax
      mov rax, sys_write
      mov rdi, stdout
      mov rsi, buffer
      mov rdx, 1         ; length
      syscall
      mov rax, VALUE_SAVE
      mov [POINTER], byte VALUE
    """)
    compile_ast_info(tail, file, meta)
  end

  def compile_ast([{:read, _, _pos}|tail], file, meta) do
    IO.write(file, """
      mov rax, sys_read
      mov rdi, stdin
      mov rsi, buffer ; into
      mov rdx, 1
      syscall
      mov VALUE, byte [buffer]
      mov [POINTER], byte VALUE
    """)
    compile_ast_info(tail, file, meta)
  end

  def compile_ast([inner|tail], file, {jmp}) when is_list(inner) do
    IO.write(file, """
bracket_open_#{jmp}:
      cmp VALUE, 0
      je bracket_close_#{jmp}
    """)

    {:ok, _, meta} = compile_ast_info(inner, file, {jmp+1})

    IO.write(file, """
      jmp bracket_open_#{jmp}
bracket_close_#{jmp}:
    """)

    compile_ast_info(tail, file, meta)
  end

  def compile_ast([], file, meta) do
    {:ok, file, meta}
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
end
