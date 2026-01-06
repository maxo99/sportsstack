# Decision: Shared Charts (sportsstack-db, observability)

## Context

Two charts in the root `charts/` directory serve shared infrastructure purposes:
- `charts/sportsstack-db/`: Database configuration management (shared by oddstracker, rotoreader)
- `charts/observability/`: Monitoring stack (Prometheus, Grafana, Loki, Tempo)

These charts are not service-specific but provide infrastructure used by multiple services.

## Options

### Option A: Keep in Root Repository

**Rationale:**
- These are infrastructure resources, not application services
- Shared nature makes them appropriate for root-level management
- Single source of truth for shared infrastructure

**Pros:**
- ✅ Simple, no migration effort
- ✅ Single source of truth for shared configs
- ✅ Easier to manage as infrastructure-as-code
- ✅ Consistent with root repo being an "orchestrator"

**Cons:**
- ❌ Coupling infrastructure to sportsstack root
- ❌ Cannot be shared with other projects

### Option B: Duplicate in Each Submodule

**Rationale:**
- Full independence for each service
- Each service owns its infrastructure

**Pros:**
- ✅ Complete independence
- ✅ Services can diverge as needed

**Cons:**
- ❌ Configuration drift between services
- ❌ Maintenance overhead (update N times)
- ❌ Inconsistent infrastructure across services
- ❌ Violates DRY principle

### Option C: Create Separate Shared Repository

**Rationale:**
- Infrastructure can be versioned independently
- Can be shared across multiple projects
- Clear separation of concerns

**Pros:**
- ✅ Infrastructure can be reused
- ✅ Independent versioning
- ✅ Clear ownership (infra team)

**Cons:**
- ❌ Additional repository to manage
- ❌ Adds dependency management complexity
- ❌ Overkill for current scope

## Recommendation: Option A - Keep in Root Repository

**Reasoning:**

1. **Nature of Resources**: These are infrastructure, not application services. Root repo acts as orchestrator.

2. **Shared Configuration**: `sportsstack-db` is used by multiple services. Duplicating it would lead to drift.

3. **Simplicity**: No value in moving infrastructure to separate location for current use case.

4. **Infrastructure as Code**: Root repository appropriately manages infrastructure as code for the platform.

5. **Future Flexibility**: Can extract to separate repo later if multiple teams/projects need it.

## Current Implementation

### sportsstack-db
- **Location**: `charts/sportsstack-db/`
- **Purpose**: Database configuration + optional in-cluster Postgres
- **Used By**: oddstracker (TimescaleDB), rotoreader (pgvector)
- **Justfile Recipe**: `helm-db-install`, `helm-db-install-external`, `helm-db-uninstall`

### observability
- **Location**: `charts/observability/`
- **Purpose**: Prometheus, Grafana, Loki, Tempo
- **Used By**: All services (telemetry export to Tempo)
- **Justfile Recipe**: `helm-observability-install`, `helm-observability-uninstall`

## Related Documentation

- [Helm Migration Plan](./helm-migration-plan.md)
- [Architecture Overview](../README.md)
- [Kubernetes Deployment Guide](../k8s/README.md)
