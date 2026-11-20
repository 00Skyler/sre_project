resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"

  namespace = kubernetes_namespace_v1.monitoring.metadata[0].name

  values = [
    yamlencode({
      datasources = {
        "datasources.yaml" = {
          apiVersion = 1
          datasources = [
            {
              name      = "Prometheus"
              type      = "prometheus"
              url       = "http://prometheus-server.monitoring.svc.cluster.local:80"
              access    = "proxy"
              isDefault = true
              editable  = true
              jsonData = {
                timeInterval = "15s"
              }
            }
          ]
        }
      }
    })
  ]
}
