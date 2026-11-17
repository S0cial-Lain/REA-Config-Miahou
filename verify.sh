#!/usr/bin/env bash
# REA fork smoke test — proves the config actually works, not just that it parses.
set -uo pipefail

REA_ENV="${REA_ENV:-/home/lain/Miahou/rea-fork/rea.env}"
FAIL=0

say() { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }
ok()  { printf '  \033[32mOK\033[0m   %s\n' "$1"; }
bad() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAIL=1; }

# --- 1. load config -----------------------------------------------------------
say "config"
if [[ -f "$REA_ENV" ]]; then
  set -a; . "$REA_ENV"; set +a
  ok "loaded $REA_ENV"
else
  bad "missing $REA_ENV"
fi

# --- 2. binary ----------------------------------------------------------------
say "binary"
REA_BIN="${REA_BIN:-$(command -v rea || true)}"
if [[ -n "$REA_BIN" ]]; then
  ok "rea -> $REA_BIN  ($("$REA_BIN" --version 2>/dev/null | head -1))"
else
  bad "rea not on PATH"
  exit 1
fi

# --- 3. checkpoint dir --------------------------------------------------------
say "ghidra checkpoint dir"
CKPT="${REA_GHIDRA_CHECKPOINT_DIR:-}"
if [[ -z "$CKPT" ]]; then
  bad "REA_GHIDRA_CHECKPOINT_DIR unset -> annotations will be DISCARDED on close"
elif [[ "$CKPT" != /* ]]; then
  bad "must be absolute: $CKPT"
else
  mkdir -p "$CKPT" 2>/dev/null
  if [[ -d "$CKPT" && -w "$CKPT" ]]; then
    ok "$CKPT (writable)"
  else
    bad "$CKPT not writable"
  fi
fi

# --- 4. providers -------------------------------------------------------------
say "providers"
for t in ghidra rizin objdump; do
  if command -v "$t" >/dev/null 2>&1; then ok "$t"; else bad "$t missing"; fi
done
if command -v java >/dev/null 2>&1; then
  ok "java $(java -version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+[0-9.]*' | head -1)"
else
  bad "java missing (Ghidra needs it)"
fi

# --- 5. MCP doctor ------------------------------------------------------------
say "mcp doctor"
DOCTOR="$("$REA_BIN" mcp doctor 2>&1)"
if grep -q 'healthy: true' <<<"$DOCTOR"; then
  ok "healthy"
  grep -E 'expected: |observed: |missing: |duplicates: ' <<<"$DOCTOR" | sed 's/^/       /'
else
  bad "doctor reported unhealthy"
  sed 's/^/       /' <<<"$DOCTOR" | tail -20
fi

# --- 6. real decompile --------------------------------------------------------
say "end-to-end decompile"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp /bin/true "$TMP/t" 2>/dev/null
OUT="$("$REA_BIN" analyze "$TMP/t" 2>&1)"
if grep -q 'sha256:' <<<"$OUT"; then
  ok "opened ELF: $(grep -m1 'sha256:' <<<"$OUT" | tr -d ' ')"
  grep -m1 -A1 'provider:' <<<"$OUT" | tail -1 | sed 's/^/       /'
  if grep -q 'version: 12' <<<"$OUT"; then ok "ghidra engaged"; else bad "ghidra did not report a version"; fi
else
  bad "analyze failed"
  sed 's/^/       /' <<<"$OUT" | head -15
fi

# --- verdict ------------------------------------------------------------------
say "verdict"
if [[ $FAIL -eq 0 ]]; then
  printf '  \033[32mALL CHECKS PASSED\033[0m\n'; exit 0
else
  printf '  \033[31mFAILURES ABOVE\033[0m\n'; exit 1
fi
