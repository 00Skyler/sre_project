resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"

  namespace = kubernetes_namespace_v1.monitoring.metadata[0].name

  values = [
    yamlencode({
      extraScrapeConfigs = <<-EOT
        - job_name: 'sre-project-app'
          scrape_interval: 15s
          metrics_path: /metrics

          static_configs:
            - targets:
                - 'sre-project-app.application.svc.cluster.local:5000'
      EOT
    })
  ]
}
