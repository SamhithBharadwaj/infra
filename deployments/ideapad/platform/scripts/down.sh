#!/usr/bin/env bash
# Stop all services, or pass service names to stop specific ones.
# Usage: ./scripts/down.sh [service...]
set -euo pipefail
cd "$(dirname "$0")/.."

docker compose down "$@"
