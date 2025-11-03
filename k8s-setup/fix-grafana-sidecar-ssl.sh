#!/bin/bash
set -e

echo "Fixing Grafana sidecar SSL issue..."

cat > prometheus-values.yaml <<EOF
prometheus:
  prometheusSpec:
    remoteWrite: []

grafana:
  sidecar:
    dashboards:
      enabled: true
      SCProvider: true
      env:
        SKIP_TLS_VERIFY: "true"
    datasources:
      enabled: true
      env:
        SKIP_TLS_VERIFY: "true"
EOF

helm upgrade kube-prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f prometheus-values.yaml

echo "✓ Grafana sidecar SSL verification disabled"
