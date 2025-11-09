set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

ns := "sportsstack"
kind_cluster := "sportsstack"
rotoreader_image := "maxo5499/sportsstack-rotoreader:latest"
oddstracker_image := "maxo5499/sportsstack-oddstracker:latest"
api_gateway_image := "maxo5499/sportsstack-api-gateway:latest"
go_sportsagent_image := "maxo5499/sportsstack-go-sportsagent:latest"

# Show available recipes
default:
	@just --list

# Common workflows
help:
	@echo "SportsStack - Common Workflows"
	@echo "==============================="
	@echo ""
	@echo "Quick Deploy (build + load + restart):"
	@echo "  just deploy-rotoreader      - Build, load, and restart rotoreader"
	@echo "  just deploy-oddstracker     - Build, load, and restart oddstracker"
	@echo "  just deploy-api-gateway     - Build, load, and restart api-gateway"
	@echo "  just deploy-go-sportsagent  - Build, load, and restart go-sportsagent"
	@echo "  just deploy-all             - Deploy all services"
	@echo ""
	@echo "Status & Monitoring:"
	@echo "  just status                 - Show pod status and resource usage"
	@echo "  just status-all             - Show all resources in namespace"
	@echo "  just logs-<service>         - Tail logs for a service"
	@echo "  just describe-<service>     - Describe pods for a service"
	@echo ""
	@echo "Port Forwarding:"
	@echo "  just pf-rotoreader          - Forward to rotoreader:8081"
	@echo "  just pf-oddstracker         - Forward to oddstracker:8080"
	@echo "  just pf-api-gateway         - Forward to api-gateway:8088"
	@echo "  just pf-go-sportsagent      - Forward to go-sportsagent:8082"
	@echo ""
	@echo "Database:"
	@echo "  just db-shell               - psql shell to shared database"
	@echo ""
	@echo "For full list: just --list"

build-rotoreader:
	./rotoreader/build.sh

build-oddstracker:
	./oddstracker/build.sh

build-api-gateway:
	./api-gateway/build.sh

build-go-sportsagent:
	./go-sportsagent/build.sh

kind-load-rotoreader:
	kind load docker-image {{rotoreader_image}} --name {{kind_cluster}}

kind-load-oddstracker:
	kind load docker-image {{oddstracker_image}} --name {{kind_cluster}}

kind-load-api-gateway:
	kind load docker-image {{api_gateway_image}} --name {{kind_cluster}}

kind-load-go-sportsagent:
	kind load docker-image {{go_sportsagent_image}} --name {{kind_cluster}}

# Combined workflows: build + load + restart
deploy-rotoreader:
	@echo "Building rotoreader..."
	@just build-rotoreader
	@echo "Loading into Kind cluster..."
	@just kind-load-rotoreader
	@echo "Restarting deployment..."
	@kubectl -n {{ns}} delete pod -l app=rotoreader
	@kubectl -n {{ns}} wait --for=condition=ready pod -l app=rotoreader --timeout=180s
	@echo "✅ rotoreader deployed successfully!"

deploy-oddstracker:
	@echo "Building oddstracker..."
	@just build-oddstracker
	@echo "Loading into Kind cluster..."
	@just kind-load-oddstracker
	@echo "Restarting deployment..."
	@kubectl -n {{ns}} delete pod -l app=oddstracker
	@kubectl -n {{ns}} wait --for=condition=ready pod -l app=oddstracker --timeout=180s
	@echo "✅ oddstracker deployed successfully!"

deploy-api-gateway:
	@echo "Building api-gateway..."
	@just build-api-gateway
	@echo "Loading into Kind cluster..."
	@just kind-load-api-gateway
	@echo "Restarting deployment..."
	@kubectl -n {{ns}} delete pod -l app=api-gateway
	@kubectl -n {{ns}} wait --for=condition=ready pod -l app=api-gateway --timeout=300s
	@echo "✅ api-gateway deployed successfully!"

deploy-go-sportsagent:
	@echo "Building go-sportsagent..."
	@just build-go-sportsagent
	@echo "Loading into Kind cluster..."
	@just kind-load-go-sportsagent
	@echo "Restarting deployment..."
	@kubectl -n {{ns}} delete pod -l app=go-sportsagent
	@kubectl -n {{ns}} wait --for=condition=ready pod -l app=go-sportsagent --timeout=180s
	@echo "✅ go-sportsagent deployed successfully!"

# Deploy all services
deploy-all:
	@just deploy-rotoreader
	@just deploy-oddstracker
	@just deploy-api-gateway
	@just deploy-go-sportsagent

k8s-create-secret:
	kubectl -n {{ns}} delete secret postgres-secret --ignore-not-found
	kubectl -n {{ns}} create secret generic postgres-secret --from-env-file=.env

k8s-apply:
	kubectl apply -f k8s/namespace.yaml
	kubectl apply -f k8s/db-config.yaml
	kubectl apply -f k8s/postgres.yaml
	kubectl apply -f k8s/rotoreader.yaml
	kubectl apply -f k8s/rotoreader-hpa.yaml
	kubectl apply -f k8s/rotoreader-collect-cronjob.yaml
	kubectl apply -f k8s/oddstracker.yaml
	kubectl apply -f k8s/oddstracker-hpa.yaml
	kubectl apply -f k8s/oddstracker-collect-cronjob.yaml
	kubectl apply -f k8s/api-gateway.yaml
	kubectl apply -f k8s/ingress.yaml

k8s-apply-no-db:
	kubectl apply -f k8s/namespace.yaml
	kubectl apply -f k8s/rotoreader.yaml
	kubectl apply -f k8s/rotoreader-hpa.yaml
	kubectl apply -f k8s/rotoreader-collect-cronjob.yaml
	kubectl apply -f k8s/oddstracker.yaml
	kubectl apply -f k8s/oddstracker-hpa.yaml
	kubectl apply -f k8s/oddstracker-collect-cronjob.yaml
	kubectl apply -f k8s/api-gateway.yaml
	kubectl apply -f k8s/ingress.yaml

k8s-rollouts:
	# kubectl -n {{ns}} rollout status statefulset/postgres
	kubectl -n {{ns}} rollout status deploy/rotoreader
	kubectl -n {{ns}} rollout status deploy/oddstracker
	kubectl -n {{ns}} rollout status deploy/api-gateway

restart-rotoreader:
	kubectl -n {{ns}} rollout restart deploy/rotoreader
	kubectl -n {{ns}} rollout status deploy/rotoreader

restart-oddstracker:
	kubectl -n {{ns}} rollout restart deploy/oddstracker
	kubectl -n {{ns}} rollout status deploy/oddstracker

restart-api-gateway:
	kubectl -n {{ns}} rollout restart deploy/api-gateway
	kubectl -n {{ns}} rollout status deploy/api-gateway

restart-go-sportsagent:
	kubectl -n {{ns}} rollout restart deploy/go-sportsagent
	kubectl -n {{ns}} rollout status deploy/go-sportsagent

logs-rotoreader:
	kubectl -n {{ns}} logs -l app=rotoreader -c api --tail=200 -f

logs-oddstracker:
	kubectl -n {{ns}} logs -l app=oddstracker -c api --tail=200 -f

logs-api-gateway:
	kubectl -n {{ns}} logs -l app=api-gateway --tail=200 -f

logs-go-sportsagent:
	kubectl -n {{ns}} logs -l app=go-sportsagent --tail=200 -f

logs-postgres:
	kubectl -n {{ns}} logs -l app=postgres --tail=200 -f

logs-rotoreader-init:
	for pod in $(kubectl -n {{ns}} get pods -l app=rotoreader -o name); do kubectl -n {{ns}} logs "$pod" -c wait-for-postgres --tail=200; done

logs-oddstracker-init:
	for pod in $(kubectl -n {{ns}} get pods -l app=oddstracker -o name); do kubectl -n {{ns}} logs "$pod" -c wait-for-postgres --tail=200; done

describe-rotoreader:
	kubectl -n {{ns}} describe pods -l app=rotoreader

describe-oddstracker:
	kubectl -n {{ns}} describe pods -l app=oddstracker

describe-api-gateway:
	kubectl -n {{ns}} describe pods -l app=api-gateway

describe-go-sportsagent:
	kubectl -n {{ns}} describe pods -l app=go-sportsagent

describe-postgres:
	kubectl -n {{ns}} describe pods -l app=postgres

events-rotoreader:
	kubectl -n {{ns}} get events --sort-by=.lastTimestamp

events:
	kubectl -n {{ns}} get events --sort-by=.lastTimestamp

pf-rotoreader:
	kubectl -n {{ns}} port-forward svc/rotoreader 8081:8081

pf-oddstracker:
	kubectl -n {{ns}} port-forward svc/oddstracker 8080:8080

pf-api-gateway:
	kubectl -n {{ns}} port-forward svc/api-gateway 8088:8088

pf-go-sportsagent:
	kubectl -n {{ns}} port-forward svc/go-sportsagent 8082:8082

pf-ingress:
	kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 8080:80

db-shell:
	kubectl -n {{ns}} exec -it svc/postgres -- psql -U postgres -d sportsstack

oddstracker-db-shell:
	kubectl -n {{ns}} exec -it oddstracker-postgres-0 -- psql -U postgres -d oddstracker

oddstracker-db-tables:
	kubectl -n {{ns}} exec -it oddstracker-postgres-0 -- psql -U postgres -d oddstracker -c "\dt"

rotoreader-db-shell:
	kubectl -n {{ns}} exec -it rotoreader-postgres-0 -- psql -U postgres -d rotoreader

rotoreader-db-tables:
	kubectl -n {{ns}} exec -it rotoreader-postgres-0 -- psql -U postgres -d rotoreader -c "\dt"

helm-observability-install:
	helm dependency update charts/observability
	helm upgrade --install observability charts/observability -n {{ns}} --create-namespace -f charts/observability/values.yaml

helm-observability-uninstall:
	helm uninstall observability -n {{ns}} || true
	kubectl -n {{ns}} delete pvc --all -l app=loki --ignore-not-found || true

# Helm-based management for database (ConfigMap + optional in-cluster Postgres)
helm-db-template:
	helm template db charts/sportsstack-db -n {{ns}} -f charts/sportsstack-db/values.yaml

helm-db-install:
	helm upgrade --install db charts/sportsstack-db -n {{ns}} --create-namespace -f charts/sportsstack-db/values.yaml

helm-db-install-external host="my-external-postgres.example.com":
	# Render ConfigMap pointing to an external Postgres; does not deploy StatefulSet/Service
	helm upgrade --install db charts/sportsstack-db -n {{ns}} --create-namespace \
	-f charts/sportsstack-db/values-external.yaml \
	--set postgres.host='{{host}}'

helm-db-uninstall:
	helm uninstall db -n {{ns}}

# Migrate existing non-Helm DB resources to Helm-managed ones
# This removes previously kubectl-applied resources so Helm can create them.
# It keeps PVCs to preserve data.
k8s-db-preroll-for-helm:
	# Delete shared ConfigMap and Services so Helm can own them
	kubectl -n {{ns}} delete configmap db-config --ignore-not-found
	kubectl -n {{ns}} delete svc postgres --ignore-not-found
	kubectl -n {{ns}} delete svc postgres-hl --ignore-not-found
	# Delete StatefulSet but KEEP the PVCs (data)
	kubectl -n {{ns}} delete statefulset postgres --ignore-not-found
	# Wait for any postgres pods to terminate (best-effort)
	kubectl -n {{ns}} wait --for=delete pod -l app=postgres --timeout=120s || true

# Danger: wipe Postgres data (use only if you want a clean DB)
k8s-db-delete-pvcs:
    kubectl -n {{ns}} delete pvc pgdata-postgres-0 --ignore-not-found || true

# Helm-based management for api-gateway
helm-api-gateway-template:
    helm template api-gateway charts/api-gateway -n {{ns}} -f charts/api-gateway/values.yaml

helm-api-gateway-install:
    helm upgrade --install api-gateway charts/api-gateway -n {{ns}} --create-namespace -f charts/api-gateway/values.yaml

helm-api-gateway-uninstall:
    helm uninstall api-gateway -n {{ns}}

k8s-api-gateway-preroll-for-helm:
    kubectl -n {{ns}} delete deployment api-gateway --ignore-not-found
    kubectl -n {{ns}} delete svc api-gateway --ignore-not-found
    kubectl -n {{ns}} wait --for=delete pod -l app=api-gateway --timeout=120s || true

# Helm-based management for oddstracker
helm-oddstracker-template:
    helm template oddstracker charts/oddstracker -n {{ns}} -f charts/oddstracker/values.yaml

helm-oddstracker-install:
    helm upgrade --install oddstracker charts/oddstracker -n {{ns}} --create-namespace -f charts/oddstracker/values.yaml

helm-oddstracker-uninstall:
    helm uninstall oddstracker -n {{ns}}

k8s-oddstracker-preroll-for-helm:
    kubectl -n {{ns}} delete deployment oddstracker --ignore-not-found
    kubectl -n {{ns}} delete svc oddstracker --ignore-not-found
    kubectl -n {{ns}} delete hpa oddstracker --ignore-not-found
    kubectl -n {{ns}} delete cronjob oddstracker-collect-hourly --ignore-not-found
    kubectl -n {{ns}} wait --for=delete pod -l app=oddstracker --timeout=120s || true

# Helm-based management for rotoreader
helm-rotoreader-template:
    helm template rotoreader charts/rotoreader -n {{ns}} -f charts/rotoreader/values.yaml

helm-rotoreader-install:
    helm upgrade --install rotoreader charts/rotoreader -n {{ns}} --create-namespace -f charts/rotoreader/values.yaml

helm-rotoreader-uninstall:
    helm uninstall rotoreader -n {{ns}}

k8s-rotoreader-preroll-for-helm:
    kubectl -n {{ns}} delete deployment rotoreader --ignore-not-found
    kubectl -n {{ns}} delete svc rotoreader --ignore-not-found
    kubectl -n {{ns}} delete hpa rotoreader --ignore-not-found
    kubectl -n {{ns}} delete cronjob rotoreader-collect-hourly --ignore-not-found
    kubectl -n {{ns}} wait --for=delete pod -l app=rotoreader --timeout=120s || true

# Helm-based management for go-sportsagent
helm-go-sportsagent-template:
    helm template go-sportsagent charts/go-sportsagent -n {{ns}} -f charts/go-sportsagent/values.yaml

helm-go-sportsagent-install:
    helm upgrade --install go-sportsagent charts/go-sportsagent -n {{ns}} --create-namespace -f charts/go-sportsagent/values.yaml

helm-go-sportsagent-uninstall:
    helm uninstall go-sportsagent -n {{ns}}

k8s-go-sportsagent-preroll-for-helm:
    kubectl -n {{ns}} delete deployment go-sportsagent --ignore-not-found
    kubectl -n {{ns}} delete svc go-sportsagent --ignore-not-found
    kubectl -n {{ns}} delete hpa go-sportsagent --ignore-not-found
    kubectl -n {{ns}} wait --for=delete pod -l app=go-sportsagent --timeout=120s || true

k8s-get-controlplane-details:
	kubectl cluster-info
	kubectl get nodes -o wide
	kubectl get namespaces

get-events:
	kubectl -n {{ns}} get events --sort-by=.lastTimestamp

# Status and utility commands
status:
	@echo "=== SportsStack Services Status ==="
	@kubectl -n {{ns}} get pods -l 'app in (rotoreader,oddstracker,api-gateway,go-sportsagent,postgres)' -o wide
	@echo ""
	@echo "=== Resource Usage ==="
	@kubectl top pod -n {{ns}} -l 'app in (rotoreader,oddstracker,api-gateway,go-sportsagent,postgres)' 2>/dev/null || echo "Metrics not available (metrics-server may not be running)"

status-all:
	@echo "=== All Pods in namespace ==="
	@kubectl -n {{ns}} get pods -o wide
	@echo ""
	@echo "=== Services ==="
	@kubectl -n {{ns}} get svc
	@echo ""
	@echo "=== Ingress ==="
	@kubectl -n {{ns}} get ingress

logs-tail service:
	kubectl -n {{ns}} logs -l app={{service}} --tail=100 -f

logs-all service:
	kubectl -n {{ns}} logs -l app={{service}} --all-containers=true --tail=500

# Quick restart without rebuild (useful when only Helm values change)
restart service:
	kubectl -n {{ns}} delete pod -l app={{service}}
	kubectl -n {{ns}} wait --for=condition=ready pod -l app={{service}} --timeout=180s

# Check if image is loaded in Kind
check-image image:
	@echo "Checking if {{image}} is in Kind cluster..."
	@docker exec -it {{kind_cluster}}-control-plane crictl images | grep {{image}} || echo "❌ Image not found in Kind cluster"

check-all-images:
	@echo "=== Images in Kind cluster ==="
	@just check-image rotoreader
	@just check-image oddstracker
	@just check-image api-gateway
	@just check-image go-sportsagent
