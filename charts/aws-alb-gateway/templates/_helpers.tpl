{{/*
Common helpers for aws-alb-gateway.
*/}}

{{- define "aws-alb-gateway.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aws-alb-gateway.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := include "aws-alb-gateway.name" . -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "aws-alb-gateway.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aws-alb-gateway.baseLabels" -}}
helm.sh/chart: {{ include "aws-alb-gateway.chart" . }}
app.kubernetes.io/name: {{ include "aws-alb-gateway.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "aws-alb-gateway.labels" -}}
{{- $global := .Values.global | default dict -}}
{{- $base := include "aws-alb-gateway.baseLabels" . | fromYaml -}}
{{- $merged := mergeOverwrite (dict) ($global.labels | default dict) $base -}}
{{ toYaml $merged }}
{{- end -}}

{{- define "aws-alb-gateway.annotations" -}}
{{- $global := .Values.global | default dict -}}
{{- with $global.annotations }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{- define "aws-alb-gateway.resourceName" -}}
{{- $name := required "resource name is required" . -}}
{{- $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aws-alb-gateway.gatewayName" -}}
{{- $key := .key -}}
{{- $gateway := .gateway | default dict -}}
{{- default $key $gateway.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aws-alb-gateway.lbConfigName" -}}
{{- $gateway := .gateway | default dict -}}
{{- $lb := $gateway.loadBalancer | default dict -}}
{{- $gatewayName := include "aws-alb-gateway.gatewayName" . -}}
{{- default (printf "%s-lbcfg" $gatewayName) $lb.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aws-alb-gateway.defaultTgConfigName" -}}
{{- $gateway := .gateway | default dict -}}
{{- $defaultTg := $gateway.defaultTargetGroup | default dict -}}
{{- $gatewayName := include "aws-alb-gateway.gatewayName" . -}}
{{- default (printf "%s-default-tgc" $gatewayName) $defaultTg.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aws-alb-gateway.routeName" -}}
{{- $route := .route | default dict -}}
{{- default .key $route.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aws-alb-gateway.routeTgConfigName" -}}
{{- $route := .route | default dict -}}
{{- $tg := $route.targetGroup | default dict -}}
{{- $routeName := include "aws-alb-gateway.routeName" . -}}
{{- default (printf "%s-tgc" $routeName) $tg.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aws-alb-gateway.targetType" -}}
{{- $local := .local | default dict -}}
{{- $global := .global | default dict -}}
{{- default (default "ip" $global.defaultTargetType) $local.targetType -}}
{{- end -}}

{{- define "aws-alb-gateway.healthCheckConfig" -}}
{{- with . }}
{{- $hc := dict -}}
{{- with .healthyThresholdCount }}{{- $_ := set $hc "healthyThresholdCount" . -}}{{- end -}}
{{- with .interval }}{{- $_ := set $hc "healthCheckInterval" . -}}{{- end -}}
{{- with .healthCheckInterval }}{{- $_ := set $hc "healthCheckInterval" . -}}{{- end -}}
{{- with .path }}{{- $_ := set $hc "healthCheckPath" . -}}{{- end -}}
{{- with .healthCheckPath }}{{- $_ := set $hc "healthCheckPath" . -}}{{- end -}}
{{- with .port }}{{- $_ := set $hc "healthCheckPort" (toString .) -}}{{- end -}}
{{- with .healthCheckPort }}{{- $_ := set $hc "healthCheckPort" (toString .) -}}{{- end -}}
{{- with .protocol }}{{- $_ := set $hc "healthCheckProtocol" . -}}{{- end -}}
{{- with .healthCheckProtocol }}{{- $_ := set $hc "healthCheckProtocol" . -}}{{- end -}}
{{- with .timeout }}{{- $_ := set $hc "healthCheckTimeout" . -}}{{- end -}}
{{- with .healthCheckTimeout }}{{- $_ := set $hc "healthCheckTimeout" . -}}{{- end -}}
{{- with .unhealthyThresholdCount }}{{- $_ := set $hc "unhealthyThresholdCount" . -}}{{- end -}}
{{- with .matcher }}{{- $_ := set $hc "matcher" . -}}{{- end -}}
{{- if $hc }}
{{ toYaml $hc }}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "aws-alb-gateway.targetGroupProps" -}}
{{- $cfg := .config | default dict -}}
{{- $root := .root -}}
{{- $global := $root.Values.global | default dict -}}
{{- $props := dict -}}
{{- $_ := set $props "targetType" (include "aws-alb-gateway.targetType" (dict "local" $cfg "global" $global)) -}}
{{- with $cfg.targetGroupName }}{{- $_ := set $props "targetGroupName" . -}}{{- end -}}
{{- with $cfg.ipAddressType }}{{- $_ := set $props "ipAddressType" . -}}{{- end -}}
{{- with $cfg.protocol }}{{- $_ := set $props "protocol" . -}}{{- end -}}
{{- with $cfg.protocolVersion }}{{- $_ := set $props "protocolVersion" . -}}{{- end -}}
{{- if hasKey $cfg "enableMultiCluster" }}{{- $_ := set $props "enableMultiCluster" $cfg.enableMultiCluster -}}{{- end -}}
{{- with $cfg.targetControlPort }}{{- $_ := set $props "targetControlPort" . -}}{{- end -}}
{{- with $cfg.targetGroupAttributes }}{{- $_ := set $props "targetGroupAttributes" . -}}{{- end -}}
{{- with $cfg.tags }}{{- $_ := set $props "tags" . -}}{{- end -}}
{{- with $cfg.nodeSelector }}{{- $_ := set $props "nodeSelector" . -}}{{- end -}}
{{- with $cfg.healthCheck }}
{{- $health := include "aws-alb-gateway.healthCheckConfig" . | fromYaml -}}
{{- if $health }}{{- $_ := set $props "healthCheckConfig" $health -}}{{- end -}}
{{- end -}}
{{ toYaml $props }}
{{- end -}}

{{- define "aws-alb-gateway.validate" -}}
{{- $root := . -}}
{{- $global := .Values.global | default dict -}}
{{- $defaultTargetType := default "ip" $global.defaultTargetType -}}
{{- if not (has $defaultTargetType (list "ip" "instance")) -}}
{{- fail "global.defaultTargetType must be one of: ip, instance" -}}
{{- end -}}
{{- range $key, $gateway := .Values.gateways }}
{{- if $gateway.enabled }}
{{- $mode := required (printf "gateways.%s.mode is required" $key) $gateway.mode -}}
{{- if not (has $mode (list "shared" "dedicated")) -}}
{{- fail (printf "gateways.%s.mode must be one of: shared, dedicated" $key) -}}
{{- end -}}
{{- if eq $mode "shared" }}
{{- $_ := required (printf "gateways.%s.name is required for shared mode" $key) $gateway.name -}}
{{- $_ := required (printf "gateways.%s.namespace is required for shared mode" $key) $gateway.namespace -}}
{{- end -}}
{{- if eq $mode "dedicated" }}
{{- $_ := required (printf "gateways.%s.namespace is required for dedicated mode" $key) $gateway.namespace -}}
{{- if not $gateway.listeners }}{{- fail (printf "gateways.%s.listeners is required for dedicated mode" $key) -}}{{- end -}}
{{- range $idx, $listener := $gateway.listeners }}
{{- if not (has $listener.protocol (list "HTTP" "HTTPS")) -}}
{{- fail (printf "gateways.%s.listeners[%d].protocol must be one of: HTTP, HTTPS" $key $idx) -}}
{{- end -}}
{{- end -}}
{{- with $gateway.defaultTargetGroup }}
{{- if and .enabled .targetType (not (has .targetType (list "ip" "instance"))) -}}
{{- fail (printf "gateways.%s.defaultTargetGroup.targetType must be one of: ip, instance" $key) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- range $key, $route := .Values.routes }}
{{- if $route.enabled }}
{{- $gatewayKey := required (printf "routes.%s.gateway is required" $key) $route.gateway -}}
{{- if not (hasKey ($root.Values.gateways | default dict) $gatewayKey) -}}
{{- fail (printf "routes.%s.gateway references undefined gateway key %q" $key $gatewayKey) -}}
{{- end -}}
{{- $gateway := index $root.Values.gateways $gatewayKey -}}
{{- if not $gateway.enabled -}}{{- fail (printf "routes.%s.gateway references disabled gateway %q" $key $gatewayKey) -}}{{- end -}}
{{- $_ := required (printf "routes.%s.namespace is required" $key) $route.namespace -}}
{{- if not $route.rules }}{{- fail (printf "routes.%s.rules is required" $key) -}}{{- end -}}
{{- range $ruleIdx, $rule := $route.rules }}
{{- if and (not $rule.backendRefs) (not $rule.filters) }}{{- fail (printf "routes.%s.rules[%d] must contain backendRefs or filters" $key $ruleIdx) -}}{{- end -}}
{{- end -}}
{{- with $route.targetGroup }}
{{- if and .enabled .targetType (not (has .targetType (list "ip" "instance"))) -}}
{{- fail (printf "routes.%s.targetGroup.targetType must be one of: ip, instance" $key) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
