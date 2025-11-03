#!/bin/bash
set -e

echo "Disabling Prometheus remote write to OpenSearch..."

cat > prometheus-values-fixed.yaml <<EOF
# No remote write - keep metrics in Prometheus only
EOF

helm upgrade kube-prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f prometheus-values-fixed.yaml

echo "✓ Prometheus remote write disabled"
echo ""
echo "View metrics in Grafana:"
echo "  kubectl port-forward -n monitoring svc/kube-prometheus-grafana 3000:80"
echo ""
echo "View logs in OpenSearch:"
echo "  kubectl port-forward -n opensearch svc/opensearch-dashboards 5601:5601"
