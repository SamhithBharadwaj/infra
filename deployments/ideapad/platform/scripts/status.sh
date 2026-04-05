#!/usr/bin/env bash
# Show status and health of all services.
# Usage: ./scripts/status.sh
set -euo pipefail
cd "$(dirname "$0")/.."

docker compose ps
