# Decision: api-gateway Handling

## Context

The `api-gateway` service is currently implemented as a monolith within the root repository at `api-gateway/`. Unlike other services (oddstracker, rotoreader, go-sportsagent), it is not organized as a git submodule.

## Options

### Option A: Keep in Root Repository

**Rationale:**
- api-gateway is a monolithic Spring Cloud Gateway service
- Already integrated with root repository infrastructure
- Simplifies architecture by keeping monolith separate from microservices

**Pros:**
- ✅ Simple, no migration effort
- ✅ Monolith remains centralized
- ✅ Clear separation between monolith and microservices

**Cons:**
- ❌ Inconsistent with microservices architecture
- ❌ Cannot be managed independently from other services

### Option B: Extract to Separate Repository

**Rationale:**
- Consistent architecture across all services
- Enables independent management and versioning
- Allows api-gateway to evolve independently

**Pros:**
- ✅ Consistent architecture pattern
- ✅ Independent versioning and releases
- ✅ Can be deployed/managed independently
- ✅ Clear ownership boundaries

**Cons:**
- ❌ Significant migration effort
- ❌ May require breaking changes to deployment workflows
- ❌ Additional repository to maintain
- ❌ Potential CI/CD configuration duplication

## Recommendation: Option B - Extract to Separate Repository

**Reasoning:**

1. **Architectural Consistency**: All services should follow the same pattern for maintainability and clarity.

2. **Independence**: api-gateway can have its own release cycle, separate from data collection services.

3. **Scalability**: As the platform grows, api-gateway may become its own team or project.

4. **Future-proofing**: Makes it easier to adopt additional monolith services later (e.g., notification-service).

## Implementation Plan (if Option B)

1. **Create separate repository**: `github.com/maxo99/api-gateway`
2. **Migrate code**: Move `api-gateway/` directory to new repo
3. **Migrate Helm chart**: Copy `charts/api-gateway/` to new repo as `charts/api-gateway/`
4. **Update workflows**: Move any GitHub Actions or CI/CD to new repo
5. **Update root justfile**: Change chart path from `charts/api-gateway` to external reference
6. **Update documentation**: Reflect new structure
7. **Test deployment**: Verify api-gateway deploys correctly from new location

## Current Decision

**Keep in Root** (Option A)

**Justification:**
- Migration effort not justified at this time
- api-gateway is tightly integrated with current deployment patterns
- No immediate need for independent versioning
- Monolith pattern is acceptable for a central routing service

**Future Trigger for Extraction:**
- Multiple teams need to work on api-gateway independently
- api-gateway requires significant architectural changes
- Platform grows to require gateway federation or multi-gateway setup

## Related Documentation

- [Helm Migration Plan](./helm-migration-plan.md)
- [Architecture Overview](../README.md)
