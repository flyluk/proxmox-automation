#!/bin/bash
set -e

echo "Checking Grafana dashboards..."

# Get Grafana pod
POD=$(kubectl get pod -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}')

echo "Grafana pod: $POD"
echo ""
echo "To access Grafana:"
echo "1. Port-forward:"
echo "   kubectl port-forward -n monitoring svc/kube-prometheus-grafana 3000:80"
echo ""
echo "2. Get admin password:"
kubectl get secret -n monitoring kube-prometheus-grafana -o jsonpath='{.data.admin-password}' | base64 -d
echo ""
echo ""
echo "3. Login: admin / (password above)"
echo ""
echo "4. Find dashboards at:"
echo "   - Click 'Dashboards' (left menu)"
echo "   - Or go to: Home → Dashboards"
echo ""
echo "5. Look for folders:"
echo "   - General"
echo "   - Kubernetes / Compute Resources"
echo "   - Kubernetes / Networking"
echo ""
echo "If no dashboards, check ConfigMaps:"
kubectl get configmap -n monitoring | grep dashboard
