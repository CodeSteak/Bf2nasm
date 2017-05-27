# Bf2nasm

Bf2nasm is a small brainfuck to x86_64 compiler, written in Elixir. It outputs x86_64
assembly for Linux in `nasm` syntax, compiles it using `yasm` and finally links it using `ld`.
Support for other Operating systems is currently not planned.

Please note that Bf2nasm outputs barely optimized assembly and therefore may be slower
than other brainfuck compilers. Also a "real" command line interface isn't implement yet.
Currently you can only pass one filename to Bf2nasm.

## Dependencies

For using it you need to have `yasm` installed.

## Building
```bash
$ git clone https://github.com/CodeSteak/Bf2nasm
$ cd Bf2nasm
$ mix escript.build
```

## Usage

```bash

$ echo '++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>'\
       '.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.' > hello.bf
$ ./bf2nasm hello.bf
$ ./hello
```
