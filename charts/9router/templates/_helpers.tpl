{{/*
Expand the name of the chart.
*/}}
{{- define "9router.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "9router.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "9router.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "9router.selectorLabels" -}}
app.kubernetes.io/name: {{ include "9router.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "9router.baseLabels" -}}
helm.sh/chart: {{ include "9router.chart" . }}
{{ include "9router.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "9router.labels" -}}
{{- $base := include "9router.baseLabels" . | fromYaml -}}
{{- $merged := mergeOverwrite (dict) (.Values.commonLabels | default dict) $base -}}
{{ toYaml $merged }}
{{- end }}

{{/*
Create the name of the service account to use.
*/}}
{{- define "9router.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "9router.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the PersistentVolumeClaim to use.
*/}}
{{- define "9router.pvcName" -}}
{{- if .Values.persistence.existingClaim }}
{{- .Values.persistence.existingClaim }}
{{- else }}
{{- printf "%s-data" (include "9router.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Determine the Deployment update strategy.
Uses Recreate automatically when persistence.enabled uses ReadWriteOnce unless explicitly set.
*/}}
{{- define "9router.strategy" -}}
{{- if .Values.strategy -}}
{{ toYaml .Values.strategy }}
{{- else if and .Values.persistence.enabled (has "ReadWriteOnce" .Values.persistence.accessModes) -}}
type: Recreate
{{- else -}}
type: RollingUpdate
rollingUpdate:
  maxSurge: 1
  maxUnavailable: 0
{{- end -}}
{{- end }}
