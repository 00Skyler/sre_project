resource "helm_release" "opentelemetry" {
  name       = "my-opentelemetry-collector"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"

  namespace = kubernetes_namespace_v1.metrics.metadata[0].name

  set = [
    {
      name  = "mode"
      value = "deployment"
    },
    {
      name  = "image.repository"
      value = "otel/opentelemetry-collector-k8s"
    }
  ]
}