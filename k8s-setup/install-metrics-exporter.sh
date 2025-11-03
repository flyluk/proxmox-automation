#!/bin/bash
set -e

echo "Installing Prometheus and metrics exporters..."

# Create namespace if not exists
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

cat > prometheus-values.yaml <<EOF
prometheus:
  prometheusSpec:
    remoteWrite:
      - url: "https://opensearch-cluster-master.opensearch.svc.cluster.local:9200/_prometheus/write"
        basicAuth:
          username:
            name: opensearch-auth
            key: username
          password:
            name: opensearch-auth
            key: password
        tlsConfig:
          insecureSkipVerify: true
EOF

# Create secret for OpenSearch auth
kubectl create secret generic opensearch-auth \
  -n monitoring \
  --from-literal=username=admin \
  --from-literal=password=Strong_password1 \
  --dry-run=client -o yaml | kubectl apply -f -

# Install kube-prometheus-stack
helm upgrade --install kube-prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --create-namespace \
  -f prometheus-values.yaml

echo "✓ Prometheus installed - Metrics will be sent to OpenSearch"
echo ""
echo "Access Grafana:"
echo "  kubectl port-forward -n monitoring svc/kube-prometheus-grafana 3000:80"
echo "  Login: admin / prom-operator"
