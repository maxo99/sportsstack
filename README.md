# SportsStack Platform

This repo contains the SportsStack services plus container orchestration assets. Two deployment paths exist:

- `docker-compose.yaml` retains the previous local stack and is still usable for quick spins of the classic environment.
- `k8s/` provides the Kubernetes manifests for the shared `sportsstack` namespace (Postgres, rotoreader, API gateway, ingress, autoscaling, and cron job).

## Prerequisites

- Docker (for image builds).
- Kind cluster named `sportsstack` with the nginx ingress controller and metrics-server installed.
- `.env` at the repo root with database credentials.

## Daily Workflow

1. Build images: `just build-rotoreader` / `just build-api-gateway`.
2. Load them into the Kind cluster: `just kind-load-rotoreader` / `just kind-load-api-gateway`.
3. Refresh secrets from `.env`: `just k8s-create-secret`.
4. Apply or update manifests: `just k8s-apply`.
5. Monitor rollouts: `just k8s-rollouts`.

## Useful Commands

- Restart deployments: `just restart-rotoreader`, `just restart-api-gateway`.
- Tail logs: `just logs-rotoreader`, `just logs-api-gateway`, `just logs-rotoreader-init`.
- Inspect cluster state: `just describe-rotoreader`, `just events-rotoreader`.
- Port-forward for local access: `just pf-api-gateway`, `just pf-rotoreader`, `just pf-ingress`.
- Database shell: `just db-shell`.

## Structure Highlights

- `api-gateway/`: Spring Cloud Gateway service, Dockerfile builds `maxo5499/sportsstack-api-gateway:latest`.
- `rotoreader/`: FastAPI data collector, Dockerfile builds `maxo5499/sportsstack-rotoreader:latest`.
- `k8s/`: Namespace, ConfigMap, Postgres StatefulSet, rotoreader Deployment/HPA/CronJob, API gateway Deployment, ingress, and setup README.
- `.github/copilot-instructions.md`: Contributor guidance for this repository.

Follow the sequence above to rebuild and redeploy as changes are made. The `justfile` is the central entry point for repeated operations.
