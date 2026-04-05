# Platform — Dev Server Services

Docker-based supporting services for the dev server.

## Quick Start

```bash
# 1. Copy and edit env vars
cp .env.example .env
# edit .env with your values

# 2. Start everything
./scripts/up.sh

# 3. Verify
./scripts/status.sh
```

## Services

| Service    | Container             | Default Port | Image              |
| ---------- | --------------------- | ------------ | ------------------- |
| PostgreSQL | `platform-postgres`   | 5432         | `postgres:16-alpine` |

## Scripts

All scripts live in `scripts/` and operate from the repo root.

| Script       | Purpose                              | Usage                                  |
| ------------ | ------------------------------------ | -------------------------------------- |
| `up.sh`      | Start all or specific services       | `./scripts/up.sh [service...]`         |
| `down.sh`    | Stop all or specific services        | `./scripts/down.sh [service...]`       |
| `status.sh`  | Show container status & health       | `./scripts/status.sh`                  |
| `logs.sh`    | Tail logs                            | `./scripts/logs.sh [service...] [-f]`  |
| `backup.sh`  | Dump a Postgres database             | `./scripts/backup.sh [db_name]`        |
| `restore.sh` | Restore from a backup file           | `./scripts/restore.sh <file> [db]`     |

## Connection Strings

From other projects on this server, connect using:

```
postgresql://devuser:changeme@localhost:5432/devdb
```

## Directory Layout

```
.
├── .env.example                  # env var template (committed)
├── .env                          # actual env vars (gitignored)
├── docker-compose.yml            # service definitions
├── scripts/                      # management scripts
│   ├── up.sh
│   ├── down.sh
│   ├── status.sh
│   ├── logs.sh
│   ├── backup.sh
│   └── restore.sh
├── services/
│   └── postgres/
│       ├── init/                 # SQL run on first start
│       │   └── 01-init.sql
│       └── config/
│           └── postgresql.conf   # custom PG config
└── backups/                      # gitignored, local backups
```

## Adding a New Service

1. Add the service definition to `docker-compose.yml`
2. Create `services/<name>/` with any config or init files
3. Add env vars to `.env.example` and `.env`
4. Update this README
