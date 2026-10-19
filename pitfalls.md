# Pitfalls

Every trap from every module, collected. Append your own as you hit them — that is what this
file is for.

Ranked roughly by how much time each one costs before you spot it.

## The expensive ones

1. **ESIL writes are invisible without `e io.cache=true`.** Emulation runs, reports success,
   and `px` shows you the original bytes. No error. You will conclude the emulation did
   nothing, or worse, submit the encoded bytes as your answer. *(Module 5)*
2. **Piping the debuggee's stdin into r2 destroys the session.** `echo pw | r2 -d ./prog`:
   r2 reads commands from stdin, consumes your input as commands, the seek never follows the
   process, and every memory read returns `0xff`. Those `0xff` bytes are the tell. *(Module 4)*
3. **`px 16 @ rsi` does not read the memory at rsi.** It silently reads the wrong place or
   prints nothing. Run `.dr*` first to import registers as flags, or `s $r:rsi` then `px`.
   `?v rsi` works, which makes this doubly confusing. *(Module 4)*
4. **`wa` can assemble to a different length than the instruction it replaces** and silently
   corrupt the next one. Always `pd 2` after writing. Prefer `wao`, which sizes correctly.
   *(Module 7)*
5. **Symbol breakpoints set before analysis never fire.** `db dbg.derive` on an unanalyzed
   session resolves to nothing, silently. `aaa` first, or `r2 -A -d`. *(Module 4)*

## Analysis

- **`pdf` prints nothing until you analyze.** The most common "r2 is broken" moment.
  *(Module 1)*
- **`aaa` is slow on big binaries** — minutes on a firmware image. `aa` is the fast subset.
  *(Module 8)*
- **r2 invents function boundaries confidently and wrongly**, especially on `-O2` code.
  Check that each `fcn.*` starts on a plausible prologue; fix with `af @ addr` and `afu`.
  *(Module 9)*
- **No xref does not mean unused.** Computed addresses, jump tables and optimized code defeat
  analysis routinely. *(Module 2)*
- **`s main` is silent when there is no `main` symbol.** `?v $$` tells you the seek did not
  move. *(Module 9)*

## Naming and output formats

- **Static functions get a `dbg.` prefix when debug info is present**, not `sym.`. Also
  expect `fcn.`, `loc.`, `sub.`, `method.`. *(Module 1)*
- **`aflq` prints addresses only** in 6.x, not names. Any script parsing names out of it is
  broken. *(Modules 1, 8)*
- **`afi` field names change between versions** — `num-bbs` in 6.2.5. Grep rather than
  assume. *(Module 1)*
- **Parse JSON, not columns.** Every listing takes a `j` suffix. Text layout moves between
  releases; JSON does not. *(Module 8)*
- **ANSI colour codes poison piped text.** `-e scr.color=0` whenever you pipe `cmd` output.
  *(Module 8)*
- **`cmdj` returns `None` when the command produced no JSON**, including on a typo — which
  then looks like an empty binary. *(Module 8)*

## Strings and data

- **`iz` and `izz` disagree, and both are right.** `iz` scans data sections, `izz` scans
  every byte. A string appended past the last section is invisible to `iz`. *(Module 2)*
- **`is` returns almost nothing on a stripped binary.** Check `i~stripped` first. *(Module 2)*
- **Short strings can be inlined as 64-bit immediates** and never appear in `iz` at all.
  *(Module 9)*

## Reading code

- **The jump condition is the negation of the source condition.** `if (x > 10)` compiles to
  "jump past the body when x <= 10". *(Module 0)*
- **`cmp eax, 5` then `jg` means eax > 5**, not the reverse. *(Module 0)*
- **`test eax, eax` is a zero check**, not a comparison with a constant. *(Module 0)*
- **A 32-bit write zeroes the upper 32 bits.** `mov eax, 1` clears all of `rax`.
  `mov al, 1` does not. *(Module 0)*
- **`lea` is arithmetic, not a load.** `lea rax, [rdi + rdi*2]` is `rax = rdi * 3`.
  *(Module 0)*
- **Signed and unsigned jumps are different instructions.** `ja` vs `jg` tells you how the
  value was typed. *(Module 0)*
- **`movzx` vs `movsx`** decides whether bytes above `0x7f` behave as negative. *(Module 3)*
- **`pdc` is a hint generator**, not a decompiler. It gets types, signedness and loop bounds
  wrong, and gets much worse on `-O2`. Confirm against `pdf`. *(Modules 3, 9)*
- **r2's variable names are guesses.** `var_ch` means "something at rbp-0xc". Two source
  variables may share one slot. `afvd` shows the real accesses. *(Module 3)*
- **Check whether the loop counter is compared before or after the increment**, or you are
  off by one. *(Module 3)*

## Optimized code

- **Stripped plus `-O2` is normal, not obfuscated.** Assume the compiler before assuming
  malice. *(Module 9)*
- **A switch may compile to branchless arithmetic** — a range check plus a subtraction plus
  a `cmov`, with no jump table anywhere. *(Module 9)*
- **Loops get auto-vectorized.** A byte-sum loop becomes `punpcklbw`/`paddd` on `xmm`
  registers with a scalar tail. Recognise the shape; do not trace the arithmetic. *(Module 9)*
- **`-O2` drops the frame pointer.** Locals become `rsp`-relative and the offsets shift as
  the stack moves. *(Modules 0, 9)*
- **Accessors get inlined away** above `-O0`, leaving only offsets at the use sites.
  *(Module 6)*

## Structs and C++

- **Padding is invisible but real.** Field offsets jump in ways the declaration does not
  explain. *(Module 6)*
- **`sizeof` is not the sum of the fields** — there is trailing padding too. *(Module 6)*
- **A vtable has more entries than the class has virtual methods**: C++ emits two destructors
  per class. *(Module 6)*
- **`av` finds vtables by pattern** and both misses real ones and reports RTTI pointers as
  entries. Verify by following an entry. *(Module 6)*

## Debugging

- **ASLR moves everything every run.** `e dbg.aslr=false`, or work in offsets from `dm`.
  Never write down a runtime address. *(Module 4)*
- **A breakpoint set before `ood` is a file offset, not a runtime address.** *(Module 4)*
- **`ptrace_scope=1` on this machine.** `r2 -d ./prog` works; `r2 -d <pid>` needs sudo.
  *(Module 4)*
- **`r2 -d './prog arg'` does not work** — r2 takes the whole string as a filename. Use
  `-e dbg.args=...` or `ood args`. *(Module 4)*
- **The first call into a PLT stub lands in the dynamic linker.** Lazy binding. `dso` over
  it, or break on the real function after the first call. *(Module 4)*
- **`WARN: Environment corrupted after null bytes injected` is harmless noise** on every
  launch here. *(Module 4)*
- **Gate order matters when you set breakpoints.** A breakpoint in a function that an earlier
  check prevents from being reached will never fire, and looks like a broken breakpoint.
  *(Module 3)*

## ESIL

- **`aei` without `aeim` gives a VM with no stack.** Anything that pushes or calls faults
  confusingly. Always pair them. *(Module 5)*
- **ESIL emulates no syscalls and no library calls.** Emulate the computation, never `main`.
  `aeso` over calls you do not care about. *(Module 5)*
- **The ESIL PC is separate from your seek.** `aeip` syncs it once; `s` afterwards does not
  move it. Check `aer rip`. *(Module 5)*
- **`aesu` stops before executing the target instruction.** Fine for a `ret`, wrong for the
  last instruction of a loop body. *(Module 5)*
- **SIMD and FPU instructions are incompletely lifted.** ESIL is reliable on plain integer
  code. *(Module 5)*

## Patching

- **Writes go nowhere without write mode**, and report success anyway. `-w` or `oo+`.
  *(Module 7)*
- **Check the seek before every write.** `pdf @ addr` does *not* move the seek, so the write
  that follows lands where you were, not where you looked. *(Module 7)*
- **`wao nop` over a `call` leaves `rax` holding stale garbage.** Patch the test after the
  call, not the call. *(Module 7)*
- **Always patch a copy.** r2's write mode edits in place with no undo. *(Module 7)*

## aarch64

- **The sysroot is not optional** under qemu: `-L /opt/V1X00/sysroots/aarch64-poky-linux`.
  No static build is possible — the SDK has `libc.so` but no `libc.a`. *(Module 10)*
- **`adrp` + `add` form addresses across two instructions.** Searching for an address as a
  constant finds nothing. *(Module 10)*
- **One `adrp` serves several `add`s** — the compiler hoists it, so the xref may be nowhere
  near. *(Module 10)*
- **The qemu gdb stub is narrower than native ptrace.** Watchpoints and `dm` are often
  unavailable; software breakpoints and stepping work. *(Module 10)*
- **Attach before the program runs.** With `-g`, qemu waits at the entrypoint. *(Module 10)*
- **`w0` is not `x0`** — 32-bit view, zeroes the top half on write. *(Module 10)*

## Environment

- **`which -a r2` when anything is strange.** A distro r2 and a `/usr/local` r2 on the same
  PATH, with mismatched plugin ABIs, produces inexplicable behaviour. `make doctor` warns.
- **Plugins must match the r2 ABI exactly.** Install them with the same `r2pm` that belongs
  to the r2 you are running.

## Yours

Add what bites you:

-
