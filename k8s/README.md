# SportsStack Kubernetes Deployment

This folder provides baseline manifests for running the core SportsStack services on a Kubernetes cluster (e.g. kind) with a shared namespace and in-cluster Postgres.

## Prerequisites

- Kubernetes cluster with metrics-server installed (required for the HPA).
- nginx ingress controller (for kind, follow <https://kind.sigs.k8s.io/docs/user/ingress/>).
  - `kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml`
  - `kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml`
- `local-path` storage class available (kind installs it by default).
- Container images `maxo5499/sportsstack-api-gateway:latest`, `maxo5499/sportsstack-rotoreader:latest`, and `maxo5499/sportsstack-oddstracker:latest` pushed to a registry accessible by the cluster (or loaded into kind).

## Secrets

Secrets are created from the repo root `.env` file. Ensure it contains at least `POSTGRES_PASSWORD=...`, `POSTGRES_USER=...`, and `THEODDSAPI_KEY=...` (and any other sensitive keys you want to surface to Pods).

```bash
kubectl create namespace sportsstack
kubectl -n sportsstack delete secret postgres-secret --ignore-not-found
kubectl -n sportsstack create secret generic postgres-secret --from-env-file=.env
```

## Apply manifests

- `kubectl apply -f k8s/namespace.yaml`
- `kubectl apply -f k8s/db-config.yaml`
- `kubectl apply -f k8s/postgres.yaml`
- `kubectl apply -f k8s/rotoreader.yaml`
- `kubectl apply -f k8s/rotoreader-hpa.yaml`
- `kubectl apply -f k8s/rotoreader-collect-cronjob.yaml`
- `kubectl apply -f k8s/oddstracker.yaml`
- `kubectl apply -f k8s/oddstracker-hpa.yaml`
- `kubectl apply -f k8s/oddstracker-collect-cronjob.yaml`
- `kubectl apply -f k8s/api-gateway.yaml`
- `kubectl apply -f k8s/ingress.yaml`

Monitor rollout:

```bash
kubectl -n sportsstack rollout status statefulset/postgres
kubectl -n sportsstack rollout status deploy/rotoreader
kubectl -n sportsstack rollout status deploy/oddstracker
kubectl -n sportsstack rollout status deploy/api-gateway
```

## Local testing

1. Add host entries pointing to the ingress controller (for kind, use the worker/control-plane IPs or `127.0.0.1` if using ingress patching):

   ```text
   127.0.0.1 api-gateway.local oddstracker.local rotoreader.local
   ```

2. Access the services through the ingress:
   - `http://api-gateway.local/`
   - `http://oddstracker.local/`
   - `http://rotoreader.local/`

## Notes

- `kubectl -n sportsstack get pods` should show `postgres`, `rotoreader`, `oddstracker`, and `api-gateway` workloads.
- The cron jobs `rotoreader-collect-hourly` and `oddstracker-collect-hourly` invoke their respective collection endpoints each hour.
- The HPAs scale `rotoreader` and `oddstracker` between 2 and 6 replicas according to CPU utilization.
- Both services share the `sportsstack` Postgres database provisioned by the StatefulSet in this namespace.
- Update the ingress hosts or TLS configuration as you promote beyond local environments.
