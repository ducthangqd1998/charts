{{/*
Expand the name of the chart.
*/}}
{{- define "crw.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "crw.fullname" -}}
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
{{- define "crw.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "crw.selectorLabels" -}}
app.kubernetes.io/name: {{ include "crw.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "crw.baseLabels" -}}
helm.sh/chart: {{ include "crw.chart" . }}
{{ include "crw.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "crw.labels" -}}
{{- $base := include "crw.baseLabels" . | fromYaml -}}
{{- $merged := mergeOverwrite (dict) (.Values.commonLabels | default dict) $base -}}
{{ toYaml $merged }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "crw.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "crw.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the SearXNG search backend URL when search is enabled.
*/}}
{{- define "crw.searchBackendUrl" -}}
{{- if .Values.search.enabled -}}
{{- if .Values.search.backendUrl -}}
{{- .Values.search.backendUrl -}}
{{- else -}}
{{- $searxng := index .Values "searxng" | default dict -}}
{{- if $searxng.enabled -}}
{{- $name := "" -}}
{{- if $searxng.fullnameOverride -}}
{{- $name = $searxng.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $subName := default "searxng" $searxng.nameOverride -}}
{{- if contains $subName .Release.Name -}}
{{- $name = .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name = printf "%s-%s" .Release.Name $subName | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- $svc := $searxng.service | default dict -}}
{{- $port := default 8080 $svc.port -}}
{{- printf "http://%s:%d" $name (int $port) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end }}
