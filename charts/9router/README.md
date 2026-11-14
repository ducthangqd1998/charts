# 9router

Deploy [9Router](https://github.com/decolua/9router), a unified AI routing and OpenAI-compatible LLM proxy gateway, on Kubernetes with Pod Security Standards (`Restricted`) hardening out of the box.

## Architecture

```text
Client / Gateway API / Ingress
            |
            v
    Service (ClusterIP :20128)
            |
            v
    Deployment (9router :20128)
      ├── DATA_DIR (/app/data) -> PersistentVolumeClaim or emptyDir
      ├── /tmp                 -> emptyDir
      └── /home/node/.npm      -> emptyDir
```

## Prerequisites

- Kubernetes 1.25+
- Helm 3.12+
- Gateway API CRDs (`gateway.networking.k8s.io/v1`) if `httpRoute.enabled=true`
- A default `StorageClass` (or explicit `persistence.storageClass`) if `persistence.enabled=true`

## Security & Runtime Notes

- **Pod Security Standards (`Restricted`):** Runs as UID/GID `1000` (`runAsNonRoot: true`), `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true`, `capabilities.drop: ["ALL"]`, `seccompProfile.type: RuntimeDefault`, and `automountServiceAccountToken: false`.
- **Entrypoint Override:** The upstream `decolua/9router` container entrypoint uses `su-exec`, which requires root privileges. This chart defaults `command` to `["node", "custom-server.js"]` so the server starts cleanly as a non-root user.
- **Writable Scratch Mounts:** `/app/data`, `/tmp`, and `/home/node/.npm` are mounted as writable volumes (`emptyDir` for scratch paths and `emptyDir` or `PersistentVolumeClaim` for `/app/data`) so `readOnlyRootFilesystem: true` works without runtime errors.
- **Secrets Management:** Never place API keys directly in `values.yaml`. Create a Kubernetes `Secret` (or sync one with External Secrets Operator / Sealed Secrets) and pass it via `extraEnvFrom` or `extraEnv`.

## Installation

### Add the Helm Repository

```bash
helm repo add thangmai-charts https://ducthangqd1998.github.io/charts
helm repo update
```

### Install the Chart

```bash
helm install my-9router thangmai-charts/9router \
  --namespace ai-tools \
  --create-namespace
```

### Install with Persistence & Custom Secret

```bash
kubectl create secret generic 9router-secrets \
  --namespace ai-tools \
  --from-literal=JWT_SECRET=change-me

helm install my-9router thangmai-charts/9router \
  --namespace ai-tools \
  --set persistence.enabled=true \
  --set 'extraEnvFrom[0].secretRef.name=9router-secrets'
```

## Configuration

| Key | Description | Default |
|---|---|---|
| `replicaCount` | Number of Deployment replicas (ignored when `autoscaling.enabled=true`) | `1` |
| `image.repository` | Container image repository | `decolua/9router` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `image.tag` | Image tag override (defaults to `Chart.appVersion`, rejects `latest`) | `""` |
| `command` | Container command (bypasses root-only `su-exec` entrypoint) | `["node", "custom-server.js"]` |
| `args` | Container arguments | `[]` |
| `strategy` | Deployment update strategy (auto-uses `Recreate` with `ReadWriteOnce` PVC) | `{}` |
| `serviceAccount.create` | Create a dedicated ServiceAccount | `true` |
| `serviceAccount.automount` | Automount ServiceAccount token in Pods | `false` |
| `service.type` | Kubernetes Service type | `ClusterIP` |
| `service.port` | Service listening port | `20128` |
| `service.targetPort` | Container listening port | `20128` |
| `ingress.enabled` | Enable standard `networking.k8s.io/v1` Ingress | `false` |
| `httpRoute.enabled` | Enable Gateway API `gateway.networking.k8s.io/v1` HTTPRoute | `false` |
| `httpRoute.parentRefs` | Gateway `parentRefs` for HTTPRoute | `[]` |
| `httpRoute.hostnames` | Hostnames matched by HTTPRoute | `[]` |
| `httpRoute.rules` | Custom HTTPRoute rules (defaults `backendRefs` to the chart Service) | `[]` |
| `resources.requests` | CPU and memory requests | `100m` / `256Mi` |
| `resources.limits` | Memory limit (CPU limit omitted to prevent CFS throttling) | `512Mi` |
| `persistence.enabled` | Enable PVC for `DATA_DIR` (uses `emptyDir` when `false`) | `false` |
| `persistence.storageClass` | StorageClass name (`""` = cluster default, `"-"` = disable dynamic provisioning) | `""` |
| `persistence.size` | Requested PVC size | `5Gi` |
| `persistence.mountPath` | Mount path for persistent data | `/app/data` |
| `env` | Plain key/value environment variables | `DATA_DIR`, `HOSTNAME`, `NODE_ENV`, `PORT` |
| `extraEnv` | Additional env entries (`valueFrom`, `secretKeyRef`, etc.) | `[]` |
| `extraEnvFrom` | Additional `envFrom` sources (`secretRef`, `configMapRef`) | `[]` |
| `autoscaling.enabled` | Enable HPA `autoscaling/v2` (incompatible with `ReadWriteOnce` PVC) | `false` |
| `podDisruptionBudget.enabled` | Enable `policy/v1` PodDisruptionBudget | `false` |
| `networkPolicy.enabled` | Enable default-deny ingress/egress NetworkPolicy | `false` |
| `terminationGracePeriodSeconds` | Grace period before SIGKILL | `60` |

See [values.yaml](./values.yaml) for the complete set of configurable options.

## Examples

- [examples/development-values.yaml](./examples/development-values.yaml): Minimal ephemeral configuration for local development.
- [examples/production-values.yaml](./examples/production-values.yaml): Stateless HA configuration with Ingress, HPA, PDB, NetworkPolicy, and topology spread.
- [examples/gateway-api-values.yaml](./examples/gateway-api-values.yaml): Single-instance persistent setup exposed via Gateway API `HTTPRoute`.

## Uninstalling

```bash
helm uninstall my-9router --namespace ai-tools
```
