# SportsStack Kubernetes Deployment

This folder provides baseline manifests for running the core SportsStack services on a Kubernetes cluster (e.g. kind) with a shared namespace and in-cluster Postgres.

## Prerequisites

- Kubernetes cluster with metrics-server installed (required for the HPA).
- nginx ingress controller (for kind, follow <https://kind.sigs.k8s.io/docs/user/ingress/>).
  - `kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml`
  - `kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml`
- `local-path` storage class available (kind installs it by default).
- Container images `maxo5499/sportsstack-api-gateway:latest` and `maxo5499/sportsstack-rotoreader:latest` pushed to a registry accessible by the cluster.

## Secrets

Secrets are created from the repo root `.env` file. Ensure it contains at least `POSTGRES_PASSWORD=...` (and any other sensitive keys you want to surface to Pods).

```bash
kubectl create namespace sportsstack
kubectl -n sportsstack delete secret postgres-secret --ignore-not-found
kubectl -n sportsstack create secret generic postgres-secret --from-env-file=.env
```

## Local testing

1. Add host entries pointing to the ingress controller (for kind, use the worker/control-plane IPs or `127.0.0.1` if using ingress patching):

   ```text
   127.0.0.1 api-gateway.local rotoreader.local
   ```

2. Access the services through the ingress:
   - `http://api-gateway.local/`
   - `http://rotoreader.local/`

## Notes

- `kubectl -n sportsstack get pods` should show `postgres`, `rotoreader`, and `api-gateway` workloads.
- The cron job `rotoreader-collect-hourly` triggers the collection endpoint each hour.
- The HPA scales `rotoreader` between 2 and 4 replicas according to CPU utilization.
- Update the ingress hosts or TLS configuration as you promote beyond local environments.
