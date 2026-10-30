provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

resource "kubernetes_namespace_v1" "k8s" {
  metadata {
    name = "k8s"
  }
}


