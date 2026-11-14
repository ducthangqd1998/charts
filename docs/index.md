# Helm Charts Repository

This site documents the Helm charts published from this repository.

## Available Charts

- [aws-alb-gateway](../charts/aws-alb-gateway)
  - Manage Kubernetes Gateway API resources and AWS Load Balancer Controller Gateway resources on EKS.
- [metrics-accumulator](../charts/metrics-accumulator)
  - Deploy [metrics-accumulator](https://github.com/bpoole6/metrics-accumulator) for collecting metrics from ephemeral workloads.
- [crw](../charts/crw)
  - Deploy FastCRW as a self-hosted Tavily/Firecrawl alternative AI search & web scraping API.
- [9router](../charts/9router)
  - Deploy 9Router as a unified AI routing and OpenAI-compatible LLM proxy gateway.

## Usage

Add the Helm repository:

```bash
helm repo add thangmai-charts https://ducthangqd1998.github.io/charts
helm repo update
```

Install a chart:

```bash
helm install my-release thangmai-charts/<chart-name>
```

## Documentation

- [9router chart documentation](../charts/9router/README.md)
- [aws-alb-gateway chart documentation](../charts/aws-alb-gateway/README.md)
- [crw chart documentation](../charts/crw/README.md)
- [metrics-accumulator chart documentation](../charts/metrics-accumulator/README.md)
- [Contributing guide](../CONTRIBUTING.md)

## Links

- [GitHub repository](https://github.com/ducthangqd1998/charts)
- [Artifact Hub packages](https://artifacthub.io/packages/search?repo=thangmai-charts)
