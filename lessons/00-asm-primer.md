# Module 0 — x86-64, just enough

**Target:** `build/00_arith` · **Time:** ~40 min · **Graded:** 0a 0b 0c 0d

Deliberately no radare2 in this module. Learn to read the assembly first, then learn the
tool. Mixing both at once is how people conclude that r2 is confusing when the assembly was
the confusing part.

## Registers

64-bit names, with their 32-bit and 8-bit aliases. Writing to the 32-bit name **zeroes the
top half**; writing to the 8-bit name does not.

| 64 | 32 | 8 | conventional use |
|---|---|---|---|
| `rax` | `eax` | `al` | return value |
| `rdi` | `edi` | `dil` | 1st argument |
| `rsi` | `esi` | `sil` | 2nd argument |
| `rdx` | `edx` | `dl` | 3rd argument |
| `rcx` | `ecx` | `cl` | 4th argument |
| `r8`  | `r8d` | `r8b` | 5th argument |
| `r9`  | `r9d` | `r9b` | 6th argument |
| `rsp` | | | stack pointer |
| `rbp` | | | frame pointer |
| `rip` | | | instruction pointer |

Arguments in order: **rdi, rsi, rdx, rcx, r8, r9**, then the stack. Return in **rax**.
That is the System V AMD64 ABI, which is what Linux uses. Windows uses a different one.

## The shapes you will see constantly

```asm
push rbp            ; function prologue: save the caller's frame pointer
mov  rbp, rsp       ; establish our own
sub  rsp, 0x20      ; make room for locals
...
leave               ; = mov rsp, rbp ; pop rbp
ret                 ; pop return address into rip
```

Locals live at negative offsets from `rbp` (`dword [rbp - 4]`). Arguments that were spilled
to the stack live at positive offsets. With `-O2` the frame pointer often disappears and
everything is `rsp`-relative instead, which is harder to read — that is module 9's problem.

## Instructions worth knowing now

| instruction | meaning |
|---|---|
| `mov a, b` | a = b |
| `lea a, [b + c*8 + 0x10]` | a = that **address**, computed, not loaded. Arithmetic in disguise. |
| `add` / `sub` / `imul` | the obvious |
| `xor eax, eax` | eax = 0, the idiomatic zero |
| `cmp a, b` | compute a - b, set flags, discard the result |
| `test a, b` | compute a & b, set flags, discard. `test eax, eax` asks "is eax zero?" |
| `call` / `ret` | push return address and jump / pop and jump |

`lea` catches everyone out. `lea rax, [rdi + rdi*2]` is `rax = rdi * 3`. No memory is touched.

## Flags and conditional jumps

`cmp`/`test` set flags; the next `jcc` reads them. The ones you need:

| after `cmp a, b` | taken when | signed? |
|---|---|---|
| `je` / `jz` | a == b | — |
| `jne` / `jnz` | a != b | — |
| `jg` / `jle` | a > b / a <= b | signed |
| `jl` / `jge` | a < b / a >= b | signed |
| `ja` / `jbe` | a > b / a <= b | **unsigned** |
| `jb` / `jae` | a < b / a >= b | **unsigned** |

Signed vs unsigned is not cosmetic. `ja` on a length check means the value was treated as
unsigned, which is often exactly where a bug lives.

### Pitfalls

- **The jump is inverted.** C's `if (x > 10) { A } else { B }` usually compiles to
  "compare, jump *past* A when x <= 10". The condition in the asm is the negation of the
  condition in the source. Read `jle` as "skip the if-body".
- **`cmp` operand order.** `cmp eax, 5` followed by `jg` means *eax* > 5, not 5 > eax.
  AT&T syntax reverses the operands; r2 and this course use Intel syntax, like the table above.
- **`test eax, eax` is not a comparison with a constant.** It is a zero check.
- **A 32-bit write clears the upper 32 bits.** `mov eax, 1` sets all of `rax` to 1.
  `mov al, 1` only touches the bottom byte and leaves the rest alone.

## Do this

```sh
make
objdump -d -M intel --no-show-raw-insn build/00_arith | less
```

Find `triple_plus`, `fork_in_road`, `sixth_arg` and `accumulate`. Read them. Do not run them.

## Exercises

Work out each answer from the disassembly. Running the binary will not tell you — `main`
prints nothing useful on purpose.

- **0a** — What does `triple_plus(7, 5)` return?
- **0b** — What does `fork_in_road(25)` return?
- **0c** — What does `sixth_arg(1, 2, 3, 4, 50, 8)` return? (Watch which registers it reads.)
- **0d** — What does `accumulate(4)` return?

```sh
make check N=0a A=42
```

## Next

`lessons/01-navigation.md`. From here on, everything is r2.
