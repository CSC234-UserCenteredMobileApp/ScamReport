#!/usr/bin/env bash
# scripts/codegen.sh — STUB (not yet implemented)
#
# Purpose (when wired up): generate Dart classes for the mobile app from the
# TypeBox schemas in packages/shared, so /add-endpoint changes propagate to the
# mobile side without anyone hand-writing DTOs.
#
# Pipeline plan:
#   1. Walk packages/shared/src/schemas/*.ts. TypeBox schemas ARE JSON Schema
#      at runtime, so a small TS helper can `JSON.stringify(SchemaObject)`
#      each export into packages/shared/.generated/<name>.json.
#   2. Feed each JSON Schema through `quicktype` to emit Dart classes:
#        bunx quicktype \
#          --src-lang schema --lang dart \
#          --out apps/mobile/lib/core/api_types/<name>.dart \
#          packages/shared/.generated/<name>.json
#   3. Run `dart format apps/mobile/lib/core/api_types/` to keep diffs small.
#
# Until this is wired up:
#   - The mobile app keeps its Dart DTOs hand-written
#     (e.g. apps/mobile/lib/features/example/domain/example_item.dart).
#   - Whoever changes a schema in packages/shared must also update the
#     matching Dart class manually. /add-endpoint and HOW_TO_CONTRIBUTE.md
#     both call this out.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="$ROOT_DIR/apps/mobile/lib/core/api_types"
SCHEMAS_DIR="$ROOT_DIR/packages/shared/src/schemas"

cat <<'MSG' >&2
[codegen] STUB — TypeBox → Dart conversion is not yet implemented.
[codegen] See the comments at the top of this script for the planned pipeline.
MSG
echo "[codegen] Target directory:  $TARGET_DIR" >&2
echo "[codegen] Schemas source:    $SCHEMAS_DIR" >&2

exit 0
