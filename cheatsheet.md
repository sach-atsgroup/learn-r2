# radare2 cheatsheet

Grouped by what you are trying to do. Validated against radare2 6.2.5.

**The only thing you must remember:** any command takes `?` as a suffix. `a?`, `af?`, `afl?`,
`p?`, `d?`, `w?`, `e?`. Everything below is discoverable that way.

## Launching

| | |
|---|---|
| `r2 bin` | open read-only |
| `r2 -A bin` | open and run `aaa` |
| `r2 -w bin` | open read-write |
| `r2 -d bin` | launch under the debugger |
| `r2 -D gdb -d gdb://host:port` | attach to a gdb stub (qemu) |
| `r2 -a arm -b 64 blob` | force architecture and bitness |
| `r2 -q -c 'aaa;afl' bin` | run commands, print, quit |
| `r2 -q -i script.r2 bin` | run a command file |
| `r2 -e scr.color=0 ...` | no ANSI codes, for piping |
| `r2 -e dbg.args='a b' -d bin` | set the debuggee's argv |

## Analysis

| | |
|---|---|
| `aa` / `aaa` / `aaaa` | analyse: fast / normal / thorough |
| `afl` / `aflj` | list functions / as JSON |
| `afl~?` | count functions |
| `af @ addr` | analyse a function here |
| `af- @ addr` | forget it |
| `afu addr` | set the current function's end |
| `afi` | info about the current function |
| `afb` | its basic blocks |
| `aflm` | call map |
| `av` / `avj` | find C++ vtables |
| `ic` | list classes |

## Moving and looking

| | |
|---|---|
| `s addr` / `s sym.name` | seek |
| `s-` / `s+` | undo / redo seek |
| `?v $$` | current offset |
| `pdf` | disassemble this function |
| `pd 20` / `pd -5` | 20 instructions forward / 5 back |
| `pdc` | pseudo-decompile (approximate) |
| `pdr` | recursive disassembly |
| `pdg` | Ghidra decompiler (`r2pm -ci r2ghidra`) |
| `cmd @ addr` | run cmd at addr without moving the seek |
| `V` / `VV` / `V!` | visual / graph / debug panel |

## Printing data

| | |
|---|---|
| `px 32` | hexdump |
| `pxw` / `pxq` | as 32- / 64-bit words |
| `p8 16` | raw hex, copy-friendly |
| `psz` / `ps` | zero-terminated string |
| `pf` | format-string structured print |

## Binary information

| | |
|---|---|
| `i` | headers: arch, bits, PIE, stripped, canary |
| `iz` / `izz` | strings in data sections / whole file |
| `is` / `ii` / `ie` | symbols / imports / entrypoints |
| `iS` / `il` | sections / libraries |
| `iD c++ _ZN...` | demangle |

## Cross-references

| | |
|---|---|
| `axt` | what references here |
| `axf` | what here references |
| `/ string` | search for a string |
| `/x deadbeef` | search for bytes |
| `/R` | ROP gadgets |

## Annotating

| | |
|---|---|
| `afn name` | rename function |
| `afvn old new` | rename variable |
| `afv` / `afvd` | list variables / their accesses |
| `afs` | function signature |
| `CC text` | comment here |
| `td "struct x {...};"` | declare a type |
| `ts` / `tl t = addr` | list types / link one to an address |

## Debugging

| | |
|---|---|
| `db sym` / `db-` / `db-*` | breakpoint: set / delete / clear all |
| `dc` / `dcu addr` / `dcr` | continue / until addr / until return |
| `ds` / `dso` / `dsf` | step / step over / step out of frame |
| `dr` / `dr rax=5` / `drr` | registers: read / write / resolved |
| `.dr*` | **import registers as flags** so `@ rsi` works |
| `s $r:rsi` | seek to a register's value |
| `f name=$r:rdi` | make a lasting flag from a register |
| `dm` / `dmi lib sym` | memory maps / library symbols |
| `dbt` | backtrace |
| `ood args` | restart the process |
| `e dbg.aslr=false` | pin addresses across runs |

## ESIL emulation

| | |
|---|---|
| `e io.cache=true` | **required** before emulating, or writes are invisible |
| `aei` / `aeim` / `aeip` | init VM / init memory / set PC to seek |
| `aes` / `aeso` / `aesu addr` | step / step over / step until |
| `aer` / `aer rax=1` | ESIL registers |
| `wc-*` | discard emulated writes |

## Patching

| | |
|---|---|
| `oo+` | reopen read-write |
| `wx 9090` | write hex |
| `wa jmp 0x117f` | assemble and write (**can change length**) |
| `wao nop` / `wao nocj` / `wao recj` | nop out / drop / reverse the current jump |
| `w text` / `wz text` | write a string |
| `wc` / `wc-*` | list / discard cached writes |

## Filtering output

| | |
|---|---|
| `cmd~text` | lines containing text |
| `cmd~?` | count lines |
| `cmd~[0]` | column 0 |
| `cmd~{}` | pretty-print JSON |
| `cmdj` (in r2pipe) | parsed JSON |
| `.cmd` | run cmd's output as commands |

## Config

| | |
|---|---|
| `e key=value` | set |
| `e~text` | search config keys |
| `e asm.syntax=att` | AT&T syntax |
| `e asm.bytes=false` | hide the bytes column |
| `~/.radare2rc` | persistent settings |
