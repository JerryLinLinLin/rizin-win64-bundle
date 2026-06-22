---
name: rizin-windows-re
description: >-
  Cheatsheet for static reverse engineering and binary analysis with the rizin bundle
  (rz-retdec `pdz`, rz-ghidra `pdg`, jsdec `pdd` decompilers, rz-libyara, FLIRT). Use it for
  essentially any RE or binary-inspection task on any format rizin parses — PE (.exe/.dll/.sys),
  ELF, Mach-O, firmware, shellcode, or raw — on any platform, not just Windows. Reach for it to
  disassemble, decompile, or inspect a binary: imports/exports/strings/symbols, cross-references,
  recovering unnamed functions, or identifying and triaging an unknown or suspicious binary (CTF
  or malware analysis). Trigger it even on casual phrasings like "analyze this binary", "what
  does this exe/dll do", "decompile this function", or "is this malware", or any rizin/radare2
  mention. Assumes rizin and its plugins are on PATH; includes extra Windows PE/driver hints.
  Not for live debugging or .NET/managed-only decompilation.
---

# Rizin RE Cheatsheet

A fast, general command reference for reverse-engineering and inspecting binaries with the
prebuilt rizin bundle. It works on any binary rizin can parse — PE, ELF, Mach-O, firmware,
shellcode, raw blobs — on any platform; the **Windows binaries** section near the end adds
extra PE/driver-specific hints, but everything above it is format-agnostic.

Assume `rizin` and friends are already on `PATH`. This skill is a cheatsheet, not a fixed
procedure — pick the commands you need for the question at hand.

## How to drive rizin non-interactively

You are running rizin from a shell tool, not sitting in its interactive prompt. Drive it
one-shot with `-c` commands and let it quit. This one launch pattern covers almost everything:

```
rizin -A -q -N -e scr.color=0 -c "<cmd>" -c "<cmd>" <file>
```

- `-A` runs full analysis (`aaa`) before your commands, so functions, xrefs, and FLIRT names
  exist. Drop it (or use plain `rizin`) when you only want headers/strings and want to be fast.
- `-q` quits after the `-c` commands (no interactive prompt to hang on).
- `-N` ignores user config so output is reproducible.
- `-e scr.color=0` disables ANSI color — **important**, or output is full of escape codes that
  are hard to parse.
- Multiple `-c` run in order. You can also chain inside one with `;`.
- Read-only by default; add `-w` only if you intend to patch.

Keep output small so you can actually read it:

- `~word` is rizin's built-in grep: `afl~main`, `iI~bits,os`. `~?` counts matches: `ii~?`.
- `q`/`j` suffixes mean quiet/JSON: `iiq` (terse imports), `aflj` (functions as JSON for parsing).
- `@ <addr>` runs one command at a temporary offset without moving the cursor: `pdf @ main`,
  `pdg @ 0x140001000`. This is cleaner than seeking first.
- Pipe huge output through `head` in your shell, or disassemble a bounded count (`pd 40`).

**Reuse analysis instead of re-running it.** Every `rizin -A … <file>` re-runs `aaa`, which is
the slow/expensive part — wasteful if you issue many queries about one binary (especially a
large one). Analyze once, save a project, then reload it instantly (no `-A`) for the rest:

```
rizin -A -q -N -e scr.color=0 -c "Ps sample.rzdb" sample.exe         # analyze once → save
rizin -p sample.rzdb -q -N -e scr.color=0 -c "afl" -c "pdg @ main"   # reload, no re-analysis
```

## Core syntax (worth knowing)

| Syntax | Meaning |
| --- | --- |
| `x?` | Help for command `x` (e.g. `i?`, `ax?`, `pdg?`). Your ground truth when unsure. |
| `x @ addr` | Run `x` once at `addr` (temporary seek). |
| `xj` / `xq` / `x*` | JSON / quiet / "emit as rizin commands" variants of most commands. |
| `cmd~grep` | Filter `cmd` output (`~?` = count, `~[2]` = column 2, `~:0` = first line). |
| `cmd @@ii` | Run `cmd` over every import; also `@@is` (symbols), `@@iz` (strings), `@@b` (basic blocks). |
| `cmd @@f:glob` | Run `cmd` over flags matching a glob (e.g. `@@f:str.*`). `@@F:glob` = functions. |
| `cmd @@c:cmd2` | Run `cmd` at every address in `cmd2`'s output. |

## Triage: what is this file?

| Command | Purpose |
| --- | --- |
| `iI` | Headers at a glance: arch, bits, OS, subsystem, compiler, stripped?, PIE, signed?, PDB path. |
| `i` / `ia` | Quick info / full summary of everything. |
| `il` | Linked libraries — often tells you the file's nature instantly (e.g. `fltmgr.sys` ⇒ minifilter driver). |
| `is` / `is~?` | Symbols (and a count). |
| `iz` / `izz` | Strings in data sections / in the **whole** file (`izz` catches more, e.g. packed). |
| `iz~?` | Just the string count — cheap way to gauge a binary. |

`iI` needs no analysis, so run it with plain `rizin -q -N -e scr.color=0 -c iI <file>` for speed.

## Imports, exports, symbols

| Command | Purpose |
| --- | --- |
| `ii` / `iiq` | Imports (what the binary calls in other modules). The fastest read on behavior. |
| `iE` / `iEq` | **Exports** — the entry points of a DLL. Start here for a `.dll`. |
| `is` | All symbols (imports, exports, locals the binary kept). |
| `ir` | Relocations. |

Imports drive triage: `CreateProcessW` + `WriteFile` + `InternetOpenW` tells a story before
you read a single instruction. To find *where* an import is used, cross-reference it (below).

## Analysis levels

| Command | What it does |
| --- | --- |
| `aaa` (= `rizin -A`) | The standard. Functions, calls, data refs, autonaming, **and applies FLIRT signatures**. |
| `aa` | Lighter: only symbols and entry. |
| `aaaa` | Experimental, more aggressive. Try it on stripped/obfuscated binaries when `aaa` misses functions. |
| `aap` | Recover functions by scanning for prologs (when calls don't reach them). |

FLIRT matters: after `aaa`, statically-linked library/CRT functions show up named `flirt.*`
(e.g. `flirt.memcpy`) instead of anonymous `fcn.*`, so you can ignore boilerplate and focus
on the binary's own code.

## Functions

| Command | Purpose |
| --- | --- |
| `afl` | List all functions. `afl~name` to filter. |
| `aflt` | Function **table**: size, xrefsTo, xrefsFrom, calls, basic blocks, cyclomatic complexity. Great for spotting the big/central functions to look at first. |
| `afi` | Detailed info on the current function. |
| `afns` | Strings referenced by the current function — a one-line summary of what it probably does. |
| `afn <name> [@ addr]` | **Rename** a function. Do this as you recover meaning; the name then shows up in decompiler output and at every call site. |
| `afv` / `afvn <new> <old>` | List / rename local variables and arguments. |

## Navigation

| Command | Purpose |
| --- | --- |
| `s <addr\|flag>` | Seek (e.g. `s main`, `s entry0`, `s sym.imp.…`, `s fcn.140001000`). |
| `s entry0` | Program entry point. For a `.sys` driver this is effectively `DriverEntry`. |
| `sf.` | Seek to the start of the current function. |
| `sh` / `shu` / `shr` | Seek history / undo / redo. |

Often you don't need to seek at all — just append `@ <addr>` to a print/decompile command.

## Disassembly & printing

| Command | Purpose |
| --- | --- |
| `pdf` | Disassemble the whole current function (`pdf @ main`). The workhorse. |
| `pd <n>` | Disassemble n instructions (negative = before). `pd 40 @ addr`. |
| `pdr` | Disassemble recursively over the function's basic-block graph. |
| `pds` | Function summary: its strings, calls, and refs without the full listing — fast triage. |
| `px <n>` | Hexdump n bytes. `pxr` annotates words with refs (good for reading the stack/IAT). |
| `ps` / `psw @ addr` | Print a string at the address — `ps` (UTF-8, null-terminated) or `psw` (UTF-16LE = Windows wide strings). |

## Cross-references (the key to stripped code)

When functions are unnamed (`fcn.*`), xrefs are how you recover meaning.

| Command | Purpose |
| --- | --- |
| `axt [@ addr]` | Refs **to** an address — who calls/uses this. `axt @ sym.imp.KERNEL32.dll_CreateProcessW` lists every caller of that API. |
| `axf [@ addr]` | Refs **from** an address — what this function calls/reads. |
| `axt @@ii` | Refs to **every import** at once — a map of which functions touch which APIs. |
| `axt @@f:str.*` | Refs to every string — find the code that uses a telling string. |

Typical move: find an interesting string or import → `axt` to the function using it → read it
with `pdg` → `afn` it a real name → follow `axf`/`axt` outward.

## Decompilers — which to use

This bundle ships three. They disagree in useful ways; when one is unclear, run another.

| Command | Engine | When to use |
| --- | --- | --- |
| `pdz` | rz-retdec | **Default — reach for it first.** Clean C with `windows.h` types; resolves imported API names and FLIRT labels well. |
| `pdg` | rz-ghidra | Strong alternative — often the best structural/control-flow recovery; recovers Windows struct types (e.g. `LPSTARTUPINFOW`, `DWORD`). |
| `pdd` | jsdec | A fast, lightweight pass / quick look. Output is lower-level (register-style) and often names imported calls. |

Add `o` for side-by-side offsets (`pdgo`, `pdzo`, `pddo`) and `j` for JSON (`pdgj`, …).
Decompile a specific function with `@`: `pdg @ fcn.140001a10`.

**Gotchas:** the decompilers work on the *current function*, so analyze first (`-A`/`aaa`, or
`af` at the address) — otherwise `pdg` errors with *"No function at this offset"*. `pdg` can be
slow on very large functions and `pdz` is expensive on large binaries, so decompile specific
functions with `@ <addr>` rather than the whole program.

**The limitation to plan around:** decompiler output is only as good as the analysis under it.
Names appear as `fcn.xxxx` / `sub_xxxx` when there are no symbols (common in stripped or Windows
binaries), and dynamically-resolved or IAT calls can show as raw pointers — e.g. rz-ghidra may
render an imported call as `(*(code *)0x22a76)(...)` instead of the real API. Don't trust a
decompiler name in isolation — **cross-reference with rizin's own analysis:**

- `afns` / `axf` to see the strings and calls a function makes — that usually reveals its job.
- `ii` + `axt @ sym.imp.<API>` to confirm which real API an ambiguous call resolves to.
- `pdf` (raw disassembly) to check what the decompiler glossed over — e.g. a `(*(code*)0x…)`
  pointer often shows in `pdf` as `call qword [sym.imp.<dll>_<API>]`, naming the real import.
- `afn` to rename the function once you know it, then re-run the decompiler so the name
  propagates (likewise `afs` to set its prototype and `afvt` to type a local — both sharpen the
  decompiler's output).
- Compare `pdz` vs `pdg` vs `pdd` — where they agree you can trust it; where they differ, dig in.

## Searching

| Command | Purpose |
| --- | --- |
| `/ <text>` | Search for a string. |
| `/x <hexpairs>` | Search for raw bytes (`/x 4889e5`). |
| `/a <asm>` | Assemble an instruction and search its bytes (`/a "jmp rax"`). |
| `/R <opcode>` | ROP gadget search. |

## YARA (rz-libyara)

| Command | Purpose |
| --- | --- |
| `yaral <file.yar>` | Load a `.yar`/`.yara` file, apply its rules, and flag every match. |
| `yarad <folder>` | Same, recursively over a folder of rules. |
| `yaraM` | List all matches found. |
| `fs yara.match; fl` | Switch to the `yara.match` flag space and list the match flags (then `s` to one). |

## Windows binaries — hints

- **EXE** — start with `iI` (subsystem GUI/console, compiler, is it signed, PDB path), then
  `ii` for behavior and `iz`/`izz` for strings. `s entry0` is CRT startup; the real logic is
  usually a few calls in — or seek `s main` if present.
- **DLL** — the exported functions *are* the API surface: list them with `iE`/`iEq` and
  decompile the interesting ones (`pdg @ sym.<export>`). `il` shows its own dependencies.
- **Driver (.sys)** — `iI` shows `os native` / `subsys Native`; `il` reveals the type
  (`fltmgr.sys` ⇒ file-system minifilter, `ndis.sys` ⇒ network, `ntoskrnl.exe` ⇒ core kernel).
  `entry0` is `DriverEntry`; from there follow calls to the dispatch/registration routines.
- **Wide strings** — Windows `…W` APIs use UTF-16; `iz`/`izz` detect them, and `psw @ addr`
  prints one (use plain `ps` for ASCII/UTF-8).
- **Dynamic API resolution** — `LoadLibrary`/`GetModuleHandle` + `GetProcAddress` patterns
  (common in packers/malware) hide real calls from the import table. Spot them via `afns`
  (the resolved API names appear as referenced strings) and confirm in the disassembly.
- **Find dangerous capability fast** — `axt @ sym.imp.KERNEL32.dll_CreateProcessW`,
  `…_WriteProcessMemory`, `…_VirtualAllocEx`, crypto/`advapi32` APIs, networking
  (`ws2_32`/`wininet`) — jump straight to the code that uses what you care about.

## Handy one-liners

```
# Headers only, fast (no analysis)
rizin -q -N -e scr.color=0 -c iI sample.exe

# Imports + strings overview
rizin -q -N -e scr.color=0 -c "iiq" -c "izzq" sample.dll

# Analyze, then list functions as a table
rizin -A -q -N -e scr.color=0 -c aflt sample.exe

# Decompile one function (RetDec is the default; pdg / pdd are alternatives)
rizin -A -q -N -e scr.color=0 -c "pdz @ 0x140001a10" sample.exe

# Who calls a risky API?
rizin -A -q -N -e scr.color=0 -c "axt @ sym.imp.KERNEL32.dll_CreateProcessW" sample.exe

# Export list for a DLL
rizin -q -N -e scr.color=0 -c iEq sample.dll
```

When a command's exact form is unclear, ask rizin: append `?` (e.g. `pdg?`, `i?`, `ax?`).
