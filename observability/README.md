# Observability Stack — Yantra Home Lab

Multi-node monitoring setup using Prometheus + Grafana + Loki. The central stack runs on **druva** (always-on Raspberry Pi 5). Remote nodes run lightweight agents that report back to druva.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  druva (Raspberry Pi 5) — always-on, central hub        │
│                                                         │
│  ┌────────────┐  ┌─────────┐  ┌──────┐                 │
│  │ Prometheus  │  │ Grafana │  │ Loki │                 │
│  │   :9090     │  │  :3000  │  │ :3100│                 │
│  └──────┬─────┘  └─────────┘  └──┬───┘                 │
│         │ scrapes                 │ receives logs        │
│  ┌──────┴──────────┐  ┌─────────┴────┐                 │
│  │ node-exporter   │  │  promtail    │                 │
│  │ :9100           │  │  :9080       │                 │
│  │ cAdvisor :8080  │  └──────────────┘                 │
│  └─────────────────┘                                    │
└─────────────────────────────────────────────────────────┘
         ▲ scrapes :9100 + :8080          ▲ pushes logs
         │                                │
┌────────┴───────┐              ┌─────────┴──────┐
│   ideapad      │              │  proxmox VMs   │
│ node-exporter  │              │ node-exporter  │
│ cAdvisor       │              │ cAdvisor       │
│ promtail ──────┼── logs ──────┤ promtail       │
└────────────────┘              └────────────────┘
```

## Ports Reference

| Service        | Port  | Runs on        |
|----------------|-------|----------------|
| Prometheus     | 9090  | druva only     |
| Grafana        | 3000  | druva only     |
| Loki           | 3100  | druva only     |
| Node Exporter  | 9100  | all nodes      |
| cAdvisor       | 8080  | all nodes      |
| Promtail       | 9080  | all nodes      |

## Folder Structure

```
observability/
├── .gitignore
├── README.md
├── druva/                  # Central stack + local agents
│   ├── docker-compose.yml
│   ├── .env.example
│   ├── prometheus/
│   │   ├── prometheus.yml
│   │   └── targets/        # file_sd_configs (edit to add nodes)
│   │       ├── node-exporter.json
│   │       └── cadvisor.json
│   ├── loki/
│   │   └── config.yml
│   ├── promtail/
│   │   └── config.yml
│   └── grafana/
│       └── provisioning/
│           ├── datasources/
│           │   └── datasources.yml
│           └── dashboards/
│               ├── dashboards.yml
│               ├── node-metrics.json
│               └── docker-metrics.json
├── ideapad/                # Agent-only stack
│   ├── docker-compose.yml
│   ├── .env.example
│   └── promtail/
│       └── config.yml
└── proxmox/                # Agent-only stack (deploy per VM)
    ├── docker-compose.yml
    ├── .env.example
    └── promtail/
        └── config.yml
```

## Deployment

### 1. Deploy druva (central stack)

```bash
cd observability/druva
cp .env.example .env
# Edit .env: set GRAFANA_ADMIN_PASSWORD, node IPs
nano .env

# Update Prometheus target files with actual IPs
nano prometheus/targets/node-exporter.json
nano prometheus/targets/cadvisor.json

docker compose up -d
```

Verify:
- Prometheus: `http://druva:9090/targets` — druva targets should show as UP
- Grafana: `http://druva:3000` — login with admin / your password
- Loki: `http://druva:3100/ready` — should return "ready"

### 2. Deploy ideapad (agents)

```bash
# Copy the ideapad/ folder to the ideapad node
scp -r observability/ideapad/ ideapad:~/observability/

# On ideapad:
cd ~/observability
cp .env.example .env
nano .env   # Verify LOKI_URL points to druva's IP
docker compose up -d
```

### 3. Deploy proxmox VMs (agents)

Deploy on **each** Ubuntu VM separately:

```bash
# Copy to the VM
scp -r observability/proxmox/ proxmox-nogpu:~/observability/

# On the VM:
cd ~/observability
cp .env.example .env
nano .env   # Set NODE_HOSTNAME (proxmox-nogpu or proxmox-gpu)
docker compose up -d
```

Repeat for the GPU VM with `NODE_HOSTNAME=proxmox-gpu`.

### 4. Verify all nodes

After all agents are running, check Prometheus targets at `http://druva:9090/targets`:
- All `node-exporter` targets should be UP
- All `cadvisor` targets should be UP

In Grafana:
- **Node Metrics** dashboard → select all nodes → verify CPU, memory, disk, network panels populate
- **Docker Metrics** dashboard → verify containers appear per node
- **Explore** → Loki → `{host="ideapad"}` → verify logs from remote nodes arrive

## Key Metrics

### Node Metrics (node-exporter)

| Metric | What it tells you |
|--------|------------------|
| `node_cpu_seconds_total` | CPU usage per core/mode |
| `node_load1` / `node_load5` / `node_load15` | System load averages |
| `node_memory_MemTotal_bytes` | Total memory |
| `node_memory_MemAvailable_bytes` | Available memory |
| `node_filesystem_size_bytes` | Disk total per mount |
| `node_filesystem_avail_bytes` | Disk free per mount |
| `node_disk_read_bytes_total` | Disk read throughput |
| `node_disk_written_bytes_total` | Disk write throughput |
| `node_network_receive_bytes_total` | Network RX bytes |
| `node_network_transmit_bytes_total` | Network TX bytes |
| `node_boot_time_seconds` | Uptime (derived) |

### Docker Metrics (cAdvisor)

| Metric | What it tells you |
|--------|------------------|
| `container_cpu_usage_seconds_total` | Container CPU usage |
| `container_memory_usage_bytes` | Container memory usage |
| `container_spec_memory_limit_bytes` | Container memory limit |
| `container_memory_rss` | Resident memory (actual) |
| `container_network_receive_bytes_total` | Container network RX |
| `container_network_transmit_bytes_total` | Container network TX |
| `container_fs_usage_bytes` | Container filesystem usage |
| `container_last_seen` | Container liveness |

## Extending Monitoring

### New Docker container added?

**No config changes needed.** Both cAdvisor and Promtail auto-discover all Docker containers:
- **Metrics**: cAdvisor exposes metrics for every container automatically. New containers appear in the Docker Metrics dashboard within one scrape interval (15s).
- **Logs**: Promtail's glob path (`/var/lib/docker/containers/*/*.log`) picks up all container logs automatically. New container logs appear in Loki immediately.

### New node added?

1. Copy the appropriate agent folder (`ideapad/` or `proxmox/` as template) to the new node
2. Update `.env` with the correct `NODE_HOSTNAME` and `LOKI_URL`
3. Update promtail `config.yml` with the correct `host` label
4. Run `docker compose up -d`
5. On druva, add the new node's IP to:
   - `druva/prometheus/targets/node-exporter.json`
   - `druva/prometheus/targets/cadvisor.json`
6. Prometheus picks up the new targets automatically (file_sd refresh every 30s) — no restart needed

### App exposes custom `/metrics` endpoint?

Add a scrape job to `druva/prometheus/prometheus.yml`:

```yaml
scrape_configs:
  # ... existing jobs ...

  - job_name: "my-app"
    static_configs:
      - targets: ["<node-ip>:<port>"]
        labels:
          node: "<node-name>"
```

Then reload Prometheus: `curl -X POST http://druva:9090/-/reload`

## Data Retention

| Service    | Retention | Storage Location |
|------------|-----------|-----------------|
| Prometheus | 15 days   | `/mnt/storage/docker/prometheus` on druva |
| Loki       | 7 days    | `/mnt/storage/docker/loki` on druva |
| Grafana    | N/A       | `/mnt/storage/docker/grafana` on druva |
