# aws-alb-gateway

`aws-alb-gateway` is a Helm chart for managing Kubernetes Gateway API resources and AWS Load Balancer Controller Gateway resources on EKS.

The chart renders:

- `Gateway`
- `LoadBalancerConfiguration`
- `TargetGroupConfiguration`
- `HTTPRoute`
- Optional `ReferenceGrant`

It does not install application workloads. Use it to define ALB-backed Gateway API entry points and route existing Kubernetes Services through them.

## Overview

AWS Load Balancer Controller can create an Application Load Balancer from a Kubernetes `Gateway`. Services are attached to that Gateway with Gateway API routes such as `HTTPRoute`.

This chart supports two gateway modes:

- `shared`: attach routes to an existing Gateway. The chart does not create the Gateway.
- `dedicated`: create a Gateway, AWS load balancer configuration, optional default target group configuration, and routes.

The default target type is `ip` through `global.defaultTargetType`. You can override it globally, per Gateway default target group, or per route target group.

## Prerequisites

Before installing this chart, the cluster should have:

- Kubernetes Gateway API CRDs installed.
- AWS Load Balancer Controller installed with Gateway API support.
- AWS Load Balancer Controller Gateway CRDs installed.
- A `GatewayClass` matching `global.gatewayClassName`. The default is `alb`.
- Valid AWS permissions and infrastructure configuration for ALB provisioning.
- ACM certificates when using HTTPS listeners with `certificateArn`.

## Install

Example values are available in:

- `examples/shared-gateway-values.yaml`
- `examples/dedicated-gateway-values.yaml`
- `examples/multi-gateway-values.yaml`

Render the chart:

```sh
helm template my-gateway ./charts/aws-alb-gateway \
  -f ./charts/aws-alb-gateway/examples/shared-gateway-values.yaml
```

Install or upgrade:

```sh
helm upgrade --install my-gateway ./charts/aws-alb-gateway \
  --namespace gateway-system \
  --create-namespace \
  -f ./charts/aws-alb-gateway/examples/shared-gateway-values.yaml
```

Verify the rendered resources:

```sh
kubectl get gateway,httproute,targetgroupconfiguration,loadbalancerconfiguration -A
kubectl describe gateway -n gateway-system shared-gateway
kubectl describe httproute -n example-app example-app
```

## Shared Gateway Example

Use `shared` mode when the Gateway already exists and this release should only manage routes and optional service target group configuration.

```yaml
global:
  gatewayClassName: alb
  defaultTargetType: ip

gateways:
  shared:
    enabled: true
    mode: shared
    name: shared-gateway
    namespace: gateway-system
    sectionName: https

routes:
  example-app:
    enabled: true
    gateway: shared
    namespace: example-app
    name: example-app
    hostnames:
      - app.example.org
    rules:
      - matches:
          - path:
              type: PathPrefix
              value: /
        backendRefs:
          - name: example-app
            port: 80
    targetGroup:
      enabled: true
      healthCheck:
        path: /healthz
        protocol: HTTP
        port: traffic-port
        matcher:
          httpCode: "200"
    referenceGrant:
      enabled: true
```

When the route namespace is different from the Gateway namespace, the chart adds the Gateway namespace to `HTTPRoute.spec.parentRefs`. `ReferenceGrant` is rendered only when `routes.<key>.referenceGrant.enabled=true` and the route is in a different namespace from the Gateway.

## Dedicated Gateway Example

Use `dedicated` mode when this chart should create the Gateway and its AWS load balancer configuration.

```yaml
global:
  gatewayClassName: alb
  defaultTargetType: ip

gateways:
  edge:
    enabled: true
    mode: dedicated
    name: edge-gateway
    namespace: gateway-system
    sectionName: https
    listeners:
      - name: https
        protocol: HTTPS
        port: 443
        hostname: app.example.org
        certificateArn: arn:aws:acm:us-east-1:111122223333:certificate/replace-me
        allowedRoutes:
          namespaces:
            from: Same
    loadBalancer:
      scheme: internet-facing
      ipAddressType: ipv4
      tags:
        Environment: example
        ManagedBy: helm
      loadBalancerAttributes:
        - key: deletion_protection.enabled
          value: "true"
    defaultTargetGroup:
      enabled: true
      targetType: ip
      protocol: HTTP
      protocolVersion: HTTP1
      healthCheck:
        path: /healthz
        protocol: HTTP
        port: traffic-port
        matcher:
          httpCode: "200"

routes:
  example-app:
    enabled: true
    gateway: edge
    namespace: gateway-system
    name: example-app
    hostnames:
      - app.example.org
    rules:
      - matches:
          - path:
              type: PathPrefix
              value: /
        backendRefs:
          - name: example-app
            port: 80
    targetGroup:
      enabled: false
```

When `listeners[].certificateArn` is set, the chart adds a matching `listenerConfigurations[].defaultCertificate` entry to the `LoadBalancerConfiguration`. You can also provide Gateway API TLS settings directly with `listeners[].tls` or `listeners[].certificateRefs`.

## Rendered Resources

Shared Gateway mode renders:

- Enabled `HTTPRoute` resources.
- Service-level `TargetGroupConfiguration` resources when `routes.<key>.targetGroup.enabled=true`.
- `ReferenceGrant` resources when explicitly enabled for cross-namespace route attachment.

Shared Gateway mode does not render a `Gateway`.

Dedicated Gateway mode renders:

- `Gateway`.
- `LoadBalancerConfiguration` when load balancer settings are set or default target group configuration is enabled.
- Default `TargetGroupConfiguration` when `gateways.<key>.defaultTargetGroup.enabled=true`.
- Enabled `HTTPRoute` resources.
- Service-level `TargetGroupConfiguration` resources when enabled.
- `ReferenceGrant` resources when explicitly enabled for cross-namespace route attachment.

## Naming

Default names are generated as follows:

| Resource | Default name |
| --- | --- |
| Gateway | `gateways.<key>.name`, or `<key>` |
| LoadBalancerConfiguration | `<gateway-name>-lbcfg` |
| Default TargetGroupConfiguration | `<gateway-name>-default-tgc` |
| HTTPRoute | `routes.<key>.name`, or `<key>` |
| Route TargetGroupConfiguration | `<route-name>-tgc` |
| ReferenceGrant | `<route-name>-allow-<gateway-key>` |

All generated names are truncated to 63 characters.

## Configuration

### Global Values

| Value | Description | Default |
| --- | --- | --- |
| `global.gatewayClassName` | Default GatewayClass for dedicated Gateways. | `alb` |
| `global.defaultTargetType` | Default target type for target group configuration. Valid values are `ip` and `instance`. | `ip` |
| `global.labels` | Labels added to chart-managed resources. | `{}` |
| `global.annotations` | Annotations added to chart-managed resources. | `{}` |

### Gateway Values

| Value | Description |
| --- | --- |
| `gateways.<key>.enabled` | Enables or disables the Gateway definition. |
| `gateways.<key>.mode` | Gateway mode. Valid values are `shared` and `dedicated`. |
| `gateways.<key>.name` | Gateway name. Required for `shared`; optional for `dedicated`. |
| `gateways.<key>.namespace` | Namespace for the Gateway and Gateway-level AWS resources. |
| `gateways.<key>.gatewayClassName` | GatewayClass override for a dedicated Gateway. |
| `gateways.<key>.sectionName` | Default listener section name used by routes. |
| `gateways.<key>.listeners` | Gateway listeners. Required for `dedicated`. Supports `HTTP` and `HTTPS`. |
| `gateways.<key>.loadBalancer` | AWS `LoadBalancerConfiguration` settings. |
| `gateways.<key>.defaultTargetGroup` | Default AWS `TargetGroupConfiguration` referenced by the load balancer configuration. |

Common `loadBalancer` fields:

| Value | Description |
| --- | --- |
| `loadBalancer.loadBalancerName` | AWS load balancer name. |
| `loadBalancer.scheme` | ALB scheme, for example `internet-facing` or `internal`. |
| `loadBalancer.ipAddressType` | IP address type, for example `ipv4` or `dualstack`. |
| `loadBalancer.securityGroups` | Security groups for the load balancer. |
| `loadBalancer.subnets` | Subnet identifiers. Rendered as `loadBalancerSubnets`. |
| `loadBalancer.loadBalancerSubnets` | Full load balancer subnet entries. |
| `loadBalancer.loadBalancerSubnetsSelector` | Selector for load balancer subnets. |
| `loadBalancer.tags` | AWS tags. |
| `loadBalancer.wafV2` | WAFv2 configuration. |
| `loadBalancer.shield` | Shield configuration. |
| `loadBalancer.loadBalancerAttributes` | ALB attributes. |
| `loadBalancer.listenerConfigurations` | Listener configuration entries. |
| `loadBalancer.minimumLoadBalancerCapacity` | Minimum load balancer capacity settings. |
| `loadBalancer.mergingMode` | Configuration merging mode. |

### Route Values

| Value | Description |
| --- | --- |
| `routes.<key>.enabled` | Enables or disables the route. |
| `routes.<key>.gateway` | Gateway key to attach the route to. |
| `routes.<key>.namespace` | Namespace for the `HTTPRoute` and route-level target group configuration. |
| `routes.<key>.name` | HTTPRoute name. Defaults to the route key. |
| `routes.<key>.hostnames` | `HTTPRoute.spec.hostnames`. |
| `routes.<key>.parentRefs.refs` | Full override for `HTTPRoute.spec.parentRefs`. |
| `routes.<key>.parentRefs.sectionName` | Listener section override for the default parent reference. |
| `routes.<key>.rules` | Raw Gateway API `HTTPRoute.spec.rules`. Each rule must include at least one backend reference. |
| `routes.<key>.targetGroup` | Optional service-level `TargetGroupConfiguration`. |
| `routes.<key>.referenceGrant` | Optional `ReferenceGrant` configuration for cross-namespace attachment. |

## TargetGroupConfiguration

`gateways.<key>.defaultTargetGroup` and `routes.<key>.targetGroup` share the same configuration shape.

```yaml
targetGroup:
  enabled: true
  targetType: ip
  targetGroupName: optional-target-group-name
  protocol: HTTP
  protocolVersion: HTTP1
  ipAddressType: ipv4
  enableMultiCluster: false
  targetControlPort: 8080
  targetGroupAttributes:
    - key: deregistration_delay.timeout_seconds
      value: "30"
  tags:
    ManagedBy: helm
  nodeSelector:
    matchLabels:
      nodepool: example
  targetReference:
    kind: Service
    name: example-app
  healthCheck:
    path: /healthz
    protocol: HTTP
    port: traffic-port
    interval: 15
    timeout: 5
    healthyThresholdCount: 2
    unhealthyThresholdCount: 2
    matcher:
      httpCode: "200"
```

Short health check fields are converted to AWS Load Balancer Controller field names:

| Input field | Rendered field |
| --- | --- |
| `path` | `healthCheckPath` |
| `port` | `healthCheckPort` |
| `protocol` | `healthCheckProtocol` |
| `interval` | `healthCheckInterval` |
| `timeout` | `healthCheckTimeout` |

If `routes.<key>.targetGroup.targetReference.name` is omitted, the chart uses the first backend reference name from the first route rule.

Example target type override:

```yaml
routes:
  example-app:
    enabled: true
    gateway: shared
    namespace: example-app
    rules:
      - backendRefs:
          - name: example-app
            port: 80
    targetGroup:
      enabled: true
      targetType: instance
      nodeSelector:
        matchLabels:
          nodepool: example
```

## Migration From Ingress

Common mapping from Ingress to Gateway API:

| Ingress / ALB annotation concept | Gateway API / AWS LBC Gateway resource |
| --- | --- |
| `Ingress.spec.rules[].host` | `HTTPRoute.spec.hostnames` |
| Ingress path rules | `HTTPRoute.spec.rules[].matches` |
| Backend service | `HTTPRoute.spec.rules[].backendRefs` |
| ALB scheme, subnets, security groups, WAF, Shield, listener certificates, and ALB attributes | `LoadBalancerConfiguration` |
| Target type, health checks, target group attributes, and target group tags | `TargetGroupConfiguration` |

Use one Gateway for one ALB boundary. Use shared Gateways when several routes can share the same ALB. Use dedicated Gateways when an entry point needs separate ownership, policy, scaling, or lifecycle.

## Validation Rules

The chart validates the most important inputs during rendering:

- `global.defaultTargetType` must be `ip` or `instance`.
- Enabled gateways must set `mode`.
- Shared gateways must set `name` and `namespace`.
- Dedicated gateways must set `namespace` and at least one listener.
- Listener protocol must be `HTTP` or `HTTPS`.
- Enabled routes must set `gateway`, `namespace`, and `rules`.
- Route rules must include at least one backend reference.
- Target group `targetType`, when set, must be `ip` or `instance`.

## Troubleshooting

### HTTPRoute is not accepted

Run:

```sh
kubectl describe httproute -n <namespace> <name>
```

Check:

- `routes.<key>.gateway` points to an enabled gateway key.
- `sectionName` matches an existing listener on the Gateway.
- Cross-namespace route attachment is allowed by the Gateway listener.
- `ReferenceGrant` is enabled if your cluster policy requires it.

### Gateway is not programmed

Run:

```sh
kubectl describe gateway -n <namespace> <name>
```

Check:

- AWS Load Balancer Controller is running with Gateway API support.
- The referenced `GatewayClass` exists.
- Subnets, security groups, certificates, WAF, Shield, and IAM permissions are valid.
- The `LoadBalancerConfiguration` exists when the Gateway references it.

### Target group uses the wrong target type

Check:

- The rendered `TargetGroupConfiguration.spec.defaultConfiguration.targetType`.
- `global.defaultTargetType`.
- Any per-target-group `targetType` override.
- Other controller-level or GatewayClass-level defaults.

### Health checks fail

Check:

- `healthCheck.path` points to an endpoint served by the backend.
- `healthCheck.port` matches the port that serves the health check.
- The backend accepts the configured health check protocol.
- `matcher.httpCode` matches the response returned by the backend.
