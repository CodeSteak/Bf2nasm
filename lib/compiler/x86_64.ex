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

  def compile_ast([{:incptr, value, _pos}|tail], file, meta) do
    IO.write(file, """
    mov [POINTER], byte VALUE
    add POINTER, #{value}
    mov VALUE, byte [POINTER]
    """)
    compile_ast(tail, file, meta)
  end

  def compile_ast([{:inc, value, _pos}|tail], file, meta) do
    IO.write(file, """
    add VALUE, byte #{value}
    """)
    compile_ast(tail, file, meta)
  end

  def compile_ast([{:set, value, _pos}|tail], file, meta) do
    IO.write(file, """
    mov VALUE, byte #{value}
    """)
    compile_ast(tail, file, meta)
  end

  def compile_ast([{:add_to_next_and_set_to_zero, _value, _pos}|tail], file, meta) do
    IO.write(file, """
    add [POINTER+1], VALUE
    mov VALUE, 0
    """)
    compile_ast(tail, file, meta)
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
    """)
    compile_ast(tail, file, meta)
  end

  def compile_ast([{:read, _, _pos}|tail], file, meta) do
    IO.write(file, """
    mov rax, sys_read
    mov rdi, stdin
    mov rsi, buffer ; into
    mov rdx, 1
    syscall
    mov VALUE, byte [buffer]
    """)
    compile_ast(tail, file, meta)
  end

  def compile_ast([inner|tail], file, {jmp}) when is_list(inner) do
    IO.write(file, """
bracket_open_#{jmp}:
    cmp VALUE, 0
    je bracket_close_#{jmp}
    """)

    {:ok, _, meta} = compile_ast(inner, file, {jmp+1})

    IO.write(file, """
    jmp bracket_open_#{jmp}
bracket_close_#{jmp}:
    """)

    compile_ast(tail, file, meta)
  end

  def compile_ast([], file, meta) do
    {:ok, file, meta}
  end
end
