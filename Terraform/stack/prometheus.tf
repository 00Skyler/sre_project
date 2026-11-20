resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"

  namespace = kubernetes_namespace_v1.monitoring.metadata[0].name

  values = [
    yamlencode({
      alertmanager = {
        enabled = true
        config = {
          global = {
            resolve_timeout    = "5m"
            smtp_smarthost     = var.smtp_smarthost
            smtp_from          = var.smtp_from
            smtp_auth_username = var.smtp_auth_username
            smtp_auth_password = var.smtp_auth_password
            smtp_require_tls   = true
          }
          route = {
            group_by        = ["alertname", "namespace", "job"]
            group_wait      = "10s"
            group_interval  = "30s"
            repeat_interval = "1h"
            receiver        = "sre-email-receiver"
            routes = [
              {
                match = {
                  severity = "critical"
                }
                receiver = "sre-email-receiver"
                continue = true
              }
            ]
          }
          receivers = [
            {
              name = "sre-email-receiver"
              email_configs = [
                {
                  to            = var.alert_email_to
                  send_resolved = true
                  headers = {
                    Subject = "[ALERT {{ .Status | toUpper }}] {{ .CommonLabels.alertname }} ({{ .CommonLabels.severity }})"
                  }
                }
              ]
            }
          ]
          inhibit_rules = [
            {
              source_match = {
                severity = "critical"
              }
              target_match = {
                severity = "warning"
              }
              equal = ["alertname", "namespace"]
            }
          ]
        }
      }

      alertmanagerFiles = {
        "alertmanager.yml" = {
          global = {
            resolve_timeout    = "5m"
            smtp_smarthost     = var.smtp_smarthost
            smtp_from          = var.smtp_from
            smtp_auth_username = var.smtp_auth_username
            smtp_auth_password = var.smtp_auth_password
            smtp_require_tls   = true
          }
          route = {
            group_by        = ["alertname", "namespace", "job"]
            group_wait      = "10s"
            group_interval  = "30s"
            repeat_interval = "1h"
            receiver        = "sre-email-receiver"
            routes = [
              {
                match = {
                  severity = "critical"
                }
                receiver = "sre-email-receiver"
                continue = true
              }
            ]
          }
          receivers = [
            {
              name = "sre-email-receiver"
              email_configs = [
                {
                  to            = var.alert_email_to
                  send_resolved = true
                  headers = {
                    Subject = "[ALERT {{ .Status | toUpper }}] {{ .CommonLabels.alertname }} ({{ .CommonLabels.severity }})"
                  }
                }
              ]
            }
          ]
          inhibit_rules = [
            {
              source_match = {
                severity = "critical"
              }
              target_match = {
                severity = "warning"
              }
              equal = ["alertname", "namespace"]
            }
          ]
        }
      }

      serverFiles = {
        "alerting_rules.yml" = {
          groups = [
            {
              name = "sre_golden_signals_alerts"
              rules = [
                {
                  alert = "HighErrorRate5xx"
                  expr  = "100 * sum(rate(flask_http_request_total{job=\"sre-project-app\",status=~\"5..\"}[5m])) / sum(rate(flask_http_request_total{job=\"sre-project-app\"}[5m])) > 10"
                  for   = "1m"
                  labels = {
                    severity = "critical"
                    team     = "sre-team"
                  }
                  annotations = {
                    summary     = "High HTTP 5xx error rate on sre-project-app"
                    description = "HTTP 5xx error rate exceeds 10% (current: {{ $value | printf \"%.2f\" }}%)."
                    runbook_url = "https://github.com/00Skyler/sre_project#troubleshooting--verification-commands"
                  }
                },
                {
                  alert = "HighHttpLatency"
                  expr  = "(sum(rate(flask_http_request_duration_seconds_sum{job=\"sre-project-app\"}[5m])) / sum(rate(flask_http_request_duration_seconds_count{job=\"sre-project-app\"}[5m]))) > 0.5"
                  for   = "1m"
                  labels = {
                    severity = "warning"
                    team     = "sre-team"
                  }
                  annotations = {
                    summary     = "High HTTP average latency detected"
                    description = "Average latency is above 0.5s (current: {{ $value | printf \"%.3f\" }}s)."
                    runbook_url = "https://github.com/00Skyler/sre_project#troubleshooting--verification-commands"
                  }
                },
                {
                  alert = "AppInstanceDown"
                  expr  = "up{job=\"sre-project-app\"} == 0"
                  for   = "1m"
                  labels = {
                    severity = "critical"
                    team     = "sre-team"
                  }
                  annotations = {
                    summary     = "Instance of sre-project-app is down"
                    description = "Prometheus cannot scrape target instance: {{ $labels.instance }}."
                  }
                },
                {
                  alert = "PodMemorySaturation"
                  expr  = "container_memory_working_set_bytes{namespace=\"application\",pod=~\"sre-project-app-.*\"} > 200000000"
                  for   = "2m"
                  labels = {
                    severity = "warning"
                    team     = "sre-team"
                  }
                  annotations = {
                    summary     = "Application pod memory saturation warning"
                    description = "Pod {{ $labels.pod }} memory usage is above 200MB."
                  }
                }
              ]
            }
          ]
        }
      }

      extraScrapeConfigs = <<-EOT
      - job_name: 'sre-project-app'
        scrape_interval: 15s
        metrics_path: /metrics

        kubernetes_sd_configs:
          - role: pod
            namespaces:
              names:
                - application

        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_label_app]
            regex: sre-project-app
            action: keep

          - source_labels: [__meta_kubernetes_pod_phase]
            regex: Running
            action: keep

          - source_labels: [__meta_kubernetes_pod_ip]
            target_label: __address__
            replacement: '$1:5000'

          - source_labels: [__meta_kubernetes_pod_name]
            target_label: pod
    EOT
    })
  ]
}
