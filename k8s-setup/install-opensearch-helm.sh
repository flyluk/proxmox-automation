#!/bin/bash
set -e

# Uninstall existing OpenSearch
echo "Uninstalling existing OpenSearch..."
helm uninstall opensearch -n opensearch 2>/dev/null || true

# Wait for pods to terminate
echo "Waiting for pods to terminate..."
kubectl wait --for=delete pod -l app.kubernetes.io/instance=opensearch -n opensearch 2>/dev/null || true

# Delete PVCs
echo "Deleting PVCs..."
kubectl delete pvc -n opensearch --all --force --grace-period=0 2>/dev/null || true
sleep 3

# Add OpenSearch Helm repository
echo "Adding OpenSearch Helm repository..."
helm repo add opensearch https://opensearch-project.github.io/helm-charts/
helm repo update

# Install OpenSearch
echo "Installing OpenSearch..."
helm install opensearch opensearch/opensearch \
  --namespace opensearch \
  --create-namespace \
  -f opensearch-values.yaml

echo "OpenSearch installation complete!"
echo ""
echo "Check status with:"
echo "  kubectl get pods -n opensearch"
echo ""
echo "Access OpenSearch:"
echo "  kubectl port-forward -n opensearch svc/opensearch-cluster-master 9200:9200"
