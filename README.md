# 🚀 SRE Infrastructure as Code & Observability Platform

An end-to-end Site Reliability Engineering (SRE) project demonstrating **Infrastructure as Code (IaC)**, **Microservices Instrumentation**, and **Cloud-Native Observability**. This project provisions a resilient multi-namespace Kubernetes environment on Minikube, deploys an instrumented Python Flask microservice, and configures an observability stack featuring **Prometheus**, **Grafana**, and **OpenTelemetry (OTel) Collector** with automated Golden Signals dashboards and alerting rules.

---

## 📑 Table of Contents

- [Architecture Overview](#-architecture-overview)
- [Repository Structure](#-repository-structure)
- [Component Breakdown](#-component-breakdown)
  - [1. Infrastructure Layer (Terraform & Kubernetes)](#1-infrastructure-layer-terraform--kubernetes)
  - [2. Observability & Monitoring Stack](#2-observability--monitoring-stack)
  - [3. Application Layer](#3-application-layer)
  - [4. Traffic Simulation & Reliability Testing](#4-traffic-simulation--reliability-testing)
  - [5. CI/CD Automation](#5-cicd-automation)
- [SRE Principles & The Four Golden Signals](#-sre-principles--the-four-golden-signals)
- [Prerequisites](#-prerequisites)
- [Deployment Guide](#-deployment-guide)
  - [Step 1: Start Kubernetes Cluster](#step-1-start-kubernetes-cluster)
  - [Step 2: Deploy Infrastructure via Terraform](#step-2-deploy-infrastructure-via-terraform)
  - [Step 3: Deploy Application Microservice](#step-3-deploy-application-microservice)
  - [Step 4: Provision Grafana Dashboards & Alerts](#step-4-provision-grafana-dashboards--alerts)
- [Operational Runbook & Access](#-operational-runbook--access)
  - [Accessing Grafana](#accessing-grafana)
  - [Accessing Prometheus](#accessing-prometheus)
  - [Accessing Application & Metrics](#accessing-application--metrics)
- [Generating Traffic & Simulating Incidents](#-generating-traffic--simulating-incidents)
- [SRE Evaluation & Evidence Checklist (Screenshots)](#-sre-evaluation--evidence-checklist-screenshots)
- [Troubleshooting & Verification Commands](#-troubleshooting--verification-commands)

---

## 🏛 Architecture Overview

<p align="center">
  <img width="1315" height="552" alt="SRE Architecture Overview" src="https://github.com/user-attachments/assets/cf7890bd-2e1b-44c8-ae15-166334fc0357" />
</p>

### System Topology & Metric Flow

```mermaid
graph TD
    subgraph "traffic_gen [Traffic Generator]"
        script["scripts/traffic-test.sh"]
    end

    subgraph "k8s_app [Namespace: application]"
        svc["Service: sre-project-app (Port 5000)"]
        pod1["Pod 1: sre-project-app"]
        pod2["Pod 2: sre-project-app"]
        pod3["Pod 3: sre-project-app"]
        svc --> pod1 & pod2 & pod3
    end

    subgraph "k8s_metrics [Namespace: metrics]"
        otel["OpenTelemetry Collector Deployment"]
    end

    subgraph "k8s_monitoring [Namespace: monitoring]"
        prom["Prometheus Server (Port 9090)"]
        grafana["Grafana Server (Port 3000)"]
        prom_cm["ConfigMap: Scrape Configs"]
        grafana_cm["ConfigMap: Dashboards, Datasources & Alerts"]
        prom_cm --> prom
        grafana_cm --> grafana
        prom -->|PromQL Datasource| grafana
    end

    script -->|HTTP /store (200 OK) & /error (500 ERR)| svc
    prom -->|Scrapes /metrics via Pod SD (15s)| pod1 & pod2 & pod3
    otel -->|Telemetry Pipeline| prom
```

---

## 📂 Repository Structure

```text
.
├── .github/
│   └── workflows/
│       └── actions.yml                 # CI workflow for pull requests and main branch builds
├── Docs/
│   └── README.md                       # Initial environment setup notes & provider reference
├── scripts/
│   └── traffic-test.sh                 # Automated load and HTTP 500 error chaos generator
├── Terraform/
│   ├── App/
│   │   ├── app.py                      # Flask REST API instrumented with prometheus-flask-exporter
│   │   ├── Dockerfile                  # Non-root, multi-stage Python 3.13-slim container
│   │   ├── requirements.txt            # Application dependencies (Flask, Gunicorn, Prometheus exporter)
│   │   ├── deployment.yaml             # Kubernetes Deployment (3 replicas) and ClusterIP Service
│   │   └── README.md                   # App documentation
│   └── stack/
│       ├── required_providers.tf       # Terraform provider definitions (Kubernetes & Helm)
│       ├── namespaces.tf               # Isolated namespaces: 'application', 'monitoring', 'metrics'
│       ├── prometheus.tf               # Prometheus Helm release with custom Pod SD relabeling
│       ├── grafana.tf                  # Grafana Helm release deployed into monitoring namespace
│       ├── otel.tf                     # OpenTelemetry Collector Helm release in metrics namespace
│       ├── Configmaps/
│       │   ├── dashboard-golden-signals.yaml   # Grafana Deployment, Datasources, Golden Signals & Alerts
│       │   ├── prometheus-config.yaml          # Standalone Prometheus server configuration
│       │   └── configmap-prometheus-server.yaml# Prometheus ConfigMap backup & reference
│       └── README.md                   # Stack documentation
├── notes.txt                           # Handy operational commands and credential extraction snippets
└── README.md                           # Master SRE Project Documentation
```

---

## 🔍 Component Breakdown

### 1. Infrastructure Layer (Terraform & Kubernetes)
- **`Terraform/stack/required_providers.tf`**: Configures the HashiCorp `kubernetes` (v3.5.0+) and `helm` (v3.3.0+) providers targeting the local Minikube cluster via `~/.kube/config`.
- **`Terraform/stack/namespaces.tf`**: Segregates concerns into three dedicated namespaces:
  - `application`: Houses the business microservices and service endpoints.
  - `monitoring`: Contains Prometheus Server, Alertmanager, and Grafana.
  - `metrics`: Houses the OpenTelemetry Collector Daemon/Deployment.

### 2. Observability & Monitoring Stack
- **`Terraform/stack/prometheus.tf`**:
  - Deploys Prometheus via the official Helm chart (`prometheus-community/prometheus`).
  - Configures an `extraScrapeConfigs` job (`sre-project-app`) that leverages **Kubernetes Pod Service Discovery** (`kubernetes_sd_configs`), dynamically discovering all pods matching label `app: sre-project-app` running in the `application` namespace and scraping them every 15s at `/metrics`.
- **`Terraform/stack/otel.tf`**:
  - Deploys OpenTelemetry Collector (`otel/opentelemetry-collector-k8s`) in `deployment` mode inside the `metrics` namespace to collect, process, and forward distributed traces and span metrics.
- **`Terraform/stack/Configmaps/dashboard-golden-signals.yaml`**:
  - Provisions Grafana with declarative datasources (Prometheus and Loki).
  - Deploys pre-built dashboards:
    - **Example Dashboard**: Core system metrics and CPU utilization per pod.
    - **Golden Signals Dashboard**: Real-time graphs covering **Latency**, **Traffic (Rx/Tx bytes)**, **Errors (HTTP 500 & container scrape failures)**, and **Saturation (CPU & Filesystem writes)**.
  - Provisions automated alert rules evaluating latency thresholds (>1400ms), network saturation, and error count thresholds.

### 3. Application Layer
- **`Terraform/App/app.py`**:
  - Lightweight Flask microservice.
  - Endpoints:
    - `GET /`: Health check / Root endpoint (`Hello, World!`).
    - `GET /store`: Product catalog retrieval endpoint (simulates regular 200 OK traffic).
    - `GET /error`: Fault simulation endpoint (returns HTTP 500 `Simulated server error` for error-rate and alerting tests).
    - `GET /metrics`: Standard Prometheus metrics endpoint automatically instrumented via `PrometheusMetrics(app)`.
- **`Terraform/App/Dockerfile`**:
  - Built on `python:3.13-slim` with a dedicated non-root user (`appuser`) for security compliance.
  - Served via production-grade WSGI server `gunicorn` on port 5000.
- **`Terraform/App/deployment.yaml`**:
  - Kubernetes Deployment managing **3 replicas** for high availability and load distribution.
  - Exposes port 5000 via a ClusterIP service named `sre-project-app`.

### 4. Traffic Simulation & Reliability Testing
- **`scripts/traffic-test.sh`**:
  - An automated SRE load generation tool.
  - In each iteration:
    - Sends 20 continuous requests to `/store` (generating baseline traffic & latency data).
    - Injects a randomized burst of 1–10 requests to `/error` (generating HTTP 500 fault spikes).
    - Pauses for 5 seconds and repeats indefinitely to populate Prometheus timeseries data and trigger alert thresholds.

### 5. CI/CD Automation
- **`.github/workflows/actions.yml`**:
  - Automated GitHub Actions pipeline triggered on `push` and `pull_request` to the `main` branch to validate changes.

---

## 📊 SRE Principles & The Four Golden Signals

This architecture is built around Google SRE's **Four Golden Signals**:

| Golden Signal | Metric / Source | PromQL / LogQL Query | Observability Goal |
| :--- | :--- | :--- | :--- |
| **Latency** | OTel Span Metrics / Request duration | `sum(rate(otel_collector_span_metrics_duration_milliseconds_bucket[5m])) by (span_name)` | Ensure endpoint response time stays below acceptable SLAs (alert threshold > 1400ms). |
| **Traffic** | Container Network Interfaces | `sum(rate(container_network_receive_bytes_total[5m])) by (container_label_k8s_app)` | Measure demand and throughput across active microservices. |
| **Errors** | HTTP 500 status codes & Application logs | `flask_http_request_total{status="500"}` / `{service_name="unknown_service"} \|= "err"` | Track rate of failed requests vs. total throughput (error budget consumption). |
| **Saturation** | Container CPU & Filesystem writes | `sum(rate(container_cpu_system_seconds_total[5m])) by (container_label_io_kubernetes_container_name)` | Detect resource constraints before performance degradation occurs. |

---

## ⚙️ Prerequisites

Before launching the project, ensure you have the following installed on your host:

- [Minikube](https://minikube.sigs.k8s.io/docs/start/) (`v1.30+`)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (`v1.28+`)
- [Terraform](https://developer.hashicorp.com/terraform/downloads) (`v1.5.0+`)
- [Helm](https://helm.sh/docs/intro/install/) (`v3.10+`)
- [Docker](https://docs.docker.com/get-docker/) (optional, if rebuilding app images)
- [curl](https://curl.se/) and [bash](https://www.gnu.org/software/bash/) (for load testing)

---

## 🚀 Deployment Guide

### Step 1: Start Kubernetes Cluster
```bash
# Start Minikube with sufficient resources for the observability stack
minikube start --cpus=4 --memory=8192 --driver=docker

# Verify connection
kubectl cluster-info
```

### Step 2: Deploy Infrastructure via Terraform
```bash
cd Terraform/stack

# Initialize Terraform providers (Kubernetes & Helm)
terraform init

# Validate configuration
terraform validate

# Plan the infrastructure execution
terraform plan

# Apply the stack (creates namespaces, Prometheus, Grafana, OpenTelemetry)
terraform apply -auto-approve
```

### Step 3: Deploy Application Microservice
```bash
# Deploy the Flask application (3 replicas) and ClusterIP service
kubectl apply -f ../App/deployment.yaml

# Verify all pods are in Running state
kubectl get pods -n application
kubectl get svc -n application
```

### Step 4: Provision Grafana Dashboards & Alerts
```bash
# Apply ConfigMaps for Prometheus Scrape Configs, Grafana Dashboards, and Datasources
kubectl apply -f Configmaps/dashboard-golden-signals.yaml
```

---

## 🛠 Operational Runbook & Access

### Accessing Grafana
1. **Retrieve the auto-generated admin password**:
   ```bash
   kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
   ```
2. **Port-forward the Grafana service**:
   ```bash
   export POD_NAME=$(kubectl get pods --namespace monitoring -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}")
   kubectl --namespace monitoring port-forward $POD_NAME 3000:3000
   ```
3. Open your browser at `http://localhost:3000` (User: `admin`, Password: `<retrieved_password>`).

### Accessing Prometheus
1. **Port-forward the Prometheus Server**:
   ```bash
   kubectl --namespace monitoring port-forward svc/prometheus-server 9090:80
   ```
2. Open your browser at `http://localhost:9090` and verify the `sre-project-app` target status under **Status -> Targets**.

### Accessing Application & Metrics
1. **Port-forward the microservice**:
   ```bash
   kubectl --namespace application port-forward svc/sre-project-app 5000:5000
   ```
2. **Test Endpoints**:
   ```bash
   # Test Home
   curl http://localhost:5000/
   
   # Test Store Catalog
   curl http://localhost:5000/store
   
   # Test Error Endpoint
   curl -i http://localhost:5000/error
   
   # View Raw Prometheus Metrics
   curl http://localhost:5000/metrics
   ```

---

## ⚡ Generating Traffic & Simulating Incidents

To simulate real-world production load, generate metric activity, and test alert triggers:

1. Ensure the application is port-forwarded on port `5000`:
   ```bash
   kubectl --namespace application port-forward svc/sre-project-app 5000:5000
   ```
2. Open a new terminal and run the traffic generation script:
   ```bash
   chmod +x scripts/traffic-test.sh
   ./scripts/traffic-test.sh
   ```
3. Observe live metrics changing in Grafana dashboards and Prometheus targets.

---

## 📸 SRE Evaluation & Evidence Checklist (Screenshots)

Use this section to attach screenshot evidence demonstrating that each component of the infrastructure, application, and observability pipeline is functioning as expected.

---

### Evidence 1: Terraform Infrastructure Deployment
> **What to capture:** Terminal output showing `terraform apply` completed successfully with all resources created (`kubernetes_namespace_v1`, `helm_release.prometheus`, `helm_release.grafana`, `helm_release.opentelemetry`).

```markdown
<!-- PASTE SCREENSHOT HERE: Terraform Apply Output -->
![Terraform Apply Evidence](docs/screenshots/01-terraform-apply.png)
```

---

### Evidence 2: Kubernetes Cluster & Pod Status
> **What to capture:** Terminal output of `kubectl get all --all-namespaces` or individual namespaces (`application`, `monitoring`, `metrics`) showing all Pods in `Running` state and Services active.

```markdown
<!-- PASTE SCREENSHOT HERE: Kubectl Pods & Services -->
![Kubernetes Pod Status](docs/screenshots/02-k8s-pod-status.png)
```

---

### Evidence 3: Prometheus Target Discovery & Scrape Status
> **What to capture:** Prometheus UI (`http://localhost:9090/targets`) showing the `sre-project-app` scrape job in the `UP (3/3)` state, confirming Kubernetes Pod Service Discovery.

```markdown
<!-- PASTE SCREENSHOT HERE: Prometheus Targets UP -->
![Prometheus Targets Status](docs/screenshots/03-prometheus-targets.png)
```

---

### Evidence 4: Application Endpoints & `/metrics` Output
> **What to capture:** Terminal or browser showing responses from `http://localhost:5000/store`, `http://localhost:5000/error` (HTTP 500), and the raw Prometheus metrics at `http://localhost:5000/metrics`.

```markdown
<!-- PASTE SCREENSHOT HERE: App Endpoints and /metrics -->
![Application Metrics Output](docs/screenshots/04-app-metrics.png)
```

---

### Evidence 5: Traffic Generator in Execution
> **What to capture:** Active terminal running `scripts/traffic-test.sh`, displaying successful batch loops and simulated HTTP 500 errors.

```markdown
<!-- PASTE SCREENSHOT HERE: Traffic Test Script -->
![Traffic Generator Execution](docs/screenshots/05-traffic-generator.png)
```

---

### Evidence 6: Grafana Golden Signals Dashboard
> **What to capture:** Grafana UI showing the **Golden Signals Dashboard** with populated timeseries data for Latency, Traffic (Rx/Tx bytes), Error rates, and CPU/Filesystem Saturation.

```markdown
<!-- PASTE SCREENSHOT HERE: Grafana Golden Signals Dashboard -->
![Grafana Golden Signals](docs/screenshots/06-grafana-golden-signals.png)
```

---

### Evidence 7: Grafana Alert Rules & Incident Triggering
> **What to capture:** Grafana Alerting panel (`/alerting/list`) showing the configured alerting rules (e.g. Latency thresholds, Error rate thresholds) transitioning to `Firing` or `Normal`.

```markdown
<!-- PASTE SCREENSHOT HERE: Grafana Alert Rules Status -->
![Grafana Alert Rules](docs/screenshots/07-grafana-alerts.png)
```

---

## 🔧 Troubleshooting & Verification Commands

```bash
# Check status of Helm releases across all namespaces
helm list -A

# Inspect Prometheus configuration loaded in pod
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus -c prometheus-server --tail=50

# Inspect OpenTelemetry Collector logs
kubectl logs -n metrics -l app.kubernetes.io/name=opentelemetry-collector --tail=50

# Verify scrape target network connectivity from within cluster
kubectl run curl-test --rm -it --image=curlimages/curl --restart=Never -- curl http://sre-project-app.application.svc.cluster.local:5000/metrics

# Extract Helm-generated manifests for debugging
helm get manifest my-opentelemetry-collector -n metrics
helm get manifest prometheus -n monitoring
helm get manifest grafana -n monitoring
```

---

## 👥 Contributors & SRE Evaluation Notes

- **Project:** SRE Infrastructure as Code & Observability Platform
- **Methodology:** Infrastructure as Code (Terraform), Kubernetes Orchestration, Cloud-Native Telemetry (Prometheus & OpenTelemetry), Golden Signals Monitoring (Grafana).
- **Evaluation Criteria:** Declarative deployment, security baseline (non-root containers), fault injection readiness, automated service discovery, and metric-driven operational visibility.
