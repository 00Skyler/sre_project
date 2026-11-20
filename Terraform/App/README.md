# 🐍 Application Microservice - SRE Project

A containerized Python Flask REST API instrumented with `prometheus-flask-exporter` for real-time observability and Golden Signals metric harvesting.

## 📡 Endpoints

- `GET /` : Health check / Hello World.
- `GET /store` : Product list retrieval (200 OK traffic).
- `GET /error` : Simulated HTTP 500 server error endpoint for chaos and alert verification.
- `GET /metrics` : Prometheus exporter endpoint.

## 🐳 Containerization & Deployment

- **Dockerfile:** Builds a secure, non-root (`appuser`) image based on `python:3.13-slim` using `gunicorn`.
- **Kubernetes:** [`deployment.yaml`](deployment.yaml:1) provisions 3 Pod replicas and a ClusterIP Service inside the `application` namespace.

```bash
# Apply deployment to Kubernetes
kubectl apply -f deployment.yaml

# Test metrics endpoint via port-forward
kubectl port-forward svc/sre-project-app -n application 5000:5000
curl http://localhost:5000/metrics
```

For complete instructions and verification, refer to the [Root README.md](../../README.md).
