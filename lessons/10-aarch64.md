# Module 10 — aarch64, cross-built and emulated

**Target:** `build/10_arm` · **Time:** ~90 min · **Graded:** 10

```sh
qemu-aarch64 -L /opt/V1X00/sysroots/aarch64-poky-linux ./build/10_arm ABCDE
# ARM REJECTED
```

This one is built with the Owasys poky toolchain — the same compiler that builds the WAVE
robot binaries — and runs under qemu user-mode emulation. Everything you have learned
transfers; only the instruction set changes.

## Static analysis

r2 reads the ELF header and picks the architecture itself:

```sh
r2 -A build/10_arm
```

To force it, or to work on a raw blob with no header:

```sh
r2 -a arm -b 64 blob.bin
```

```
e asm.arch=arm
e asm.bits=64
e asm.arch=?        list what this build supports
```

## aarch64 in one page

| | |
|---|---|
| arguments | `x0`–`x7` (32-bit views `w0`–`w7`) |
| return | `x0` |
| link register | `x30` / `lr` — the return address, in a register, not on the stack |
| stack pointer | `sp` |
| zero register | `xzr` / `wzr` — reads as 0, writes discard |
| frame pointer | `x29` / `fp` |

| instruction | meaning |
|---|---|
| `bl label` | call: set `lr` to the next instruction, branch |
| `ret` | branch to `lr` |
| `b` / `b.eq` / `b.ne` | branch, conditionally |
| `cbz` / `cbnz x0, label` | branch if register is / is not zero |
| `ldr x0, [x1, #8]` | load |
| `str w0, [x1, #4]` | store |
| `ldrb w0, [x1]` | load one byte, zero-extended |
| `mov x0, x1` | move |
| `cmp` / `subs` | compare, set flags |
| `stp` / `ldp x29, x30, [sp, #-16]!` | store/load a **pair** — the standard prologue |

Fixed 4-byte instructions. Every instruction is 4 bytes, always, which makes patching
simpler than on x86 — the replacement is always the same size.

## adrp + add: how addresses are formed

This is the idiom that trips up everyone coming from x86:

```asm
adrp x0, 0x411000       ; x0 = the 4 KiB page containing the target
add  x0, x0, #0x40      ; x0 = the target
```

A 64-bit address does not fit in a 32-bit instruction, so it is built from two. `adrp` gets
the page, `add` (or the offset in a following `ldr`) gets the rest.

Consequences: searching for an address as a constant finds nothing, and reading either
instruction alone tells you nothing. r2 usually resolves the pair and comments the real
target — but when it does not, you have to add the two yourself.

## Debugging under qemu

qemu exposes a gdb stub; r2 speaks gdb remote.

Terminal 1:

```sh
qemu-aarch64 -L /opt/V1X00/sysroots/aarch64-poky-linux -g 1234 ./build/10_arm ABCDE
```

It blocks, waiting for a debugger. Terminal 2:

```sh
r2 -D gdb -d gdb://localhost:1234
```

Then the module 4 commands work as usual: `db`, `dc`, `dr`, `.dr*`, `px @ x0`.

### Pitfalls

- **The sysroot is not optional.** `10_arm` is dynamically linked against the poky libc.
  Without `-L /opt/V1X00/sysroots/aarch64-poky-linux`, qemu cannot find the loader and
  fails with a confusing error. There is no static build available here — the SDK ships
  `libc.so` but no `libc.a`.
- **`adrp` pairs break constant searches.** `/x` for the bytes of an address will not find
  references to it. Search for the `adrp` target page instead, or use `axt`.
- **One `adrp` serves several `add`s.** The compiler hoists it. The same `x0` page gets a
  different offset added in three places, so the xref you want may not be next to the `adrp`.
- **`pdc` is weaker on aarch64** than on x86. Expect to read the real instructions.
- **The qemu gdb stub supports a narrower command set than native ptrace.** Hardware
  watchpoints, some register writes and memory-map queries may not work. `dm` is often
  unhelpful. Software breakpoints and stepping do work.
- **Attach before the program runs anything.** With `-g`, qemu waits at the entrypoint.
  If you connect late you have already missed the start.
- **Do not confuse `w0` with `x0`.** Operations on `w` registers zero the top 32 bits, same
  as x86's 32-bit registers. A `cmp w0, #5` after a byte load is a 32-bit compare.

## Exercise

- **10** — The 5-character key that `10_arm` accepts.

```sh
make check N=10 A='KEY'
```

The grader runs it under qemu with the right sysroot.

## Next

`lessons/11-capstone.md`.
