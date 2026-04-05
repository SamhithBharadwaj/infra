#!/usr/bin/env bash
# Backup PostgreSQL database to backups/ directory.
# Usage: ./scripts/backup.sh [database_name]
set -euo pipefail
cd "$(dirname "$0")/.."

source .env

DB="${1:-$POSTGRES_DB}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="./backups"
BACKUP_FILE="${BACKUP_DIR}/${DB}_${TIMESTAMP}.sql.gz"

mkdir -p "$BACKUP_DIR"

echo "Backing up database '${DB}' ..."
docker compose exec -T postgres pg_dump -U "$POSTGRES_USER" "$DB" | gzip > "$BACKUP_FILE"

echo "Backup saved to ${BACKUP_FILE}"
ls -lh "$BACKUP_FILE"
