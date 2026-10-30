provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

resource "kubernetes_namespace_v1" "k8s" {
  metadata {
    name = "k8s"
  }
} # This block tells Terraform to communicate with Minikube using a local kubeconfig file


provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
    config_context = "minikube
  }
} # This block enables Terraform to interact with Helm to install charts into k8s

