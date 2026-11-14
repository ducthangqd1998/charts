# Metrics Accumulator Helm Chart

## Background

Ephemeral workloads can be difficult to monitor with tools that assume metrics should remain available until explicitly deleted. This can lead to stale metrics when short-lived jobs finish and no longer update their values.

[Metrics Accumulator](https://github.com/bpoole6/metrics-accumulator) addresses this use case for ephemeral and short-lived jobs (AWS Lambda, Cloud Run, Kubernetes Jobs, CronJobs). This chart packages Metrics Accumulator for deployment on Kubernetes with Helm.

Special thanks to [bpoole6](https://github.com/bpoole6) for creating the Metrics Accumulator project.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+

## Installing the Chart

To install the chart with the release name `my-metrics-accumulator`:

```bash
helm repo add thangmai-charts https://ducthangqd1998.github.io/charts
helm repo update
helm install my-metrics-accumulator thangmai-charts/metrics-accumulator
```

Or install directly from source:

```bash
git clone https://github.com/ducthangqd1998/charts.git
cd charts
helm install my-metrics-accumulator ./charts/metrics-accumulator
```

## Uninstalling the Chart

```bash
helm uninstall my-metrics-accumulator
```

## Configuration

### Basic Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas (ignored when `autoscaling.enabled: true`) | `1` |
| `image.repository` | Image repository | `bpoole6/metrics-accumulator` |
| `image.tag` | Image tag (defaults to `Chart.appVersion`) | `""` (`2.0.1`) |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `nameOverride` | Override chart name | `""` |
| `fullnameOverride` | Override chart fullname | `""` |
| `commonLabels` | Labels applied to all rendered resources | `{}` |

### ServiceAccount & Security (PSS Restricted)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceAccount.create` | Create service account | `true` |
| `serviceAccount.automount` | Automount ServiceAccount token | `false` |
| `serviceAccount.annotations` | Service account annotations | `{}` |
| `serviceAccount.name` | Service account name | `""` |
| `podSecurityContext` | Pod security context (`runAsNonRoot: true`, UID `10001`, `seccompProfile: RuntimeDefault`) | Restricted defaults |
| `securityContext` | Container security context (`readOnlyRootFilesystem: true`, `allowPrivilegeEscalation: false`, `capabilities.drop: [ALL]`) | Restricted defaults |

### Service & Ingress

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `8080` |
| `service.targetPort` | Container port | `8080` |
| `service.annotations` | Service annotations | `{}` |
| `ingress.enabled` | Enable `networking.k8s.io/v1` Ingress | `false` |
| `ingress.className` | IngressClass name | `""` |
| `ingress.annotations` | Ingress annotations | `{}` |
| `ingress.hosts` | Ingress host rules | See `values.yaml` |
| `ingress.tls` | Ingress TLS configuration | `[]` |

### Resources, Lifecycle & Probes

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.requests` | CPU and memory requests | `cpu: 100m, memory: 256Mi` |
| `resources.limits` | Memory limit | `memory: 512Mi` |
| `startupProbe` | HTTP GET probe on `/service-discovery` (`port: http`) | Enabled |
| `livenessProbe` | HTTP GET probe on `/service-discovery` (`port: http`) | Enabled |
| `readinessProbe` | HTTP GET probe on `/service-discovery` (`port: http`) | Enabled |
| `lifecycle` | Container lifecycle hooks | `preStop: sleep 10` |
| `terminationGracePeriodSeconds` | Pod termination grace period | `60` |

### Autoscaling, Persistence & Observability

| Parameter | Description | Default |
|-----------|-------------|---------|
| `autoscaling.enabled` | Enable `autoscaling/v2` HorizontalPodAutoscaler | `false` |
| `autoscaling.minReplicas` | Minimum replicas | `2` |
| `autoscaling.maxReplicas` | Maximum replicas | `10` |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU utilization | `80` |
| `persistence.enabled` | Enable PVC storage (`ReadWriteOnce` requires single replica or `ReadWriteMany` StorageClass) | `false` |
| `persistence.accessMode` | PVC access mode | `ReadWriteOnce` |
| `persistence.size` | Storage size | `1Gi` |
| `persistence.mountPath` | Container mount path | `/data` |
| `serviceMonitor.enabled` | Create Prometheus Operator `ServiceMonitor` | `false` |
| `serviceMonitor.interval` | Scrape interval | `30s` |
| `serviceMonitor.scrapeTimeout` | Scrape timeout | `10s` |
| `serviceMonitor.path` | Metrics scrape path (`/metrics/{metricGroup}`) | `/metrics/default` |
| `serviceMonitor.honorLabels` | Preserve pushed metric labels on scrape | `true` |
| `networkPolicy.enabled` | Enable NetworkPolicy | `false` |
| `podDisruptionBudget.enabled` | Enable PodDisruptionBudget (`minAvailable: 1` default) | `false` |
| `config` | Raw YAML configuration mounted at `/etc/metrics-accumulator/metrics-accumulator.yml` | `""` |

### Secure Configuration & API Keys

> **Security Warning:** Never commit plaintext `apiKey` secrets inside `values.yaml` (`config`).
> For production deployments, store your `metrics-accumulator.yml` containing `apiKey` values in a Kubernetes `Secret` (managed by External Secrets Operator, Vault, or SealedSecrets), mount it via `volumes` + `volumeMounts`, and pass `--config-file=/etc/metrics-accumulator-secret/metrics-accumulator.yml` in `extraArgs` (or inject environment variables via `extraEnv` / `extraEnvFrom`).

When `config` is non-empty, the chart automatically:
1. Renders a `ConfigMap` (`<fullname>-config`).
2. Mounts it read-only at `/etc/metrics-accumulator/metrics-accumulator.yml`.
3. Passes `--config-file=/etc/metrics-accumulator/metrics-accumulator.yml` to container `args`.
4. Annotates Pod templates with `checksum/config` so config updates trigger a rolling restart.

## Usage

### Pushing Metrics (`/update/{metricGroup}`)

Metrics Accumulator accepts Prometheus text exposition payloads via `POST /update/{metricGroup}` authenticated with the `X-API-KEY` header:

```bash
curl -X POST "http://metrics-accumulator:8080/update/default" \
  -H "X-API-KEY: <your-metric-group-api-key>" \
  -H "Content-Type: text/plain" \
  --data-binary $'# TYPE lambda_invocations_total counter\nlambda_invocations_total{function="billing"} 1.0\n'
```

### Viewing Metrics (`/metrics/{metricGroup}`)

```bash
curl "http://metrics-accumulator:8080/metrics/default"
```

### Configuring Prometheus (`/service-discovery` or Static Scrape)

Metrics Accumulator exposes a native Prometheus HTTP Service Discovery endpoint at `/service-discovery`:

```yaml
scrape_configs:
  - job_name: 'metrics-accumulator'
    honor_labels: true
    http_sd_configs:
      - url: 'http://metrics-accumulator.default.svc.cluster.local:8080/service-discovery'
```

Or scrape a specific metric group directly:

```yaml
scrape_configs:
  - job_name: 'metrics-accumulator-default'
    metrics_path: '/metrics/default'
    honor_labels: true
    static_configs:
      - targets: ['metrics-accumulator.default.svc.cluster.local:8080']
```

## Troubleshooting

```bash
kubectl get pods -l app.kubernetes.io/name=metrics-accumulator
kubectl logs -l app.kubernetes.io/name=metrics-accumulator
kubectl get svc -l app.kubernetes.io/name=metrics-accumulator
```

## Contributing

Please read [CONTRIBUTING.md](../../CONTRIBUTING.md) for details on submitting pull requests.

## License

This chart is distributed under the [Apache 2.0 License](../../LICENSE).
