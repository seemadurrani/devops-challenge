{{- define "nginx-web.name" -}}
nginx-web
{{- end }}

{{- define "nginx-web.fullname" -}}
{{ printf "%s-%s" .Release.Name "nginx" }}
{{- end }}

