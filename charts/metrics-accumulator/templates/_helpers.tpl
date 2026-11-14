{{/*
Expand the name of the chart.
*/}}
{{- define "metrics-accumulator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "metrics-accumulator.fullname" -}}
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
{{- define "metrics-accumulator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "metrics-accumulator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "metrics-accumulator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "metrics-accumulator.baseLabels" -}}
helm.sh/chart: {{ include "metrics-accumulator.chart" . }}
{{ include "metrics-accumulator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "metrics-accumulator.labels" -}}
{{- $base := include "metrics-accumulator.baseLabels" . | fromYaml -}}
{{- $merged := mergeOverwrite (dict) (.Values.commonLabels | default dict) $base -}}
{{ toYaml $merged }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "metrics-accumulator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "metrics-accumulator.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the image name
*/}}
{{- define "metrics-accumulator.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.image.repository $tag }}
{{- end }}

{{/*
Return "true" when .Values.config contains non-whitespace content
*/}}
{{- define "metrics-accumulator.hasConfig" -}}
{{- if ne (trim (.Values.config | default "")) "" -}}
true
{{- end -}}
{{- end }}

{{/*
Create service monitor labels
*/}}
{{- define "metrics-accumulator.serviceMonitorLabels" -}}
{{- if .Values.serviceMonitor.labels }}
{{- toYaml .Values.serviceMonitor.labels }}
{{- end }}
{{- end }}

{{/*
Create service monitor annotations
*/}}
{{- define "metrics-accumulator.serviceMonitorAnnotations" -}}
{{- if .Values.serviceMonitor.annotations }}
{{- toYaml .Values.serviceMonitor.annotations }}
{{- end }}
{{- end }}
