# FastCRW (`crw`) Helm Chart

## Introduction

[FastCRW (`crw`)](https://github.com/fastcrw/crw) is an ultra-fast, lightweight web scraping, crawling, and AI search API written in Rust. Designed specifically for AI Agents, RAG pipelines, and LLM context extraction, FastCRW delivers clean Markdown and structured JSON without the overhead of heavy browser engines.

This Helm chart packages FastCRW for production Kubernetes deployments. Following enterprise patterns (similar to [SigNoz](https://github.com/SigNoz/charts)), it integrates [SearXNG](https://github.com/searxng/searxng) as an optional **Helm subchart dependency** (`techpipe/searxng`), providing an out-of-the-box, private, and self-hosted alternative to **Tavily**, **Serper**, and **Firecrawl**.

## Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│ Clients / AI Agents / LLMs (Claude Code, Cursor, OpenWebUI) │
└──────────────────────────────┬──────────────────────────────┘
                               │ POST /v1/search, /v1/scrape, /v1/crawl
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ FastCRW (crw: port 3000)                                    │
│ • Lightweight Rust scraper & crawler (~6 MB idle RAM)       │
│ • Converts target pages into LLM-ready clean Markdown       │
│ • Native Model Context Protocol (MCP) server support        │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Optional internal search queries)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ SearXNG Subchart (searxng: port 8080) [Optional Dependency] │
│ • Controlled via: searxng.enabled (default: true)           │
│ • Sourced from: https://techpipe-io.github.io/searxng-helm  │
└─────────────────────────────────────────────────────────────┘
```

## Features

- **Tavily / Firecrawl Alternative**: Provides `/v1/search`, `/v1/scrape`, and `/v1/crawl` endpoints.
- **Single-Binary Efficiency**: Written in Rust, extremely low resource footprint (~6 MB RAM).
- **Subchart Modularity**: Bundles SearXNG via Helm `dependencies` (can be toggled on/off with `searxng.enabled`).
- **Auto-Discovery**: FastCRW automatically detects the internal SearXNG subchart service endpoint (respecting `searxng.fullnameOverride` and `searxng.nameOverride`) without manual wiring.
- **External Search Backend Support**: Simply set `searxng.enabled: false` and point `search.backendUrl` to any existing cluster or external SearXNG instance.
- **Native Model Context Protocol (MCP)**: Directly connects to MCP-compatible coding agents (Claude Code, Cursor).
- **Hardened Security**:
  - Non-root execution (`runAsNonRoot: true`, UID `10001`).
  - Read-only root filesystem (`readOnlyRootFilesystem: true`) with `/tmp` `emptyDir`.
  - Drop all Linux capabilities (`capabilities.drop: [ALL]`) and `seccompProfile: RuntimeDefault`.
  - ServiceAccount token automount disabled by default (`serviceAccount.automount: false`).
- **Vendor-Neutral Networking**: Supports standard Kubernetes `Ingress` (`networking.k8s.io/v1`) and Gateway API `HTTPRoute` (`gateway.networking.k8s.io/v1`).
- **Production Ready**: HorizontalPodAutoscaler (`autoscaling/v2`), PodDisruptionBudget (`policy/v1`), NetworkPolicy with working defaults, probes, graceful shutdown (`preStop` + 60s termination grace period), and JSON schema validation.

## Prerequisites

- **Kubernetes**:
  - `>= 1.27` when `searxng.enabled: true` (required by the upstream `techpipe/searxng` `0.1.11` subchart).
  - `>= 1.19` when `searxng.enabled: false` (standalone `crw` mode).
- **Helm**: `>= 3.0`

## Important Operational Notes

### GitOps / Argo CD (`searxng.secret.existingSecret`)

When `searxng.enabled: true` and `searxng.secret.create: true` (upstream subchart default), the SearXNG subchart generates a random `SEARXNG_SECRET` using Helm `lookup` / `randAlphaNum`. Because Argo CD renders charts offline via `helm template` where `lookup` is disabled, a new random secret would be generated on every sync (`OutOfSync` drift).

For GitOps / Argo CD deployments, supply a pre-existing Secret (managed via External Secrets Operator, Vault, or SealedSecrets) containing key `SEARXNG_SECRET`:

```yaml
searxng:
  enabled: true
  secret:
    create: false
    existingSecret: "searxng-runtime-secret"
    existingSecretKey: SEARXNG_SECRET
```

### Pod Security Standards (`restricted` Namespaces)

The `crw` container runs under the strict **Pod Security Standards `restricted`** profile out of the box (`runAsNonRoot: true`, UID `10001`, `readOnlyRootFilesystem: true`, `capabilities.drop: [ALL]`, `seccompProfile: RuntimeDefault`).

However, the upstream `searxng/searxng` image bundled in the optional `searxng` subchart starts as root by default (`FORCE_OWNERSHIP=true`) to initialize configuration files. If your target namespace enforces `pod-security.kubernetes.io/enforce: restricted`, either:

1. Deploy `crw` with `searxng.enabled: false` and connect to an external SearXNG instance in a `baseline` namespace via `search.backendUrl`, or
2. Configure custom non-root security contexts and `searxng.env.forceOwnership: false` on the `searxng` subchart.

## Installing the Chart

Add the repository:

```bash
helm repo add thangmai-charts https://ducthangqd1998.github.io/charts
helm repo update
```

### Option A: Out-of-the-box (Bundled SearXNG subchart)

```bash
helm install my-crw thangmai-charts/crw
```

### Option B: Use an existing external SearXNG backend

```bash
helm install my-crw thangmai-charts/crw \
  --set searxng.enabled=false \
  --set search.backendUrl="http://searxng.default.svc.cluster.local:8080"
```

## Configuration

### FastCRW Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of FastCRW replicas (ignored when `autoscaling.enabled: true`) | `1` |
| `image.repository` | FastCRW container image repository | `ghcr.io/fastcrw/crw` |
| `image.tag` | FastCRW image tag | `0.42.1` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `serviceAccount.create` | Create a dedicated ServiceAccount | `true` |
| `serviceAccount.automount` | Automount ServiceAccount API credentials | `false` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service HTTP port | `3000` |
| `service.targetPort` | Container HTTP port | `3000` |
| `search.enabled` | Enable web search capabilities | `true` |
| `search.backendUrl` | URL to search backend (auto-resolved if `searxng.enabled` is `true`) | `""` |
| `resources.requests` | CPU/Memory requests | `cpu: 100m, memory: 128Mi` |
| `resources.limits` | Memory limits | `memory: 256Mi` |
| `startupProbe` | Optional container startup probe | `{}` |
| `livenessProbe` | Container liveness probe (`/health`) | HTTP GET `:http/health` |
| `readinessProbe` | Container readiness probe (`/health`) | HTTP GET `:http/health` |
| `lifecycle` | Container lifecycle hooks | `preStop: sleep 10` |
| `terminationGracePeriodSeconds` | Pod termination grace period | `60` |

### SearXNG Subchart Dependency Parameters

Values under the `searxng:` key are passed directly to the upstream SearXNG subchart.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `searxng.enabled` | Deploy bundled SearXNG subchart dependency | `true` |
| `searxng.secret.create` | Create SearXNG runtime Secret via Helm | `true` |
| `searxng.secret.existingSecret` | Existing Secret name for GitOps / Argo CD (`SEARXNG_SECRET`) | `""` |
| `searxng.config.useDefaultSettings` | Use SearXNG default settings | `true` |
| `searxng.config.settings.search.formats` | Formats enabled for SearXNG | `[html, json]` |
| `searxng.persistence.cache.enabled` | Enable PVC for SearXNG cache (`false` uses stateless `emptyDir`) | `false` |
| `searxng.valkey.enabled` | Enable Valkey caching/rate-limiting | `false` |

### Autoscaling, Networking & Resilience

| Parameter | Description | Default |
|-----------|-------------|---------|
| `autoscaling.enabled` | Enable `autoscaling/v2` HorizontalPodAutoscaler | `false` |
| `autoscaling.minReplicas` | Minimum replicas when HPA is enabled | `2` |
| `autoscaling.maxReplicas` | Maximum replicas when HPA is enabled | `10` |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU utilization percentage | `80` |
| `ingress.enabled` | Enable standard `networking.k8s.io/v1` Ingress | `false` |
| `ingress.className` | IngressClass to use | `""` |
| `ingress.hosts` | List of host rules | See `values.yaml` |
| `httpRoute.enabled` | Enable Gateway API `HTTPRoute` | `false` |
| `httpRoute.parentRefs` | Parent Gateway references | `[]` |
| `httpRoute.rules` | Custom routing, matches, filters, and timeouts | `[]` |
| `podDisruptionBudget.enabled` | Enable PDB (`minAvailable` / `maxUnavailable` mutually exclusive) | `false` |
| `networkPolicy.enabled` | Enable NetworkPolicy (renders sensible defaults when `ingress`/`egress` are empty) | `false` |

## Example Configurations

- [Development Values (NodePort, lightweight, SearXNG disabled)](examples/development-values.yaml)
- [Production Values (HA, Ingress with TLS, PDB, bundled SearXNG)](examples/production-values.yaml)
- [External SearXNG Backend (Standalone CRW)](examples/external-searxng-values.yaml)
- [Gateway API Values (Kubernetes Gateway API HTTPRoute)](examples/gateway-api-values.yaml)

## Usage Examples

### 1. Web Search Query (`/v1/search`)

```bash
curl -X POST http://<CRW-HOST>:3000/v1/search \
  -H "Content-Type: application/json" \
  -d '{"query": "Latest breakthroughs in AI", "limit": 5}'
```

### 2. Scrape Web Page to Clean Markdown (`/v1/scrape`)

```bash
curl -X POST http://<CRW-HOST>:3000/v1/scrape \
  -H "Content-Type: application/json" \
  -d '{"url": "https://news.ycombinator.com"}'
```

### 3. Model Context Protocol (MCP) Integration

FastCRW includes built-in MCP server capabilities. Add this to your Claude Desktop / Claude Code / Cursor MCP configuration:

```json
{
  "mcpServers": {
    "crw": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "--network=host", "ghcr.io/fastcrw/crw:0.42.1", "mcp"]
    }
  }
}
```

## Uninstalling

```bash
helm uninstall my-crw
```
