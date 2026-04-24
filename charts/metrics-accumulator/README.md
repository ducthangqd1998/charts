# Metrics Accumulator Helm Chart

## Background

Ephemeral workloads can be difficult to monitor with tools that assume metrics should remain available until explicitly deleted. This can lead to stale metrics when short-lived jobs finish and no longer update their values.

[Metrics Accumulator](https://github.com/bpoole6/metrics-accumulator) addresses this use case for ephemeral and short-lived jobs. This chart packages Metrics Accumulator for deployment on Kubernetes with Helm.

Special thanks to [bpoole6](https://github.com/bpoole6) for creating the Metrics Accumulator project.

## Introduction

This chart deploys [metrics-accumulator](https://github.com/bpoole6/metrics-accumulator) on a Kubernetes cluster using the [Helm](https://helm.sh) package manager.

Metrics Accumulator is designed as an alternative to Prometheus Pushgateway for short-lived and ephemeral workloads.

## Prerequisites

- Kubernetes 1.16+
- Helm 3.0+

## Installing the Chart

To install the chart with the release name `my-metrics-accumulator`:

```bash
helm repo add thangmai-charts https://ducthangqd1998.github.io/charts
helm install my-metrics-accumulator thangmai-charts/metrics-accumulator
```

Or install directly from source:

```bash
git clone https://github.com/ducthangqd1998/charts.git
cd charts
helm install my-metrics-accumulator ./charts/metrics-accumulator
```

The command deploys metrics-accumulator on the Kubernetes cluster with the default configuration. The [Configuration](#configuration) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-metrics-accumulator` deployment:

```bash
helm uninstall my-metrics-accumulator
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the chart and their default values.

### Basic Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Image repository | `bpoole6/metrics-accumulator` |
| `image.tag` | Image tag | `""` (uses appVersion) |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `nameOverride` | Override chart name | `""` |
| `fullnameOverride` | Override chart fullname | `""` |

### Service Account

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceAccount.create` | Create service account | `true` |
| `serviceAccount.annotations` | Service account annotations | `{}` |
| `serviceAccount.name` | Service account name | `""` |

### Service

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `8080` |
| `service.targetPort` | Target port | `8080` |
| `service.annotations` | Service annotations | `{}` |

### Ingress

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class name | `""` |
| `ingress.annotations` | Ingress annotations | `{}` |
| `ingress.hosts` | Ingress hosts | `[{host: "metrics-accumulator.local", paths: [{path: "/", pathType: "Prefix"}]}]` |
| `ingress.tls` | TLS configuration | `[]` |

### Resources

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources` | CPU/Memory requests and limits | `{}` |

### Autoscaling

| Parameter | Description | Default |
|-----------|-------------|---------|
| `autoscaling.enabled` | Enable autoscaling | `false` |
| `autoscaling.minReplicas` | Minimum replicas | `1` |
| `autoscaling.maxReplicas` | Maximum replicas | `10` |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU utilization | `80` |

### Persistence

| Parameter | Description | Default |
|-----------|-------------|---------|
| `persistence.enabled` | Enable persistent storage | `false` |
| `persistence.accessMode` | PVC access mode | `ReadWriteOnce` |
| `persistence.size` | Storage size | `1Gi` |
| `persistence.storageClass` | Storage class | `""` |
| `persistence.mountPath` | Mount path | `/data` |

### ServiceMonitor (Prometheus Operator)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceMonitor.enabled` | Create ServiceMonitor | `false` |
| `serviceMonitor.interval` | Scrape interval | `30s` |
| `serviceMonitor.scrapeTimeout` | Scrape timeout | `10s` |
| `serviceMonitor.path` | Metrics path | `/metrics` |

### Security

| Parameter | Description | Default |
|-----------|-------------|---------|
| `networkPolicy.enabled` | Enable NetworkPolicy | `false` |
| `podDisruptionBudget.enabled` | Enable PodDisruptionBudget | `false` |

## Usage

### Pushing Metrics

To push metrics to metrics-accumulator:

```python
import json
import urllib3

def handler(event, context):
    execution_time = 123

    # Push metrics to metrics-accumulator
    http = urllib3.PoolManager()

    metric_data = {
        "hostname": "example-host",
        "endpoint": "example-job",
        "request_method": "POST",
        "status_code": 200,
        "pid": 1234,
        "value": execution_time
    }

    response = http.request(
        'POST',
        'http://your-metrics-accumulator-url/api/v1/metrics',
        headers={'Content-Type': 'application/json'},
        body=json.dumps(metric_data)
    )

    return {
        'statusCode': 200,
        'body': json.dumps('Success')
    }
```

### Viewing Metrics

To view accumulated metrics in Prometheus format:

```bash
curl http://your-metrics-accumulator-url/metrics
```

### Configuring Prometheus

Add the following job to your Prometheus configuration:

```yaml
scrape_configs:
  - job_name: 'metrics-accumulator'
    static_configs:
      - targets: ['metrics-accumulator.default.svc.cluster.local:8080']
    metrics_path: '/metrics'
    honor_labels: true
```

## Comparison with Pushgateway

| Feature | Pushgateway | Metrics Accumulator |
|---------|-------------|-------------------|
| Lambda Support | Limited | Optimized |
| Short-lived Jobs | Basic | Advanced |
| TTL Support | Manual | Built-in |
| API | REST | REST + Enhanced |
| Performance | Good | Optimized for ephemeral jobs |

## Why Metrics Accumulator over Pushgateway?

1. **No TTL Issues**: Metrics Accumulator handles metric lifecycle better for ephemeral workloads
2. **Short-Lived Workload Support**: Designed for jobs that start, publish metrics, and exit
3. **Better Resource Management**: More efficient handling of transient metrics
4. **Enhanced API**: Provides additional endpoints for better observability

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=metrics-accumulator
```

### View Logs

```bash
kubectl logs -l app.kubernetes.io/name=metrics-accumulator
```

### Check Service

```bash
kubectl get svc metrics-accumulator
```

## Contributing

Please read [CONTRIBUTING.md](../../CONTRIBUTING.md) for details on the process for submitting pull requests.

## Acknowledgments

- Thanks to [bpoole6](https://github.com/bpoole6) for the original [Metrics Accumulator](https://github.com/bpoole6/metrics-accumulator) project
- Inspired by the need for better metrics collection from ephemeral workloads in Kubernetes environments

## License

This chart is distributed under the [Apache 2.0 License](https://www.apache.org/licenses/LICENSE-2.0).

## Repository

This Helm chart is maintained at: https://github.com/ducthangqd1998/charts
