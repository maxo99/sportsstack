# SportsStack Platform

This repo contains the SportsStack services plus container orchestration assets. Two deployment paths exist:

- `docker-compose.yaml` retains the previous local stack and is still usable for quick spins of the classic environment.
- `k8s/` provides the Kubernetes manifests for the shared `sportsstack` namespace (Postgres, rotoreader, oddstracker, API gateway, ingress, autoscaling, and cron jobs).

## Prerequisites

- Docker (for image builds).
- Kind cluster named `sportsstack` with the nginx ingress controller and metrics-server installed.
- `.env` at the repo root with database credentials and `THEODDSAPI_KEY` for oddstracker.

## Daily Workflow

1. Build images: `just build-rotoreader` / `just build-oddstracker` / `just build-api-gateway`.
2. Load them into the Kind cluster: `just kind-load-rotoreader` / `just kind-load-oddstracker` / `just kind-load-api-gateway`.
3. Refresh secrets from `.env`: `just k8s-create-secret`.
4. Choose how to manage the database:
   - With raw manifests (current default): `just k8s-apply` includes `k8s/db-config.yaml` and `k8s/postgres.yaml`.
   - With Helm (optional, recommended for easy switch to external DB):
     - In-cluster DB: `just helm-db-install`
     - External DB: `just helm-db-install-external host=mydb.example.com`
5. Apply or update the remaining manifests: `just k8s-apply` (or `just k8s-apply-no-db` if Helm is used for DB).
6. Monitor rollouts: `just k8s-rollouts`.

## Useful Commands

- Restart deployments: `just restart-rotoreader`, `just restart-oddstracker`, `just restart-api-gateway`.
- Tail logs: `just logs-rotoreader`, `just logs-oddstracker`, `just logs-api-gateway`, `just logs-rotoreader-init`, `just logs-oddstracker-init`.
- Inspect cluster state: `just describe-rotoreader`, `just describe-oddstracker`, `just events`.
- Port-forward for local access: `just pf-api-gateway`, `just pf-rotoreader`, `just pf-oddstracker`, `just pf-ingress`.
- Database shell: `just db-shell`.

## Structure Highlights

- `api-gateway/`: Spring Cloud Gateway service, Dockerfile builds `maxo5499/sportsstack-api-gateway:latest`.
- `rotoreader/`: FastAPI data collector, Dockerfile builds `maxo5499/sportsstack-rotoreader:latest`.
- `oddstracker/`: FastAPI betting odds tracker, Dockerfile builds `maxo5499/sportsstack-oddstracker:latest`.
- `k8s/`: Namespace, ConfigMap, Postgres StatefulSet, rotoreader and oddstracker Deployments/HPAs/CronJobs, API gateway Deployment, ingress, and setup README.
- `charts/sportsstack-db/`: Helm chart for DB ConfigMap and optional in‑cluster Postgres. Toggle external vs in‑cluster DB without changing app manifests.
- `.github/copilot-instructions.md`: Contributor guidance for this repository.

Follow the sequence above to rebuild and redeploy as changes are made. The `justfile` is the central entry point for repeated operations.
