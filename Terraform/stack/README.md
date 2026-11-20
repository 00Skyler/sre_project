# ☸️ Terraform Stack - Infrastructure & Observability

This directory contains the Terraform Infrastructure as Code (IaC) configuration for provisioning the Kubernetes cluster namespaces and core observability stack via Helm charts.

## 📦 Provisioned Resources

| File | Terraform Resource | Description |
| :--- | :--- | :--- |
| [`required_providers.tf`](required_providers.tf:1) | `provider "kubernetes"`, `provider "helm"` | Configures K8s and Helm providers to target Minikube context (`~/.kube/config`). |
| [`namespaces.tf`](namespaces.tf:1) | `kubernetes_namespace_v1` | Creates isolated namespaces: `application` and `monitoring`. |
| [`variables.tf`](variables.tf:1) | Terraform Variables | Schema definitions for email destination and SMTP authentication settings. |
| [`terraform.tfvars.example`](terraform.tfvars.example:1) | Config Template | Example configuration template for Gmail and Outlook SMTP credentials. |
| [`prometheus.tf`](prometheus.tf:1) | `helm_release.prometheus` | Deploys Prometheus Server and Alertmanager with Golden Signals alerting rules, email routing, and Pod SD targeting `sre-project-app`. |
| [`grafana.tf`](grafana.tf:1) | `helm_release.grafana` | Deploys Grafana server into the `monitoring` namespace. |
| [`Configmaps/`](Configmaps/) | Dashboard, Scrape & Alert Configs | Golden Signals dashboard JSON, Prometheus scrape configs, and Alertmanager routing definitions. |

## 📧 Email Alerts Configuration

To route alerts to your email address:
1. Copy the example configuration:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
2. Open `terraform.tfvars` and fill in your destination email and SMTP credentials (e.g. Gmail App Password).

## 🚀 Execution

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

For complete instructions and verification, refer to the [Root README.md](../../README.md).
