#!/bin/bash
set -e

echo "Setting up Prometheus data source in Grafana..."

# Get Grafana password
GRAFANA_PASSWORD=$(kubectl get secret -n monitoring kube-prometheus-grafana -o jsonpath='{.data.admin-password}' | base64 -d)

# Port forward Grafana in background
kubectl port-forward -n monitoring svc/kube-prometheus-grafana 3000:80 &
PF_PID=$!
sleep 5

# Add Prometheus data source
curl -X POST http://admin:${GRAFANA_PASSWORD}@localhost:3000/api/datasources \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Prometheus",
    "type": "prometheus",
    "url": "http://kube-prometheus-kube-prome-prometheus.monitoring.svc.cluster.local:9090",
    "access": "proxy",
    "isDefault": true
  }'

# Kill port forward
kill $PF_PID

echo ""
echo "✓ Prometheus data source configured"
echo ""
echo "Access Grafana:"
echo "  kubectl port-forward -n monitoring svc/kube-prometheus-grafana 3000:80"
echo "  Login: admin / ${GRAFANA_PASSWORD}"
