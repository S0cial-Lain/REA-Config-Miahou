# REA providers & tool families — host matrix

Extracted from `rea-agents@6.9.0`. Availability column reflects **this host**
(CachyOS, x86_64).

---

## 1. Analysis providers

| id | Role | Available here | Notes |
|---|---|---|---|
| `ghidra` | Primary decompiler, CFG, value flow, DWARF types | ✅ 12.1.2 @ `/opt/ghidra` | Java 27. Ephemeral unless `REA_GHIDRA_CHECKPOINT_DIR` set. |
| `rizin` | Fast disasm, no JVM, raw/odd architectures | ✅ `/usr/bin/rizin` | Good fallback for huge or malformed bins. |
| `objdump` | Zero-dependency disasm / section dump | ✅ `/usr/bin/objdump` | `inspect_with_objdump`, `operation: architectures`. |
| `kuna` | Headless decompiler, own cache | ❌ not installed | Set `REA_KUNA_COMMAND` + `REA_KUNA_CACHE_DIR`. |
| `ida` | IDA Pro via MCP | ❌ not installed | `REA_IDA_MCP_CONFIG`. |
| `jeb` | JEB via MCP (Dalvik/native) | ❌ not installed | `REA_JEB_MCP_URL` default `http://127.0.0.1:8425/mcp`. |
| `hopper` | Hopper GUI bridge | ❌ macOS-only | `bridge/hopper_bridge.py`; `REA_MANAGED_LINUX_HOPPER_LAUNCHER` for Linux attempt. |
| `native-macos` | codesign/lipo/plutil/dyld | ❌ macOS-only | Reports `unsupported_host` here — expected, not an error. |
| `rea-workflow` | Composed wrapper → Evidence envelope | ✅ always | Not selectable; wraps whichever upstream ran. |

**Auto-routing:** leave `REA_ANALYSIS_PROVIDER` empty and REA picks by format +
what's installed. Set it explicitly for reproducible reports.

---

## 2. Tool families (`REA_MCP_TOOL_FAMILIES`)

18 ids, in catalog order. Each family is a block of tool schemas advertised to the
agent — **every advertised schema costs context on every turn**. Trim to what a
workflow needs; out-of-scope tools stay registered but disabled.

| # | family | Covers | Keep for Miahou? |
|---|---|---|---|
| 1 | `direct` | `open_binary`, `decompile`, `search_procedures`, `xrefs`, `list_*` | **yes** |
| 2 | `enhanced` | `analyze_function`, call graph, value flow, compare | **yes** |
| 3 | `native` | Mach-O/PE/ELF static inspection, hardening, imports | **yes** |
| 4 | `artifact` | archive/ASAR/firmware inventory, extraction, entropy | **yes** |
| 5 | `managed` | .NET PE/CLI, IL members, native boundaries | **yes** |
| 6 | `firmware` | binwalk regions, unblob extraction, devicetree | **yes** |
| 7 | `android` | APK package/class/method, JNI, signature, JADX | optional (needs JADX jar) |
| 8 | `pcap` | tshark fields, pcap summary, HAR/mitmproxy | optional (needs tshark) |
| 9 | `flutter` | Dart AOT snapshot, Flutter build ID | optional |
| 10 | `frida` | attach/spawn, script load, session status | optional |
| 11 | `apktool` | `decode_android_resources` | optional |
| 12 | `jeb` | JEB project/unit/decompile | optional |
| 13 | `adb` | device, package, logcat, pull/push | optional |
| 14 | `browser` | CDP pages, JS bundle, screenshots | optional |
| 15 | `electron` | fuses, page inspect, scenario capture | optional |
| 16 | `javascript-runtime` | V8 inspector, runtime reconcile | optional |
| 17 | `application` | app graph projection, feature trace | optional |
| 18 | `session` | `binary_session`, evidence bundle, unknowns | **yes** |

Recommended Miahou default (used in `rea.env`):

```
direct,enhanced,native,artifact,managed,firmware,session
```

That's 7 of 18 — the static binary-analysis core, zero mobile/browser/network
baggage. Add families back per-engagement.

---

## 3. Catalog invariants

`rea mcp doctor` enforces these. Break one and it goes red:

| Invariant | Value |
|---|---|
| tools expected | 255 |
| prompts expected | 6 |
| package version | 6.9.0 |
| catalog digest | `2c725b48818ac5266198069330907c657f0fa2b6b8236065e5a191e20d95c2d7` |
| MCP protocol | `2025-11-25` |

> Tool/prompt counts are for the **full** catalog. Scoping via
> `REA_MCP_TOOL_FAMILIES` disables tools but does **not** change the expected
> count — doctor still validates 255.

---

## 4. Bridge subprocesses

REA shells out; it does not link. A fork that drops a bridge must drop the family.

```
bridge/
├── agentenv/          build-computer sandboxes
├── android/           adb + JADX MCP
├── cutter/            live Cutter session bridge
├── ghidra/            headless Ghidra (the big one)
├── hopper_bridge.py   Hopper GUI (macOS)
├── mitmproxy/         HAR capture
├── native/            macho / pe / elf / wasm / evm readers
├── process/           PTY process capture
├── pwndbg/            GDB + pwndbg
└── pwntools/          ELF layout via pwntools
```

---

Made with 💕 by Miahou 🐾
