# x86-64 IP Address Checksum

A Linux x86-64 assembly program (NASM) that reads an IPv4 address, checks that it's valid, and prints a checksum. It was a programming project for CSC 35500 (Computer Systems I) at Lindenwood University, Fall 2026.

```
$ ./ipcheck
Enter an IP address: 68.191.206.51
The checksum is -9

$ ./ipcheck
Enter an IP address: 253.254.256.1
Illegal IP address
```

## The rules

An address is legal only if it's exactly four numbers separated by three dots, every number is between 0 and 255, and nothing else appears: no letters, symbols or spaces, not even a trailing space.

For a legal address, the checksum adds up `(n % 31) - 15` for each of the four numbers. For `68.191.206.51` that's (6 − 15) + (5 − 15) + (20 − 15) + (20 − 15) = −9.

## Build and run

You need an x86-64 Linux machine with `nasm` and `ld` (binutils).

```
make          # nasm -gstabs -felf64 -l ipcheck.lst ipcheck.asm && ld ipcheck.o -o ipcheck
./ipcheck
make test     # runs every example from the assignment, plus edge cases
```

No Linux machine? Paste `ipcheck.asm` into [onecompiler.com/assembly](https://onecompiler.com/assembly), type an address in the STDIN box and click Run.

## Interactive walkthrough

[`walkthrough/index.html`](walkthrough/index.html) explains every line for someone new to assembly. It also replays the program one instruction at a time on three example inputs, showing the registers, variables, stack and terminal as they change. The replay was recorded by running the real program under the gdb debugger.

To view it, download the file and open it in a browser. You can also turn on GitHub Pages (Settings → Pages → Deploy from a branch → `main`) and visit `https://<your-username>.github.io/x86-ip-checksum/walkthrough/`.

## How it works

1. Print the prompt and read the input with the `int 0x80` read and write system calls.
2. Loop over the characters. A digit updates the current number (`num = num × 10 + digit`, illegal if it passes 255). A dot finishes the number. A newline ends the input. Anything else is illegal.
3. At the end, require exactly 3 dots and a last number with at least one digit.
4. For each number, `div` by 31, take the remainder from RDX, subtract 15 and add it to the total.
5. Print the total: print a `-` if it's negative, then divide by 10 over and over and use the stack to put the digits back in order.

## Limited instruction set

The assignment only allowed instructions covered in class: `mov`, `add`, `sub`, `inc`, `dec`, `mul`, `div`, `cmp`, `jmp`, `je`, `jne`, `jg`, `jge`, `jl`, `jnz`, `call`, `ret`, `push`, `pop` and `int`. So the program:

- uses `mov rax, 0` instead of `xor rax, rax`
- clears RAX and then uses `mov al, [...]` instead of `movzx`
- computes `0 - x` with `sub` instead of using `neg`
- uses the `int 0x80` system calls instead of `syscall`

## Known limitations

- It reads at most 256 characters. Longer input is cut off, and the leftover characters go back to the shell after the program exits.
- Leading zeros are accepted, so `010.001.0.1` is treated as `10.1.0.1`.

## How this was made

Most of the code, the tests and the walkthrough page were written by Claude, Anthropic's AI assistant, while I was learning x86 assembly. My AI use was disclosed in the course submission, as the assignment required.

— Callum Hudson
