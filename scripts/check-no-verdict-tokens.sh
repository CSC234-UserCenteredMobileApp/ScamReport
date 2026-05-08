#!/usr/bin/env bash
# FR-4.3: Ask AI must NEVER label a situation as Scam / Suspicious / Safe /
# Unknown. Verdict labels are reserved for the formal POST /check verdict
# screen (P-13). This gate scans the askAi* localisation keys in both ARBs
# and fails CI if any forbidden token is used as a label.
#
# We allow the words inside descriptive phrases ("describe what scam happened")
# as long as they are not the standalone label. The grep is intentionally
# conservative: it matches tokens with quote / colon adjacency to catch
# `"label": "Scam"` patterns while skipping prose. False positives can be
# silenced with an `ALLOW_VERDICT_TOKEN: <reason>` comment on the same line.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Pattern: askAi* key whose value is a *standalone* verdict label. Matches
#   "askAiX": "Scam"
#   "askAiX": "Scam!"
# but NOT
#   "askAiX": "Scam type"
#   "askAiX": "Submit a scam report"
# because verdict-as-value is the FR-4.3 risk; verdict-as-noun-in-phrase is fine.
PATTERN='"askAi[A-Za-z]*"\s*:\s*"\s*(Scam|Suspicious|Safe|Unknown)\s*[!.?]?\s*"'

found=0
for file in \
  "$ROOT/apps/mobile/lib/l10n/app_en.arb" \
  "$ROOT/apps/mobile/lib/l10n/app_th.arb"
do
  if [ ! -f "$file" ]; then continue; fi
  # Filter: drop lines that explicitly opt out via ALLOW_VERDICT_TOKEN comment.
  matches=$(grep -nE "$PATTERN" "$file" | grep -v 'ALLOW_VERDICT_TOKEN' || true)
  if [ -n "$matches" ]; then
    echo "[FR-4.3 violation] verdict-label token in askAi* key — $file:" >&2
    echo "$matches" >&2
    found=1
  fi
done

if [ "$found" -eq 1 ]; then
  echo "" >&2
  echo "Ask AI must not surface a Scam/Suspicious/Safe/Unknown verdict label" >&2
  echo "(FR-4.3). Reword the affected keys, or annotate the line with" >&2
  echo "'ALLOW_VERDICT_TOKEN: <reason>' if it is genuinely necessary." >&2
  exit 1
fi

echo "[FR-4.3 gate] no verdict tokens in askAi* keys."
