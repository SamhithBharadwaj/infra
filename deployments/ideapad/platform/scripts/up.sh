#!/usr/bin/env bash
# Start all services, or pass service names to start specific ones.
# Usage: ./scripts/up.sh [service...]
set -euo pipefail
cd "$(dirname "$0")/.."

docker compose up -d "$@"
echo ""
docker compose ps
