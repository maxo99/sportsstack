# Direct Pod Session Sandbox Plan

## Goals

- Provide isolated IPython execution per session intialized by go-sportsagent.
- Route all requests through the existing API Gateway and go-sportsagent.
- Export generated reports before session teardown.

## Architecture

- API Gateway forwards sandbox requests to go-sportsagent.
- go-sportsagent creates a Pod in the sandbox namespace using the pre-built IPython image.
- Pod labels carry trace identifiers for Zipkin correlation.
- Pod runs a wrapper entrypoint that boots IPython and listens for agent commands via gRPC or WebSocket tunnel.

## Session Workflow

1. Client authenticates and requests a sandbox session via API Gateway.
2. go-sportsagent provisions the Pod with a unique name and injects secrets/config via Kubernetes API.
3. When Pod becomes Ready, go-sportsagent returns connection details to the client.
4. Agent streams commands and receives results over the chosen protocol.
5. On completion or timeout, go-sportsagent signals shutdown and deletes the Pod.

## Storage and Artifacts

- Mount a short-lived PVC (ephemeral volume or RWX scratch) for session workspace.
- Provide in-Pod helper to push artifacts to object storage before shutdown.
- Expose a download endpoint in go-sportsagent that proxies stored artifacts.

## Observability

- Annotate Pod with `prometheus.io/scrape` for resource metrics when needed.
- Stream stdout/stderr to Loki via existing log pipeline.
- Inject trace/span IDs through environment variables for IPython wrapper logging.

## Security and Isolation

- Use dedicated ServiceAccount with minimal RBAC (create/delete Pods, PVCs, Secrets in sandbox namespace).
- Apply PodSecurity admission (restricted profile), seccomp, and apparmor policies.
- Enforce CPU/memory/ephemeral-storage limits and network policies restricting egress.

## Cleanup and Lifecycle Management

- go-sportsagent tracks Pod phase and enforces max session duration.
- Use finalizer or background reaper to delete orphaned Pods/PVCs.
- Emit audit events when sessions start/stop for compliance records.

## Future Enhancements

- Replace direct Pod handling with a lightweight SandboxSession CRD/controller.
- Introduce warm pool management or scale-to-zero platform when concurrency grows.
- Add persistent notebooks export pipeline if long-lived analysis becomes necessary.
