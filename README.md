# Thang Mai's Helm Charts Collection

Welcome to my collection of Helm charts for tools and applications that don't have official Helm charts or need better Kubernetes integration.

## About

This repository contains Helm charts that I've created to fill gaps in the Kubernetes ecosystem. As a DevOps engineer, I often encounter excellent tools that lack proper Helm charts for easy Kubernetes deployment. This collection aims to bridge that gap.

## Available Charts

### [Metrics Accumulator](./metrics-accumulator)

A Helm chart for [bpoole6/metrics-accumulator](https://github.com/bpoole6/metrics-accumulator) - an alternative to Prometheus Pushgateway specifically designed for Lambda functions and ephemeral workloads.

**Why this chart was created:**
- Prometheus Pushgateway doesn't handle Lambda metrics well (no TTL support)
- Metrics Accumulator solves the Lambda metrics collection challenge
- The original project lacked a Helm chart for Kubernetes deployment

**Features:**
- Production-ready configuration
- ServiceMonitor support for Prometheus Operator
- Comprehensive security options
- Examples for both development and production environments

## Installation

### Add Helm Repository

```bash
helm repo add thangmai-charts https://ducthangqd1998.github.io/charts
helm repo update
```

### Install a Chart

```bash
# Install metrics-accumulator
helm install my-metrics-accumulator thangmai-charts/metrics-accumulator
```

### Install from Source

```bash
git clone https://github.com/ducthangqd1998/charts.git
cd charts
helm install my-release ./chart-name
```

## Charts in Development

I'm working on Helm charts for other useful tools that lack proper Kubernetes integration:

- **Monitoring Tools**: Additional observability solutions for specialized use cases
- **Lambda Integration Tools**: More tools for connecting serverless workloads with Kubernetes
- **Development Utilities**: Charts for development and testing environments

## Why These Charts?

As someone who works extensively with Kubernetes and Lambda functions, I've encountered several pain points:

1. **Lambda Metrics Collection**: Traditional tools like Pushgateway aren't optimized for ephemeral workloads
2. **Missing Helm Charts**: Many excellent tools lack official Helm charts
3. **Production-Ready Configurations**: Need charts with comprehensive security and production features
4. **Vietnamese DevOps Community**: Sharing knowledge and tools with the Vietnamese tech community

## Contributing

I welcome contributions, suggestions, and feedback! If you:

- Find bugs in existing charts
- Want to suggest new tools that need Helm charts
- Have improvements for existing configurations
- Want to contribute new charts

Please feel free to:
- Open an issue for discussions
- Submit pull requests
- Share your use cases and configurations

## Chart Standards

All charts in this repository follow these standards:

- ✅ **Production-ready**: Comprehensive security and configuration options
- ✅ **Well-documented**: Clear README with examples and configuration tables
- ✅ **Best Practices**: Following Helm and Kubernetes best practices
- ✅ **Examples**: Development and production value examples
- ✅ **Testing**: Validation scripts and testing procedures

## Roadmap

- [ ] Add GitHub Actions for automated chart testing and publishing
- [ ] Create more charts for Lambda integration tools
- [ ] Add Grafana dashboards for monitoring the deployed applications
- [ ] Vietnamese documentation for charts
- [ ] Community feedback integration

## Acknowledgments

Special thanks to the open-source community and the original authors of the tools I'm creating charts for:

- [bpoole6](https://github.com/bpoole6) for Metrics Accumulator
- The Kubernetes and Helm communities for excellent tooling
- The Vietnamese DevOps community for inspiration and feedback

## Contact

- **GitHub**: [@ducthangqd1998](https://github.com/ducthangqd1998)
- **Repository**: [https://github.com/ducthangqd1998/charts](https://github.com/ducthangqd1998/charts)

## License

All charts in this repository are licensed under the [Apache 2.0 License](LICENSE), same as the tools they deploy.

---

*Building better Kubernetes deployments, one chart at a time.* 🚀 