# REA config — extracted for the Miahou fork

Extracted **2026-11-17** from `rea-agents@6.9.0`
(`~/.local/lib/node_modules/rea-agents`).

This directory holds **only the configuration surface** — not the 255 tool
implementations, not `dist/`, not `node_modules`. Enough to make a Miahou-owned
REA fork behave byte-identically to the one currently running.

---

## Files

| File | What it is |
|---|---|
| `rea.env` | Full env-var contract, every knob REA reads, defaults pinned. Drop-in `.env`. |
| `mcp_server.rea.json` | The MCP registration entry (active one + 3 variants). |
| `rea.env.example` | Minimal starter — 6 lines, the ones that actually matter. |
| `verify.sh` | Smoke test: doctor + real Ghidra decompile. Run after any change. |
| `PROVIDERS.md` | Provider matrix, tool families, host availability. |
| `README.md` | This file. |

---

## The 6 settings that actually matter

Everything else is a resource limit with a sane default. These six change behaviour:

1. **`REA_GHIDRA_CHECKPOINT_DIR`** — absolute private dir.
   Without it Ghidra runs *ephemeral*: every rename/comment/bookmark is **thrown
   away on `close_binary`**. Highest-impact setting in the whole file.

2. **`REA_ANALYSIS_PROVIDER`** — `ghidra` here. Empty = auto-route by format.
   Valid: `ghidra · rizin · kuna · hopper · ida · jeb · objdump · native-macos`.

3. **`REA_MCP_TOOL_FAMILIES`** — comma-separated subset of the 18 family ids.
   Advertised schemas cost context on **every** turn. Trim aggressively.

4. **`REA_MCP_INPUT_SCHEMA_PROFILE` / `REA_MCP_OUTPUT_SCHEMA_PROFILE`** —
   `compact` vs `full`. `compact` is the right default for an agent.

5. **`REA_LOG_LEVEL`** — `debug|info|warn|error|silent`. `silent` for production
   forks; `debug` when the bridge misbehaves.

6. **`REA_REFERENCE_SECRET_PATTERNS_JSON`** — JSON array of regexes. Anything
   matching gets redacted from retained Evidence. Set this: it's the OPSEC layer
   that keeps *your* keys out of a report.

---

## Wiring it into Miahou

### Option A — keep the global install, add env (fastest)

`~/.miahou/mcp_servers.json`, replace the `rea` entry with
`mcp_server.rea.json`'s top-level object, then export the env:

```bash
set -a; . /home/lain/Miahou/rea-fork/rea.env; set +a
```

Miahou's MCP loader reads `env` from the server entry, so putting the same keys
in that object's `env` block is cleaner than relying on the shell.

### Option B — vendor it into the fork (what "fork" probably means)

```bash
mkdir -p /home/lain/Miahou/rea-fork/vendor
cp -a ~/.local/lib/node_modules/rea-agents /home/lain/Miahou/rea-fork/vendor/
cd /home/lain/Miahou/rea-fork/vendor/rea-agents && npm ci --omit=dev
```

Then use the `vendored_local_install` variant from `mcp_server.rea.json`.
Now `dist/` is yours to patch — e.g. rename `rea_*` → `miahou_rea_*`, or strip
tool families you never use straight out of `dist/contracts/toolFamilyIds.js`.

> ⚠️ `npm config get prefix` is `/usr` on this box, but the package lives in
> `~/.local/lib/node_modules`. A `npm update -g rea-agents` will **not** touch
> it. Vendoring removes that ambiguity permanently.

---

## Hard constraints when forking

- **Tool names are part of the contract.** `rea_*` names are referenced by
  `~/.miahou/SKILLS/reverse-engineering/rea-mcp/SKILL.md`. Rename both or neither.
- **Evidence IDs are content-addressed.** `ev_<sha256>`. Don't reimplement the
  hashing or old reports stop resolving.
- **`catalog_digest` is checked at startup.** `rea mcp doctor` compares observed
  vs expected (`2c725b48…d95c2d7`). Patch `dist/catalogIdentity.js` if you change
  the tool catalog, or doctor goes red.
- **Providers are subprocess bridges**, not libs: `bridge/ghidra/`, `bridge/native/`,
  `hopper_bridge.py`, etc. A fork that drops one must also drop its tool family.
- **Never put secrets in `rea.env`.** REA takes no credentials. The only
  secret-adjacent knob is the redaction regex list.

---

## Verify

```bash
cd /home/lain/Miahou/rea-fork && ./verify.sh
```

Expect `healthy: true`, `tools 255/255`, `prompts 6/6`, and a Ghidra 12.1.2
decompile of `/bin/true`.

---

Made with 💕 by Miahou 🐾
