# Rizin Windows RE Toolkit

*Portable, ready-to-run Rizin for Windows reverse engineering.*

A Windows x64 build of Rizin bundling three decompiler plugins (rz-ghidra, jsdec, and rz-retdec), rz-libyara, and the official Rizin FLIRT signature database.

| Decompiler | Command | Output style |
| --- | --- | --- |
| `rz-retdec` | `pdz` | RetDec-generated C |
| `rz-ghidra` | `pdg` | Ghidra-style C pseudocode |
| `jsdec` | `pdd` | Lightweight, register-level C pseudocode |

Everything ships as a single bundle, `rizin-windows-x64-0.8.2-bundle.zip`: download it, extract it anywhere, add `bin` to your `PATH`, and you have Rizin with all three decompilers, YARA scanning, and bundled signatures — no plugins to build yourself.

## Contents

- [Quick Start](#quick-start)
- [Requirements](#requirements)
- [Why Use This Build](#why-use-this-build)
- [Included Components](#included-components)
- [What's Customized](#whats-customized)
- [Local Build / Development](#local-build--development)
- [Example Commands](#example-commands)
- [Agent Skill](#agent-skill)
- [License](#license)

## Quick Start

Download `rizin-windows-x64-0.8.2-bundle.zip` from this repository and extract it anywhere. It unpacks to a single `rizin\` folder. Then add that folder's `bin` directory to your `PATH` — replace `C:\path\to\rizin\bin` with your actual extracted location.

Persistently, for your user account (applies to new terminals opened afterward):

```powershell
[Environment]::SetEnvironmentVariable("Path",
  [Environment]::GetEnvironmentVariable("Path", "User") + ";C:\path\to\rizin\bin", "User")
```

Or just for the current shell session (not saved):

```powershell
$env:PATH = "C:\path\to\rizin\bin;$env:PATH"
```

Then check it works (open a **new** terminal first if you used the persistent command):

```powershell
rizin -v
```

Confirm the decompiler and YARA plugins are loaded:

```powershell
rizin -q -N -c "pdg?" -c "pdd?" -c "pdz?" -c "yara?" -c "q"
```

## Requirements

- Windows x64
- Microsoft Visual C++ Redistributable / runtime, which provides the required DLLs:
  `MSVCP140.dll`, `VCRUNTIME140.dll`, and `VCRUNTIME140_1.dll`

## Why Use This Build

Three decompilers live side by side in one portable Rizin setup, so you can cross-check results without switching tools or maintaining three separate plugin build environments:

- **`pdz` (RetDec)** — reach for this first; a clean default that resolves imports and types well.
- **`pdg` (Ghidra)** — a strong alternative with the best structural recovery.
- **`pdd` (jsdec)** — when you want a fast, lightweight pass.

That makes this a practical toolkit for repeated Windows malware and reversing work, where quick comparison across decompilers matters most.

`rz-libyara` adds rule-based scanning inside the same Rizin session, so you can apply local YARA rules and jump straight to the generated `yara.match` flags.

## Included Components

| Component | Commands | Source | Commit |
| --- | --- | --- | --- |
| Rizin | `rizin` | [JerryLinLinLin/rizin](https://github.com/JerryLinLinLin/rizin) ([upstream](https://github.com/rizinorg/rizin)) | [`5a611ee`](https://github.com/JerryLinLinLin/rizin/commit/5a611eee2999d312317ff90d600e37dde0f58992) |
| rz-ghidra | `pdg`, `pdgo`, `pdgj`, `pdgs` | [JerryLinLinLin/rz-ghidra](https://github.com/JerryLinLinLin/rz-ghidra) ([upstream](https://github.com/rizinorg/rz-ghidra)) | [`8da1a3d`](https://github.com/JerryLinLinLin/rz-ghidra/commit/8da1a3d515567c015926f9ec91b5d791d1b3c3aa) |
| jsdec | `pdd`, `pddo`, `pddj` | [JerryLinLinLin/jsdec](https://github.com/JerryLinLinLin/jsdec) ([upstream](https://github.com/rizinorg/jsdec)) | [`068f799`](https://github.com/JerryLinLinLin/jsdec/commit/068f799e5e362bf10fdba8bfdf8c3274fc11f344) |
| rz-retdec | `pdz`, `pdzo`, `pdzj` | [JerryLinLinLin/rz-retdec](https://github.com/JerryLinLinLin/rz-retdec) ([upstream](https://github.com/rizinorg/rz-retdec)) | [`0b065b6`](https://github.com/JerryLinLinLin/rz-retdec/commit/0b065b6a98e526ddcd6f43ede6d5aa645a50206d) |
| rz-libyara | `yarac`, `yarad`, `yaral`, `yaraM`, `yaras`, `yaram` | [JerryLinLinLin/rz-libyara](https://github.com/JerryLinLinLin/rz-libyara) ([upstream](https://github.com/rizinorg/rz-libyara)) | [`1de567e`](https://github.com/JerryLinLinLin/rz-libyara/commit/1de567ebe29f57628561e0119b21c4fe9f25f27c) |
| Rizin sigdb | `Fl`, `Fa`, `Fs`, `Ff` | [JerryLinLinLin/sigdb](https://github.com/JerryLinLinLin/sigdb) ([upstream](https://github.com/rizinorg/sigdb)) | [`4addbed`](https://github.com/JerryLinLinLin/sigdb/commit/4addbed50cd3b50eeef5a41d72533d079ebbfbf8) |

The source repositories are also included as Git submodules under `sources/`, all tracking the `windows-bundle-v0.8.2` branch.

## What's Customized

This is more than just unzipping stock Rizin. It carries several Windows-focused packaging fixes:

- **Portable SLEIGH resolution** — `rz-ghidra` loads its SLEIGH specs relative to the extracted folder
  (`lib\rizin\plugins\rz_ghidra_sleigh`), so no global `SLEIGHHOME` is required even after the folder is moved.
- **DLL load fix** — `core_ghidra.dll` is also placed in `bin` so Windows can resolve it when
  `asm_ghidra.dll` and `analysis_ghidra.dll` load.
- **rz-retdec rebuilt** — patched for the Rizin 0.8.x API and for MSVC/Windows linking.
- **rz-retdec VS 2026 fixes** — the bundled RetDec build is patched for CMake 4.x compatibility,
  old yaramod/fmt MSVC behavior, OpenSSL 1.1 Authenticode linking, and Windows install path normalization.
- **Bundled OpenSSL side by side** — OpenSSL 1.1 runtime DLLs are kept for `rz-retdec`, while
  OpenSSL 3.5 runtime DLLs are kept for `rz-libyara`'s hash and Authenticode support:
  `libcrypto-1_1-x64.dll`, `libssl-1_1-x64.dll`, `libcrypto-3-x64.dll`, and `libssl-3-x64.dll`.
- **rz-libyara integrated** — built as a release `/MD` plugin with embedded static YARA
  ([VirusTotal/yara](https://github.com/VirusTotal/yara) commit
  [`a7f351a`](https://github.com/VirusTotal/yara/commit/a7f351aab0fbad6713e9091b8e012cc7e870ec76)).
  A local compatibility patch stores plugin metadata without the newer `core->plugin_contexts` API, so it loads on Rizin 0.8.2.
  The YARA OpenSSL/hash/Authenticode path is enabled through FireDaemon OpenSSL 3.5.7 LTS
  ([download page](https://www.firedaemon.com/download-firedaemon-openssl)), verified with SHA-256
  `2591459A06A6DF2D2E2B23B02A28D7C180B95C02FB4965099A708B7365A74014`.
- **Bundled FLIRT signatures** — the official Rizin signature database is included at
  `share\sigdb`, so `Fl` and `Fa` work without downloading a separate database.
- **Relocation-tested** — the whole `rizin` folder was moved to a new path and re-tested to confirm every plugin still works.

## Local Build / Development

Clone with submodules:

```powershell
git clone --recursive https://github.com/JerryLinLinLin/rizin-win64-bundle.git
cd rizin-win64-bundle
```

If you already cloned without `--recursive`:

```powershell
git submodule update --init --recursive
```

This repo stores a ready-to-run runtime under `build\rizin`. The `sources\rizin` submodule is pinned for provenance; the bundle runtime itself starts from the official shared Windows Rizin 0.8.2 build, then the plugins and data are installed into that prefix.

Build from a **Developer PowerShell / Developer Command Prompt for Visual Studio 2026**. Set these paths first:

```powershell
$Prefix = "$PWD\build\rizin"
$OpenSSL11 = "C:\path\to\openssl-1.1.1w\x64"
$OpenSSL3 = "C:\path\to\openssl-3.5.7-firedaemon\x64"
$env:PATH = "$Prefix\bin;$OpenSSL11\bin;$OpenSSL3\bin;$env:PATH"
$env:PKG_CONFIG_PATH = "$Prefix\lib\pkgconfig;$env:PKG_CONFIG_PATH"
$env:CMAKE_PREFIX_PATH = "$Prefix;$OpenSSL3;$env:CMAKE_PREFIX_PATH"
```

You also need CMake, Meson, and Ninja available in that shell. The OpenSSL 3 path is intentionally exposed through `CMAKE_PREFIX_PATH` for `rz-libyara`; `rz-retdec` still receives the OpenSSL 1.1 prefix explicitly.

Rebuild and install `rz-ghidra`:

```powershell
cmake -S sources\rz-ghidra -B sources\rz-ghidra\build-vs2026 -G "Visual Studio 18 2026" -A x64 `
  -DCMAKE_PREFIX_PATH="$Prefix" `
  -DCMAKE_INSTALL_PREFIX="$Prefix" `
  -DBUILD_CUTTER_PLUGIN=OFF
cmake --build sources\rz-ghidra\build-vs2026 --config Release --target install
Copy-Item "$Prefix\lib\rizin\plugins\core_ghidra.dll" "$Prefix\bin\core_ghidra.dll" -Force
```

Rebuild and install `jsdec`:

```powershell
meson setup sources\jsdec\build-vs2026 sources\jsdec --backend=ninja --buildtype=release -Db_vscrt=md `
  --prefix="$Prefix" `
  -Drizin_plugdir="$Prefix\lib\rizin\plugins" `
  -Dbuild_type=rizin
meson compile -C sources\jsdec\build-vs2026
meson install -C sources\jsdec\build-vs2026
```

Rebuild and install `rz-retdec`:

```powershell
cmake -S sources\rz-retdec -B sources\rz-retdec\build-vs2026 -G "Visual Studio 18 2026" -A x64 `
  -DCMAKE_PREFIX_PATH="$Prefix;$OpenSSL11" `
  -DCMAKE_INSTALL_PREFIX="$Prefix" `
  -DBUILD_CUTTER_PLUGIN=OFF `
  -DRZ_RETDEC_DOC=OFF `
  -DBUILD_BUNDLED_RETDEC=ON
cmake --build sources\rz-retdec\build-vs2026 --config Release --target install
Copy-Item "$OpenSSL11\bin\libcrypto-1_1-x64.dll" "$Prefix\bin\" -Force
Copy-Item "$OpenSSL11\bin\libssl-1_1-x64.dll" "$Prefix\bin\" -Force
```

Rebuild and install `rz-libyara` with OpenSSL 3:

```powershell
meson setup sources\rz-libyara\build-vs2026-openssl3 sources\rz-libyara --backend=ninja --buildtype=release -Db_vscrt=md `
  --prefix="$Prefix" `
  -Drizin_plugdir="$Prefix\lib\rizin\plugins" `
  -Duse_sys_yara=disabled `
  -Denable_openssl=true
meson compile -C sources\rz-libyara\build-vs2026-openssl3
meson install -C sources\rz-libyara\build-vs2026-openssl3
Copy-Item "$OpenSSL3\bin\libcrypto-3-x64.dll" "$Prefix\bin\" -Force
Copy-Item "$OpenSSL3\bin\libssl-3-x64.dll" "$Prefix\bin\" -Force
```

Refresh bundled FLIRT signatures from the submodule:

```powershell
robocopy sources\sigdb "$Prefix\share\sigdb" /E /XD .git
```

After local installs, remove generated import libraries from the runtime plugin directory:

```powershell
Remove-Item "$Prefix\lib\rizin\plugins\*.lib" -Force -ErrorAction SilentlyContinue
```

Quick verification:

```powershell
$env:SLEIGHHOME = $null
rizin -q -N -c "pdg?" -c "pdd?" -c "pdz?" -c "yara?" -c "q" C:\path\to\sample.exe
```

## Example Commands

> Inside Rizin's own command line, write paths with forward slashes (e.g. `C:/rules/rule.yara`) even on Windows. The PowerShell snippets in [Quick Start](#quick-start) use backslashes because they run in the shell.

Basic Rizin analysis:

```rizin
aaa            # analyze everything (functions, refs, strings)
afl            # list the functions found
s entry0       # seek to the entrypoint
pdf            # disassemble the current function
```

Ghidra decompiler (`rz-ghidra`):

```rizin
pdg            # decompile the current function
pdgo           # decompile side by side with offsets
pdgj           # emit the decompiled function as JSON
pdgs           # list the loaded SLEIGH languages
```

jsdec (`pdd`):

```rizin
pdd            # decompile the current function
pddo           # decompile side by side with offsets
pddj           # emit the decompiled function as JSON
```

RetDec (`rz-retdec`):

```rizin
pdz            # decompile the current function
pdzo           # decompile side by side with offsets
pdzj           # emit the decompiled function as JSON
```

YARA (`rz-libyara`):

```rizin
yaral C:/rules/example.yara   # parse a .yar/.yara file and apply its rules
yaraM                         # list all matches found
fs yara.match                 # switch to the yara.match flag space
fl                            # list the match flags
```

FLIRT signatures:

```rizin
aaa            # run analysis first
Fl             # list the signatures available in the bundled sigdb
Fa             # apply matching signatures from the sigdb
fs flirt       # switch to the flirt flag space
fl             # list the matched library-function flags
```

## Agent Skill

This repo also ships a Claude Code **skill** that teaches an AI agent how to drive this bundle for reverse engineering: [`skills/rizin-windows-re/SKILL.md`](skills/rizin-windows-re/SKILL.md) (also packaged as [`skills/rizin-windows-re.skill`](skills/rizin-windows-re.skill)).

It's a concise cheatsheet — how to run rizin non-interactively, the most useful commands grouped by purpose (triage, imports/exports, analysis, functions, cross-references, disassembly, the three decompilers, YARA), which decompiler to reach for and how to cross-reference when symbols are missing, plus extra Windows PE/driver hints. The command reference is generic, so it works on any binary rizin can parse — not just Windows.

**To use it:** copy the `rizin-windows-re` folder into a skills directory Claude Code loads (e.g. a project `.claude/skills/` or your user skills dir), or import the `.skill` package. The agent then applies it automatically for reverse-engineering requests (e.g. "analyze this binary", "decompile this function"), assuming the bundle's `bin` is on `PATH`.

## License

This bundle redistributes several upstream projects, each under its own license — for example Rizin under LGPL-3.0, the Ghidra decompiler under Apache-2.0, RetDec under MIT, and YARA under BSD-3-Clause. Consult each linked upstream repository under [Included Components](#included-components) for the authoritative license terms. The local Windows portability patches described in [What's Customized](#whats-customized) are offered under the same terms as the projects they modify.
