# Helm Chart Migration Plan

## Objective

Migrate Helm charts from the root SportsStack repository into their respective submodules, enabling submodules to operate independently and be unlinked from the root repository.

## Current Architecture

### Root Repository Structure

```
sportsstack/
├── .gitmodules                          # Submodule definitions
├── charts/                              # Centralized Helm charts
│   ├── api-gateway/                     # Monolith service chart
│   ├── go-sportsagent/                  # Submodule chart
│   ├── oddstracker/                     # Submodule chart
│   ├── rotoreader/                      # Submodule chart
│   ├── sportsstack-db/                  # Shared DB configuration
│   └── observability/                   # Shared monitoring stack
├── k8s/                                 # Raw Kubernetes manifests
│   ├── api-gateway.yaml
│   ├── oddstracker.yaml
│   ├── oddstracker-hpa.yaml
│   ├── oddstracker-collect-cronjob.yaml
│   ├── rotoreader.yaml
│   ├── rotoreader-hpa.yaml
│   ├── rotoreader-collect-cronjob.yaml
│   ├── postgres.yaml
│   ├── db-config.yaml
│   └── ingress.yaml
├── justfile                             # Central deployment automation
├── api-gateway/                         # Monolith service (not submodule)
├── go-sportsagent/                      # Git submodule
├── oddstracker/                         # Git submodule
└── rotoreader/                          # Git submodule (has own k8s/ directory)
```

### Submodules

| Submodule | Remote URL | Current Deployment Config |
|-----------|-----------|---------------------------|
| rotoreader | https://github.com/maxo99/rotoreader.git | Has k8s/ directory with raw manifests |
| oddstracker | https://github.com/maxo99/oddstracker.git | No deployment configs |
| go-sportsagent | https://github.com/maxo99/go-sportsagent.git | No deployment configs |

### Monolith Services

| Service | Location | Deployment Config |
|---------|----------|-------------------|
| api-gateway | root/api-gateway/ | Root chart + k8s/ manifest |
| notification-service | root/notification-service/ | No deployment config |

## Target Architecture

### After Migration

```
Submodule Repositories:
─────────────────────────────────────────────────────
go-sportsagent/
├── charts/
│   └── go-sportsagent/          # Migrated from root
├── internal/
├── go.mod
└── ...

oddstracker/
├── charts/
│   └── oddstracker/             # Migrated from root
├── src/oddstracker/
├── pyproject.toml
└── ...

rotoreader/
├── charts/
│   └── rotoreader/              # Migrated from root
├── k8s/                         # Existing raw manifests (keep or deprecate)
├── src/rotoreader/
└── ...

Root Repository (simplified):
─────────────────────────────────────────────────────
sportsstack/
├── charts/                      # Reduced to shared resources only
│   ├── api-gateway/             # Monolith service (remains)
│   ├── sportsstack-db/          # Shared DB config (remains)
│   └── observability/           # Shared monitoring (remains)
├── k8s/                         # Shared manifests only
│   ├── postgres.yaml
│   ├── db-config.yaml
│   └── ingress.yaml
├── justfile                     # Updated to reference submodule charts
├── api-gateway/                 # Monolith service
├── notification-service/        # Monolith service
└── .gitmodules                  # REMOVED after migration
```

## Migration Strategy

### Phase 1: Chart Migration (Per Submodule)

For each submodule (rotoreader, oddstracker, go-sportsagent):

1. **Copy Chart to Submodule**
   - Create `charts/` directory in submodule
   - Copy entire chart directory from root: `charts/{service}/` → `{service}/charts/{service}/`
   - Preserve Chart.yaml versioning

2. **Update Chart References (if any)**
   - Check for inter-chart dependencies
   - Update values.yaml to reference correct service names
   - Verify image repository paths

3. **Commit to Submodule Repository**
   - Commit chart changes to the submodule's own repository
   - Tag appropriately if versioning is used

4. **Remove from Root**
   - Delete `charts/{service}/` from root repository
   - Update root justfile to reference submodule path: `{service}/charts/{service}`

### Phase 2: Justfile Updates

Update root justfile recipes to reference new chart locations:

```justfile
# Before:
helm-oddstracker-install:
    helm upgrade --install oddstracker charts/oddstracker -n {{ns}} ...

# After:
helm-oddstracker-install:
    helm upgrade --install oddstracker oddstracker/charts/oddstracker -n {{ns}} ...
```

Recipes to update:
- `helm-oddstracker-*` (template, install, uninstall)
- `helm-rotoreader-*` (template, install, uninstall)
- `helm-go-sportsagent-*` (template, install, uninstall)

### Phase 3: Documentation Updates

Update these files to reflect new chart locations:

1. **k8s/README.md**
   - Update Helm chart paths
   - Adjust migration instructions
   - Update example commands

2. **docs/usage.md**
   - Update Helm workflow section
   - Adjust quick deploy references

3. **README.md** (root)
   - Update architecture diagram
   - Update component descriptions

### Phase 4: Testing

For each migrated service:

1. **Local Testing**
   ```bash
   # Test chart rendering
   just helm-{service}-template

   # Test installation in Kind
   just helm-{service}-install
   ```

2. **Integration Testing**
   - Verify service communication through api-gateway
   - Test cronjobs (if applicable)
   - Verify HPA functionality

3. **Rollback Plan**
   - Keep root chart backup for quick rollback
   - Document rollback steps

### Phase 5: Submodule Removal

After successful testing:

1. **Update Root Repository**
   - Remove submodule references from `.gitmodules`
   - Run: `git config --remove-section submodule.{service}`
   - Run: `git rm --cached {service}`
   - Commit the removal

2. **Verify Independence**
   - Each submodule can be deployed standalone
   - No cross-repository dependencies (except shared resources)

## Decision Points

### 1. api-gateway (Monolith) Handling

**Option A: Keep in Root**
- ✅ Simple, already monolithic
- ❌ Inconsistent with modular architecture

**Option B: Extract to Separate Repo**
- ✅ Consistent architecture
- ✅ Can be managed independently
- ❌ More migration effort
- ❌ May require breaking changes

**Recommendation: Option B** - Extract to separate repository for consistency.

### 2. sportsstack-db Chart (Shared Resource)

**Option A: Keep in Root**
- ✅ Shared across multiple services
- ✅ Single source of truth
- ❌ Coupling to root repository

**Option B: Duplicate in Each Submodule**
- ✅ Full independence
- ❌ Configuration drift
- ❌ Maintenance overhead

**Option C: Create Separate Shared Repo**
- ✅ Shared resource
- ✅ Versioned independently
- ❌ Additional repository

**Recommendation: Option A** - Keep in root for now as shared infrastructure. Consider separate repo later if needed.

### 3. observability Chart (Shared Resource)

**Recommendation: Option A** - Keep in root as shared infrastructure.

### 4. rotoreader k8s/ Directory

**Options:**
- Keep as alternative deployment method
- Deprecate and migrate to Helm only
- Move to archive

**Recommendation: Deprecate** - Document migration to Helm and eventually remove.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking existing deployment workflows | Medium | High | Comprehensive testing, rollback plan |
| Chart dependency issues | Low | Medium | Review inter-service dependencies |
| Documentation drift | Medium | Low | Update all docs simultaneously |
| Submodule repo access/permissions | Low | High | Verify access before migration |
| Version conflicts | Low | Medium | Preserve Chart.yaml versions |

## Rollback Plan

If migration fails:

1. **Immediate Rollback**
   - Restore root charts from backup
   - Revert justfile changes
   - Revert documentation changes

2. **Submodule State**
   - Commit chart removal to submodule
   - Or keep chart as fallback option

3. **Communication**
   - Document failure
   - Identify root cause
   - Plan retry with adjusted approach

## Success Criteria

- [ ] All submodule charts successfully migrated to their respective repositories
- [ ] Root justfile updated to reference new chart locations
- [ ] Documentation updated across all relevant files
- [ ] All services deploy successfully with new chart locations
- [ ] Integration tests pass
- [ ] Submodule references removed from .gitmodules
- [ ] Each submodule can be deployed independently

## Timeline Estimate

| Phase | Duration |
|-------|----------|
| Phase 1: Chart Migration (3 submodules) | 2-3 hours |
| Phase 2: Justfile Updates | 30 minutes |
| Phase 3: Documentation Updates | 1 hour |
| Phase 4: Testing | 2-3 hours |
| Phase 5: Submodule Removal | 30 minutes |
| **Total** | **6-8 hours** |

## Prerequisites

- Write access to all submodule repositories
- Backup of current root charts directory
- Test Kind cluster available
- All submodule repositories accessible locally

## Post-Migration

### Monitoring Tasks

- Verify all deployments work correctly
- Monitor for any unexpected behavior
- Update CI/CD workflows if they reference chart paths
- Archive or remove deprecated k8s/ manifests

### Future Improvements

- Consider creating Helm chart repository for publishing
- Implement chart versioning strategy
- Create shared chart dependencies management
- Evaluate api-gateway extraction
