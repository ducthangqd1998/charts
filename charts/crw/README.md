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
- **Auto-Discovery**: FastCRW automatically detects the internal SearXNG subchart service endpoint without manual wiring.
- **External Search Backend Support**: Simply set `searxng.enabled: false` and point `search.backendUrl` to any existing cluster or external SearXNG instance.
- **Native Model Context Protocol (MCP)**: Directly connects to MCP-compatible coding agents (Claude Code, Cursor).
- **Hardened Security**:
  - Non-root execution (`runAsNonRoot: true`, UID `10001`).
  - Read-only root filesystem (`readOnlyRootFilesystem: true`).
  - Drop all Linux capabilities (`capabilities.drop: [ALL]`).
- **Vendor-Neutral Networking**: Supports standard Kubernetes `Ingress` and Gateway API `HTTPRoute`.
- **Production Ready**: PodDisruptionBudget, ServiceAccount, NetworkPolicy, probes, and resource controls.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+

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
| `replicaCount` | Number of FastCRW replicas | `1` |
| `image.repository` | FastCRW container image repository | `ghcr.io/fastcrw/crw` |
| `image.tag` | FastCRW image tag | `0.42.1` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service HTTP port | `3000` |
| `search.enabled` | Enable web search capabilities | `true` |
| `search.backendUrl` | URL to search backend (auto-resolved if searxng is enabled) | `""` |
| `resources.requests` | CPU/Memory requests | `cpu: 100m, memory: 128Mi` |
| `resources.limits` | Memory limits | `memory: 256Mi` |

### SearXNG Subchart Dependency Parameters

Values under the `searxng:` key are passed directly to the upstream SearXNG subchart.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `searxng.enabled` | Deploy bundled SearXNG subchart dependency | `true` |
| `searxng.config.useDefaultSettings` | Use SearXNG default settings | `true` |
| `searxng.config.settings.search.formats`| Formats enabled for SearXNG | `[html, json]` |
| `searxng.valkey.enabled` | Enable Valkey caching/rate-limiting | `false` |

### Networking & Ingress

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable standard Ingress | `false` |
| `ingress.className` | IngressClass to use | `""` |
| `ingress.hosts` | List of host rules | See `values.yaml` |
| `httpRoute.enabled` | Enable Gateway API HTTPRoute | `false` |
| `httpRoute.parentRefs` | Parent Gateway references | `[]` |
| `httpRoute.rules` | Custom routing, header matches, and filters | `[]` |
| `podDisruptionBudget.enabled` | Enable PDB for high availability | `false` |
| `networkPolicy.enabled` | Enable NetworkPolicy | `false` |

## Example Configurations

- [Development Values (NodePort, lightweight)](examples/development-values.yaml)
- [Production Values (HA, Ingress with TLS, PDB)](examples/production-values.yaml)
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
