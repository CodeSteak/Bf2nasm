# Bf2nasm

Bf2nasm is a small brainfuck to x86_64 compiler written in elixir. It outputs x86_64
assembly in `nasm` syntax, compiles it using `yasm` and finaly links it using `ld`.

Please note that Bf2nasm outputs unoptimized assembly and therefore may be slower
than other brainfuck compiler. Also a "real" commandline interface isn't implement
yet. Currently you can only pass one filename to Bf2nasm.

## Dependencies

For using it you need to have `yasm` installed.

## Build
```bash
$ git clone https://github.com/CodeSteak/Bf2nasm
$ cd Bf2nasm
$ mix escript.build
```

## Usage

```bash

$ echo '++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]'/
      '>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.' > hello.bf
$ ./bf2nasm hello.bf
$ ./hello
```
