resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_namespace_v1" "metrics" {
  metadata {
    name = "metrics"
  }
}

resource "kubernetes_namespace_v1" "application" {
  metadata {
    name = "application"
  }
}