# Helm Charts

This repository contains community Helm charts for Kubernetes tooling and infrastructure components.

## Available Charts

### [aws-alb-gateway](./charts/aws-alb-gateway)

A Helm chart for managing Kubernetes Gateway API resources and AWS Load Balancer Controller Gateway resources on EKS.

It can render:

- `Gateway`
- `HTTPRoute`
- `LoadBalancerConfiguration`
- `TargetGroupConfiguration`
- Optional `ReferenceGrant`

### [metrics-accumulator](./charts/metrics-accumulator)

A Helm chart for [metrics-accumulator](https://github.com/bpoole6/metrics-accumulator), an alternative to Prometheus Pushgateway for ephemeral workloads.

It includes:

- Configurable deployment settings.
- Service and ingress support.
- Optional persistence.
- Optional ServiceMonitor support for Prometheus Operator.
- Security-related options such as NetworkPolicy and PodDisruptionBudget.

## Installation

Add the Helm repository:

```bash
helm repo add thangmai-charts https://ducthangqd1998.github.io/charts
helm repo update
```

Install a chart from the repository:

```bash
helm install my-release thangmai-charts/<chart-name>
```

Install a chart from source:

```bash
git clone https://github.com/ducthangqd1998/charts.git
cd charts
helm install my-release ./charts/<chart-name>
```

## Documentation

- [aws-alb-gateway documentation](./charts/aws-alb-gateway/README.md)
- [metrics-accumulator documentation](./charts/metrics-accumulator/README.md)
- [Contributing guide](./CONTRIBUTING.md)

## Chart Standards

Charts in this repository should follow these standards:

- Pass `helm lint`.
- Render successfully with default values and documented examples.
- Include clear default values.
- Include a chart README with installation, configuration, examples, and troubleshooting notes.
- Follow Kubernetes and Helm labeling conventions.
- Avoid publishing environment-specific or organization-specific details in public examples.

## Contributing

Contributions, bug reports, and chart requests are welcome. See [CONTRIBUTING.md](./CONTRIBUTING.md) for development and review guidelines.

## License

Charts in this repository are distributed under the [Apache 2.0 License](./LICENSE).
