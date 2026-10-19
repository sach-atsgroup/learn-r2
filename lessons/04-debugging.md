# Module 4 — Dynamic debugging

**Target:** `build/04_guard` · **Time:** ~90 min · **Graded:** 4

```sh
./build/04_guard
password: hunter2
GUARD DENIED
```

The password is never stored in the binary. It is built in memory at startup by `derive()`.
Static reading would work but is tedious; watching it happen takes a minute. That is what a
debugger is for.

## Starting

```sh
r2 -d build/04_guard          # launch under the debugger
r2 -d 1234                    # attach to a running pid (needs sudo here, see pitfalls)
```

Inside an already-open session:

```
ood                 reopen in debug mode, restarting the process
ood arg1 arg2       ... with arguments
oo                  reopen (back to static)
```

To pass arguments at launch, set them before the process starts:

```sh
r2 -d -e 'dbg.args=R2ZZZZZZZZZZZZZZ' build/03_keycheck
```

`r2 -d './prog arg'` does **not** work — r2 treats the whole string as a filename.

## Execution control

```
db <addr|symbol>    set a breakpoint
db                  list breakpoints (also dbl)
db- <addr>          delete one
db-*                delete all
dc                  continue
dcu <addr>          continue until an address
dcr                 continue until return
ds                  step one instruction
ds 10               step ten
dso                 step over a call
dsf                 step until the end of the frame
```

## State

```
dr                  all registers
dr rax              one register
dr rax=5            write one
drr                 registers, with what they point at resolved
dm                  memory maps
dmi <lib> <sym>     symbols inside a loaded library
dbt                 backtrace
```

`drr` is the one to reach for first. It tells you which registers hold pointers into the
stack, the heap or the binary, which is usually the question you actually have.

## Reading memory at a register — the part that bites

This is the most important paragraph in the module.

```
dr rsi                  prints the value. Fine.
px 16 @ rsi             WRONG. Silently reads the wrong place or nothing at all.
px 16 @ $r:rsi          also prints nothing in 6.2.5.
```

Two forms that do work:

```
.dr*                    import every register as a flag, then
px 16 @ rsi             ... now rsi is a flag and resolves correctly

s $r:rsi                seek there explicitly, then
px 16                   ... print at the new seek
```

`.dr*` runs `dr*` and feeds its output back into r2 as commands — the leading `.` is
"interpret the output of this as commands". It is the idiomatic fix and worth remembering
beyond this course. Re-run it after every step, because the flags are a snapshot.

To keep a pointer across later steps, turn it into your own flag:

```
f mybuf=$r:rdi          create a flag at whatever rdi holds now
psz @ mybuf             still valid after the register has changed
```

## Visual debugging

```
V!          visual debugger panel
Vpp         visual mode preset for debugging
```

In visual mode: `F7` step, `F8` step over, `F9` continue, `F2` toggle breakpoint.
`:` drops to a command line. This is far more pleasant than typing `ds` repeatedly.

### Pitfalls

- **Never pipe the program's input into r2.** `echo pw | r2 -d ./prog` breaks the session:
  r2 reads *its own commands* from stdin, so your input is consumed as commands, the seek
  never follows the process, and every memory read returns `0xff`. Those `0xff` bytes are
  the symptom to recognize. Run r2 interactively and type the program's input at the
  terminal when it asks, or avoid needing stdin at all (see the route below).
- **Analyze before setting symbol breakpoints.** `db dbg.derive` on an unanalyzed session
  silently resolves to nothing and the breakpoint never fires. Run `aaa` first, or `r2 -A -d`.
- **ASLR moves everything.** Addresses differ every run. `e dbg.aslr=false` pins them, or
  use `dm` to find the base and work in offsets. Never write down a runtime address and
  expect it next session.
- **A breakpoint set before `ood` is a file offset, not a runtime address.** Set breakpoints
  after the process exists, or set them on symbols and let r2 rebase them.
- **`ptrace_scope` is 1 on this machine.** Launching under r2 (`r2 -d ./prog`) works.
  Attaching to a process that is already running (`r2 -d <pid>`) needs sudo. Check with
  `cat /proc/sys/kernel/yama/ptrace_scope`.
- **`WARN: Environment corrupted after null bytes injected` is noise.** It appears on every
  launch here and does not affect the session.
- **Stepping into a PLT stub lands you in the dynamic linker** the first time a function is
  called, because the symbol is resolved lazily. `dso` over the call, or break on the real
  function after the first call has resolved it.

## Suggested route

Two ways in; do both.

**Interactive, the obvious one.** `r2 -A -d build/04_guard`, break on `sym.imp.strcmp`,
`dc`, type anything at the password prompt, then `.dr*` and `psz @ rsi`. The expected string
is the second argument to `strcmp`.

**Non-interactive, the neater one.** `derive()` runs *before* the program asks for input,
so you never have to deal with stdin at all:

```
aaa
db dbg.derive
dc
f buf=$r:rdi        the output buffer it was handed
db sym.imp.printf
dc                  let derive finish
psz @ buf
```

The second route is the one to internalize. "Break before the data exists, flag the pointer,
continue, then read" is the general shape of every runtime-secret problem.

## Exercise

- **4** — The password `04_guard` accepts.

```sh
make check N=4 A='thepassword'
```

## Next

`lessons/05-esil.md`.
