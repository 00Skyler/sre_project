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
