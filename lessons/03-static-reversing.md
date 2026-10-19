# Module 3 — Static logic reversing · boss fight

**Target:** `build/03_keycheck` · **Time:** ~90 min · **Graded:** 3

```sh
./build/03_keycheck SOMEKEY     # KEY REJECTED
```

Find a key it accepts. **Statically.** No debugger, no brute force. Read the gates, invert
them, compute the answer with a calculator.

This is the module where r2 stops being a disassembler and becomes a notebook: you annotate
as you understand, and the annotations carry you.

## Annotating

Analysis gives you machine names. Your job is to replace them with meaning.

```
afn newname          rename the current function
afn newname @ 0x1234 rename the one at an address
afvn old new         rename a local variable or argument
afv                  list this function's variables and arguments
afvd                 show how each variable is accessed
CC some note         add a comment at the current address
CC- @ addr           delete it
Cs                   mark the current address as a string
afs                  show or set the function signature
```

Rename as you go. A function called `dbg.table_gate` with a variable called `var_14h` is
noise; `checksum_loop` with `i` is a sentence.

## Reading the logic

```
pdf              the disassembly
pdc             r2's pseudo-decompiler (C-ish, approximate)
pdr             recursive disassembly following calls
VV              the control-flow graph
axf             what this function calls
```

`pdc` is a hint generator. It will get types, signedness and loop bounds wrong. Use it to
orient, then confirm against `pdf`. Never submit an answer that only `pdc` supports.

If you want a real decompiler, `r2pm -ci r2ghidra` adds `pdg`. It is genuinely good. It is
also not necessary here, and the point of this module is to read the assembly.

## Reading data

The gates compare against a table. Read it:

```
px 16 @ <addr>     16 bytes of hex
pxw @ <addr>       as 32-bit words
p8 16 @ <addr>     raw hex, no formatting, easy to copy
psz @ <addr>       as a zero-terminated string
```

## Suggested route

1. `r2 -A build/03_keycheck`, then `afl` and find `validate`.
2. `VV` or `pdf` on it. It calls three gates in sequence. Name them.
3. Read each gate. Two are trivial. One loops over the input against a table in `.rodata`.
4. `px` the table. Work out the per-index transform from the loop body — watch for the
   multiply and the constant added before the XOR.
5. Invert it: for each index, the wanted character is `table[i] XOR mask(i)`.
6. Compute all 16 characters. Check it against the two easy gates. Submit.

### Pitfalls

- **r2's variable names are guesses.** `var_ch` means "something at rbp-0xc", nothing more.
  It may be two different variables that the compiler merged, or part of a struct.
  `afvd` shows the actual accesses.
- **The loop bound is not always in the `cmp`.** At `-O0` it usually is. Check whether the
  counter is compared before or after the increment, or you will be off by one.
- **`movzx` vs `movsx`.** One zero-extends, the other sign-extends. On a `char` compare that
  difference decides whether `0x80`-and-up bytes behave as negative. This target stays in
  ASCII, but the habit matters.
- **The mask constant may be folded.** `i * 7 + 0x2a` can appear as a `lea` with a scale, or
  as a multiply, or partially constant-folded. Read what the registers actually hold rather
  than looking for the literal `7`.
- **Do not trust `pdc` on the XOR direction.** Confirm against `pdf` which operand is the
  table and which is the input.
- **Gate order matters when you test.** `prefix_gate` runs before `table_gate`, so a key
  that fails the prefix never reaches the interesting code. If you are also poking at this
  under a debugger, that is why your breakpoint never fires.

## Exercise

- **3** — A key that `03_keycheck` accepts.

```sh
make check N=3 A='YOUR_KEY_HERE'
```

The grader runs the real binary. Any key it accepts counts.

**Badge:** static reverser.

## Next

`lessons/04-debugging.md`.
