# PHASE 32 — POS Docker Deployment Runbook (VPS)

> Isolated POS Cloud stack on the existing OVH VPS. **Never touches ERP / ERP-Commercial / Owner.**
> Production secrets stay in `.env` (0600) — never in Git, images, or logs.

## 0. Deploy directory (VPS)

```text
/home/dev/pos-cloud/
    compose.yml            # pos stack (from this repo)
    .env                   # secrets (0600)
    deployment/
    docs/
    backups/
```

Copy the stabilized repo (or just `backend Dockerfile`, `frontend Dockerfile` + `frontend/nginx.conf`, `docker-compose.yml`, `.env.example`).
`deployment/` may hold the generated `backend/migrations-pos-cloud.sql`.

## 1. Pre-flight (on the VPS)

```bash
# 1.1 Verify commit / source integrity
git -C /home/dev/pos-cloud rev-parse HEAD            # == the POS commit recorded in DEPLOYMENT_STATUS.md

# 1.2 Capacity snapshot (before starting anything)
free -m; cat /proc/pressure/memory; uptime; df -h /
cat /sys/fs/cgroup/memory.current 2>/dev/null || true

# 1.3 Live port check — never assume a port is free
ss -tlnp | grep -E ':(8103|8104)\b' || echo "ports 8103/8104 FREE"
# If busy → pick other free ports and set POS_API_PORT / POS_WEB_PORT in .env

# 1.4 Confirm ERP/Owner stacks remain untouched
docker compose -f /path/to/erp/compose ps   # READ-ONLY status only
docker network ls | grep -E 'erp|owner'     # POS must NOT appear here
```

## 2. Secrets

```bash
cp .env.example .env && chmod 600 .env
# fill POS_POSTGRES_PASSWORD / POS_JWT_KEY / POS_ALLOWED_HOSTS / POS_WEB_ORIGIN
# Generate: openssl rand -base64 48
```

## 3. Validate + start (isolated namespace)

```bash
cd /home/dev/pos-cloud
docker compose config --quiet && echo "compose OK"
docker compose up -d pos-db
docker compose up -d pos-api     # auto-runs EF migrations on startup (idempotent history)
docker compose up -d pos-web
docker compose ps                 # pos-db / pos-api / pos-web healthy
```

Startup order is enforced by healthchecks (`pos-db healthy → pos-api → pos-web`).

## 4. Smoke tests

```bash
curl -fsS  http://127.0.0.1:8103/health                  # API health   → 200
curl -fsS  http://127.0.0.1:8104/                        # Web          → 200 (index.html)
curl -fsS  http://127.0.0.1:8104/api/                    # Web→API proxy→ 200 JSON
curl -fsS  http://127.0.0.1:8104/health                  # Web→API proxy→ 200
```

Login / POS / products / sales / purchases / accounting / invoices / reports /
settings / image upload — via the web UI **using only isolated POS test data**.
Tenant isolation is covered by the 26/26 automated suite (must stay green).

## 5. Persistence + recovery

```bash
# Image persistence (POS-§30)
docker compose restart pos-web && curl -fsSI http://127.0.0.1:8104/uploads/products/<existing>.jpg
docker compose restart pos-api && curl -fsSI http://127.0.0.1:8104/uploads/products/<existing>.jpg

# Backup (POS-§31) — never mixed with ERP dumps
mkdir -p /home/dev/server-backups/pos
docker compose exec -T pos-db pg_dump -U poscloud -d POSCloudDb -Fc > /home/dev/server-backups/pos/pos-$(date +%F).dump
cp docker-compose.yml .env.example /home/dev/server-backups/pos/

# DR (POS-§34) — restore into an isolated test environment, never the live pos-db
docker run --rm --network pos-net -v pgdata2vol:/var/lib/postgresql/data ...   # isolated restore target
```

## 6. Reboot survival (POS-§37)

`restart: unless-stopped` is set on pos-db/pos-api/pos-web.
After a VPS reboot: `docker compose ps` → all healthy; re-run smoke tests.

## 7. Owner registration (POS-§32, read-only)

Register instance `pos-cloud` (ServerId `server-local`, `protected=false`,
`environment=customer/demo/pos`) in Owner with read-only visibility only
(health/version/container list/drift/backup/capacity). No mutation permissions.
OpenClaw stays unchanged in PHASE 32.

## 8. Rollback

```bash
cd /home/dev/pos-cloud
docker compose down            # POS stack only — never with -v on ERP
docker compose up -d --build   # rebuild from a previous commit/tag if needed
```
`docker compose down`/`prune`/etc. are **forbidden for ERP/Owner stacks only** —
POS targets are prefixed `pos-` and isolated on `pos-net`.
