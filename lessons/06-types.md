# Module 6 — Types, structs and vtables

**Targets:** `build/06_structs`, `build/06_vtable` · **Time:** ~60 min · **Graded:** 6a 6b 6c

Compiled code has no structs. It has `[rax + 0x18]`. Recovering the layout is most of what
reversing application code *is* — and it is what you will be doing on the WAVE C++ binaries.

## Reading offsets

```sh
r2 -A build/06_structs
```

Each accessor reads exactly one field:

```
afl~get_
pdf @ dbg.get_id
pdf @ dbg.get_battery
```

The offset in the memory operand is the field offset. `qword [rax + 0x18]` into an SSE
register means "an 8-byte float 24 bytes into the object".

Reconstruct the whole layout by reading every accessor, then sanity-check it: the offsets
should be ordered and consistent with the alignment rules (an 8-byte field sits at a
multiple of 8; the struct's size is a multiple of its largest member's alignment).

## Declaring types in r2

Once you know the layout, tell r2 and it will annotate for you:

```
td "struct robot { uint32_t id; uint8_t mode; char name[16]; double battery; };"
ts                  list known structs
ts robot            show one
tl robot = 0x4040   link the type to an address
t?                  the full type menu
afs                 show or set the current function's signature
```

After `tl`, r2 labels the field accesses in the disassembly instead of showing bare offsets.
This is what turns a 500-line reversing job into a 50-line one.

## C++ and vtables

```sh
r2 -A build/06_vtable
```

```
av                  find vtables
avj                 ... as JSON
ic                  list classes
ic~Sprayer          one of them
```

A virtual call looks like: load the object pointer, load the vtable pointer from offset 0,
load a function pointer at a fixed offset into the vtable, `call` it. The offset tells you
*which* virtual method, and `av` tells you which classes could be on the other end.

### Pitfalls

- **Padding is invisible but real.** `uint8_t` followed by `double` leaves 3 bytes of hole
  after a `char[16]`. Offsets jump in ways the field list does not explain. Never assume
  field N starts where field N-1 ended.
- **The compiler reorders nothing in C, but it does pad.** Field *order* in memory matches
  declaration order. Gaps do not mean reordering.
- **`sizeof` is not the sum of the fields.** It is rounded up to the struct's alignment, so
  there is trailing padding too.
- **An accessor may be inlined away** at any optimization level above `-O0`, leaving you with
  only the offsets at the use sites. This target is built `-O0 -fno-inline` on purpose.
- **A vtable has more entries than the class has virtual methods.** C++ emits *two*
  destructors (complete and deleting) per class, so each vtable here starts with two slots
  before `prepare`. Count what is in the table, not what is in the header.
- **`av` finds vtables by pattern** and can miss them, especially with
  `-fvisibility=hidden` or LTO. It can also report RTTI pointers as entries. Verify by
  following one entry to a function that looks like a method.
- **Name mangling.** r2 demangles by default here. If you see `_ZN7Sprayer5applyEi`, run
  `e bin.demangle=true`, or decode it with `iD c++ _ZN...`.

## Exercises

```sh
./build/06_structs      # prints sizeof, useful as a cross-check
```

- **6a** — At what byte offset does the `battery` field start?
- **6b** — What is `sizeof(struct robot)`?
- **6c** — How many entries does each class's vtable have in `06_vtable`?

```sh
make check N=6a A=24
```

## Next

`lessons/07-patching.md`.
