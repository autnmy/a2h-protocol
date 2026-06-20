#!/usr/bin/env bash
#
# Frozen-identifier guard. Catches accidental drift of the protocol's wire identifiers and the
# canonical schema domain — the kind of mistake a well-meaning "consistency cleanup" or a blanket
# find-replace introduces. Run in CI alongside the conformance tests.
#
# The protocol identity is uniformly `ahcp` (it was renamed from `a2h`; see MIGRATION.md). This guard:
#   1. asserts every JSON Schema `$id` is on the canonical domain (ahcpprotocol.org);
#   2. asserts the reference resolver BASE matches that domain (or $ref resolution silently breaks);
#   3. asserts the frozen wire identifiers still exist verbatim (a rename breaks interop + vectors);
#   4. asserts the old `a2h` identity has not crept back onto the wire surface (schemas / reference
#      src / examples / vectors).
#
# Adjust CANON_DOMAIN / the token lists here when an intentional, versioned change lands.

set -uo pipefail
cd "$(dirname "$0")/.."

CANON_DOMAIN="ahcpprotocol.org"
FROZEN_WIRE_TOKENS=("ahcp_version" "AHCP-Signature" "AHCP_CALLBACK_SECRET" "x-ahcp-sensitive")
# Retired identity that must never reappear on the wire surface.
FORBIDDEN_TOKENS=("a2hprotocol.org" "a2h_version" "A2H-Signature" "A2H_CALLBACK_SECRET" "x-a2h-sensitive" "A2HSEALv1" ".well-known/a2h")
WIRE_PATHS=("schema/" "reference/src/" "examples/" "conformance/vectors/")

fail=0
err() { echo "::error::$1"; fail=1; }

# 1) Schema $id on the canonical domain.
for f in schema/*/*.schema.json; do
  id_line=$(grep -m1 '"\$id"' "$f" || true)
  if [ -z "$id_line" ]; then
    err "$f: missing \$id"
  elif ! printf '%s' "$id_line" | grep -q "$CANON_DOMAIN/schema/"; then
    err "$f: \$id not on $CANON_DOMAIN/schema/ — got: $id_line"
  fi
done

# 2) Reference resolver BASE matches the canonical schema domain.
grep -q "const BASE = \"https://$CANON_DOMAIN/schema/" reference/src/envelope.ts \
  || err "reference/src/envelope.ts BASE must be https://$CANON_DOMAIN/schema/... (it resolves \$refs)"

# 3) Frozen wire identifiers still present (a rename would break interop + conformance vectors).
for tok in "${FROZEN_WIRE_TOKENS[@]}"; do
  grep -rq -- "$tok" spec/ schema/ \
    || err "frozen wire identifier '$tok' not found in spec/ or schema/ — was it renamed?"
done

# 4) The retired `a2h` identity must not reappear on the wire surface.
for tok in "${FORBIDDEN_TOKENS[@]}"; do
  hits=$(grep -rIl -- "$tok" "${WIRE_PATHS[@]}" 2>/dev/null || true)
  if [ -n "$hits" ]; then
    echo "$hits" | sed "s/^/  stale '$tok' in: /"
    err "retired identifier '$tok' found on the wire surface (must be the ahcp equivalent)"
  fi
done

if [ "$fail" -ne 0 ]; then
  echo "frozen-identifier check FAILED"
  exit 1
fi
echo "frozen-identifier check passed (schema \$id on $CANON_DOMAIN; ahcp wire identifiers intact; no a2h on the wire surface)"
