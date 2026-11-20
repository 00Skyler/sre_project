# ☸️ Terraform Stack - Infrastructure & Observability

This directory contains the Terraform Infrastructure as Code (IaC) configuration for provisioning the Kubernetes cluster namespaces and core observability stack via Helm charts.

## 📦 Provisioned Resources

| File | Terraform Resource | Description |
| :--- | :--- | :--- |
| [`required_providers.tf`](required_providers.tf:1) | `provider "kubernetes"`, `provider "helm"` | Configures K8s and Helm providers to target Minikube context (`~/.kube/config`). |
| [`namespaces.tf`](namespaces.tf:1) | `kubernetes_namespace_v1` | Creates isolated namespaces: `application` and `monitoring`. |
| [`prometheus.tf`](prometheus.tf:1) | `helm_release.prometheus` | Deploys Prometheus Server with Pod Service Discovery targeting `sre-project-app`. |
| [`grafana.tf`](grafana.tf:1) | `helm_release.grafana` | Deploys Grafana server into the `monitoring` namespace. |
| [`Configmaps/`](Configmaps/) | Dashboard & Scrape Configs | Golden Signals dashboard JSON and Prometheus Server scrape configurations. |

## 🚀 Execution

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

For complete instructions and verification, refer to the [Root README.md](../../README.md).
