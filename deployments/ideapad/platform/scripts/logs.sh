#!/usr/bin/env bash
# Tail logs for all services, or pass service names for specific ones.
# Usage: ./scripts/logs.sh [service...] [-f]
set -euo pipefail
cd "$(dirname "$0")/.."

docker compose logs --tail=100 "$@"
