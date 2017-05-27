# Bf2nasm

Bf2nasm is a small Brainfuck to x86_64 compiler, written in Elixir. It outputs x86_64
assembly for Linux in `nasm` syntax, compiles it using `yasm` and finally links it using `ld`.
Support for other Operating systems is currently not planned.

Performance should be comparable to other Brainfuck compilers.

Please note that the command line interface is work in progress.
Currently you can only pass one filename, ending with `.bf`, to Bf2nasm.
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
