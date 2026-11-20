#!/bin/bash

# ==============================================================================
# SRE PROJECT - AUTOMATED CLUSTER LIFECYCLE MANAGEMENT SCRIPT
# ==============================================================================
# Usage:
#   ./scripts/cluster.sh up       # Full cluster creation & end-to-end deployment
#   ./scripts/cluster.sh down     # Teardown & Minikube deletion
#   ./scripts/cluster.sh status   # Check health of all pods and scrape targets
#   ./scripts/cluster.sh forward  # Start port-forwards for Grafana, Prom, Alertmanager, App
# ==============================================================================

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/Terraform/stack"
APP_DIR="$PROJECT_ROOT/Terraform/App"

# Color helpers
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

function log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

function log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

function log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

function log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

function cluster_up() {
    echo "=========================================================="
    echo " 🚀 SRE PLATFORM: STARTING FULL END-TO-END DEPLOYMENT"
    echo "=========================================================="

    # 1. Start Minikube
    log_info "1/4 Checking / Starting Minikube cluster..."
    if minikube status >/dev/null 2>&1; then
        log_info "Minikube is already running."
    else
        log_info "Starting Minikube (4 CPUs, 8GB RAM)..."
        minikube start --cpus=4 --memory=8192 --driver=docker
    fi

    # 2. Deploy Terraform Stack
    log_info "2/4 Applying Terraform Infrastructure & Observability Stack..."
    cd "$TERRAFORM_DIR"
    terraform init
    terraform apply -auto-approve

    # 3. Deploy Application Microservice
    log_info "3/4 Deploying Application Microservice (3 replicas)..."
    kubectl apply -f "$APP_DIR/deployment.yaml"

    # 4. Wait for Pod Readiness
    log_info "4/4 Waiting for all monitoring and application pods to be Ready..."
    kubectl rollout status deployment/sre-project-app -n application --timeout=120s
    kubectl rollout status deployment/prometheus-server -n monitoring --timeout=180s
    kubectl rollout status deployment/grafana -n monitoring --timeout=180s

    echo ""
    log_success "🎉 SRE Platform is fully deployed and healthy!"
    echo "=========================================================="
    print_access_info
}

function cluster_down() {
    echo "=========================================================="
    echo " 🛑 SRE PLATFORM: TEARING DOWN CLUSTER"
    echo "=========================================================="

    log_warn "Destroying Terraform resources..."
    cd "$TERRAFORM_DIR"
    terraform destroy -auto-approve || true

    log_warn "Deleting Minikube cluster..."
    minikube delete

    log_success "Cluster destroyed cleanly."
}

function cluster_status() {
    echo "=========================================================="
    echo " 📊 SRE PLATFORM: CLUSTER STATUS"
    echo "=========================================================="
    
    echo -e "\n${BLUE}--- Application Namespace ---${NC}"
    kubectl get pods,svc -n application -o wide

    echo -e "\n${BLUE}--- Monitoring Namespace ---${NC}"
    kubectl get pods,svc -n monitoring -o wide

    echo -e "\n${BLUE}--- Prometheus Target Status ---${NC}"
    kubectl exec -n monitoring deploy/prometheus-server -c prometheus-server -- \
      wget -qO- "http://localhost:9090/api/v1/targets" 2>/dev/null | grep -o '"health":"[^"]*"' | head -n 5 || echo "Prometheus server starting..."
}

function print_access_info() {
    echo ""
    echo "📋 ACCESS & PORT-FORWARD COMMANDS:"
    echo "----------------------------------------------------------"
    echo "Grafana (3000):"
    echo "  kubectl port-forward svc/grafana -n monitoring 3000:80"
    echo "  Password: \$(kubectl get secret -n monitoring grafana -o jsonpath=\"{.data.admin-password}\" | base64 --decode)"
    echo ""
    echo "Prometheus (9090):"
    echo "  kubectl port-forward svc/prometheus-server -n monitoring 9090:80"
    echo ""
    echo "Alertmanager (9093):"
    echo "  kubectl port-forward svc/prometheus-alertmanager -n monitoring 9093:9093"
    echo ""
    echo "Application Service (5000):"
    echo "  kubectl port-forward svc/sre-project-app -n application 5000:5000"
    echo ""
    echo "Generate Traffic & Chaos:"
    echo "  ./scripts/traffic-test.sh"
    echo "=========================================================="
}

function start_port_forwards() {
    echo "=========================================================="
    echo " 🔌 STARTING LOCAL PORT FORWARDS"
    echo "=========================================================="
    log_info "Forwarding Grafana -> http://localhost:3000"
    kubectl port-forward svc/grafana -n monitoring 3000:80 > /dev/null 2>&1 &
    
    log_info "Forwarding Prometheus -> http://localhost:9090"
    kubectl port-forward svc/prometheus-server -n monitoring 9090:80 > /dev/null 2>&1 &

    log_info "Forwarding Alertmanager -> http://localhost:9093"
    kubectl port-forward svc/prometheus-alertmanager -n monitoring 9093:9093 > /dev/null 2>&1 &

    log_info "Forwarding SRE App -> http://localhost:5000"
    kubectl port-forward svc/sre-project-app -n application 5000:5000 > /dev/null 2>&1 &

    log_success "Port-forwards running in background. Press Ctrl+C or kill processes to stop."
    wait
}

case "$1" in
    up)
        cluster_up
        ;;
    down)
        cluster_down
        ;;
    status)
        cluster_status
        ;;
    forward)
        start_port_forwards
        ;;
    *)
        echo "Usage: $0 {up|down|status|forward}"
        exit 1
        ;;
esac
