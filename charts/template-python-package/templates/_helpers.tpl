{{/*
Expand the name of the chart.
*/}}
{{- define "template-python-package.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "template-python-package.fullname" -}}
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
The namespace every resource in this chart is created in.
*/}}
{{- define "template-python-package.namespace" -}}
{{- default (include "template-python-package.name" .) .Values.namespaceOverride }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "template-python-package.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "template-python-package.labels" -}}
helm.sh/chart: {{ include "template-python-package.chart" . }}
{{ include "template-python-package.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "template-python-package.selectorLabels" -}}
app.kubernetes.io/name: {{ include "template-python-package.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
