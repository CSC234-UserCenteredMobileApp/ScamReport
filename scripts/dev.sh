#!/usr/bin/env bash
# Run the api and the mobile app concurrently.
# Prefers the root `bun run dev` script (which uses `concurrently`) for labelled output.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

exec bun run dev
