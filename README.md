# Bf2nasm

Bf2nasm is a small brainfuck to x86_64 compiler written in elixir. It outputs x86_64
assembly in `nasm` syntax, compiles it using `yasm` and finaly links it using `ld`

## Dependencies

For using it you need to have `yasm` installed.

## Usage

```bash
$ git clone https://github.com/CodeSteak/Bf2nasm
$ cd Bf2nasm
$ echo '++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]'/
      '>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.' > hello.bf
$ mix run mix.exs hello.bf
$ ./hello
```
