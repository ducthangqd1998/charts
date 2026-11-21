# Helm Charts

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/thangmai-charts)](https://artifacthub.io/packages/search?repo=thangmai-charts)

Community Helm chart repository published via GitHub Pages and [chart-releaser](https://github.com/helm/chart-releaser).

## Usage

Add the Helm repository:

```bash
helm repo add thangmai-charts https://ducthangqd1998.github.io/charts
helm repo update
```

Search available charts:

```bash
helm search repo thangmai-charts
```

Install a chart:

```bash
helm install my-release thangmai-charts/<chart-name>
```

## Available Charts

| Chart | Description | Documentation |
|---|---|---|
| **9router** | Unified AI routing and OpenAI-compatible LLM proxy gateway with Pod Security Standards (`Restricted`). | [9router README](https://github.com/ducthangqd1998/charts/blob/master/charts/9router/README.md) |
| **aws-alb-gateway** | Manage Kubernetes Gateway API and AWS Load Balancer Controller Gateway resources on EKS. | [aws-alb-gateway README](https://github.com/ducthangqd1998/charts/blob/master/charts/aws-alb-gateway/README.md) |
| **crw** | Self-hosted FastCRW web scraping, crawling, and AI search API with optional SearXNG integration. | [crw README](https://github.com/ducthangqd1998/charts/blob/master/charts/crw/README.md) |
| **metrics-accumulator** | Alternative to Prometheus Pushgateway for collecting metrics from ephemeral workloads. | [metrics-accumulator README](https://github.com/ducthangqd1998/charts/blob/master/charts/metrics-accumulator/README.md) |

## Links

- [Source Repository (`master`)](https://github.com/ducthangqd1998/charts)
- [Helm Repository Index (`index.yaml`)](https://ducthangqd1998.github.io/charts/index.yaml)
- [Contributing Guide](https://github.com/ducthangqd1998/charts/blob/master/CONTRIBUTING.md)
- [Releases](https://github.com/ducthangqd1998/charts/releases)
