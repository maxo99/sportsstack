set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

ns := "sportsstack"
kind_cluster := "sportsstack"
rotoreader_image := "maxo5499/sportsstack-rotoreader:latest"
oddstracker_image := "maxo5499/sportsstack-oddstracker:latest"
api_gateway_image := "maxo5499/sportsstack-api-gateway:latest"
go_sportsagent_image := "maxo5499/sportsstack-go-sportsagent:latest"

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
	kubectl -n {{ns}} rollout status statefulset/postgres
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
	kubectl -n {{ns}} logs deploy/rotoreader -c api --tail=200 -f

logs-oddstracker:
	kubectl -n {{ns}} logs deploy/oddstracker -c api --tail=200 -f

logs-api-gateway:
	kubectl -n {{ns}} logs deploy/api-gateway --tail=200 -f

logs-go-sportsagent:
	kubectl -n {{ns}} logs deploy/go-sportsagent -c api --tail=200 -f

logs-rotoreader-init:
	for pod in $(kubectl -n {{ns}} get pods -l app=rotoreader -o name); do kubectl -n {{ns}} logs "$pod" -c wait-for-postgres --tail=200; done

logs-oddstracker-init:
	for pod in $(kubectl -n {{ns}} get pods -l app=oddstracker -o name); do kubectl -n {{ns}} logs "$pod" -c wait-for-postgres --tail=200; done

describe-rotoreader:
	kubectl -n {{ns}} describe pods -l app=rotoreader

describe-oddstracker:
	kubectl -n {{ns}} describe pods -l app=oddstracker

describe-go-sportsagent:
	kubectl -n {{ns}} describe pods -l app=go-sportsagent

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