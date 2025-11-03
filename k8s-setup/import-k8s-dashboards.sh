#!/bin/bash
set -e

echo "Importing K8s dashboards to Grafana..."

GRAFANA_PASSWORD=$(kubectl get secret -n monitoring kube-prometheus-grafana -o jsonpath='{.data.admin-password}' | base64 -d)

# Dashboard IDs to import
DASHBOARDS=(
  "315"    # Kubernetes cluster monitoring
  "747"    # Kubernetes deployment
  "6417"   # Kubernetes cluster (Prometheus)
  "8588"   # Kubernetes Deployment Statefulset Daemonset metrics
)

echo "Grafana password: ${GRAFANA_PASSWORD}"
echo ""
echo "Manual import steps:"
echo "1. Access Grafana: kubectl port-forward -n monitoring svc/kube-prometheus-grafana 3000:80"
echo "2. Login: admin / ${GRAFANA_PASSWORD}"
echo "3. Go to: Dashboards → Import"
echo "4. Enter dashboard ID and click 'Load':"
for id in "${DASHBOARDS[@]}"; do
  echo "   - ${id}"
done
echo "5. Select 'Prometheus' as data source"
echo "6. Click 'Import'"
