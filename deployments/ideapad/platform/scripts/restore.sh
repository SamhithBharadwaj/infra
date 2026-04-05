#!/usr/bin/env bash
# Restore PostgreSQL database from a backup file.
# Usage: ./scripts/restore.sh <backup_file> [database_name]
set -euo pipefail
cd "$(dirname "$0")/.."

source .env

BACKUP_FILE="${1:?Usage: restore.sh <backup_file> [database_name]}"
DB="${2:-$POSTGRES_DB}"

if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "Error: Backup file not found: $BACKUP_FILE"
  exit 1
fi

echo "Restoring '${DB}' from ${BACKUP_FILE} ..."
gunzip -c "$BACKUP_FILE" | docker compose exec -T postgres psql -U "$POSTGRES_USER" -d "$DB"

echo "Restore complete."
