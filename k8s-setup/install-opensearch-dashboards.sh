#!/bin/bash
set -e

helm uninstall opensearch-dashboards -n opensearch

cat > dashboards-values.yaml <<EOF
image:
  tag: "3.3.0"

kuopensearchHosts: "https://opensearch-cluster-master:9200"

replicas: 1

config:
  opensearch_dashboards.yml: |
    server.host: '0.0.0.0'
    opensearch.hosts: ["https://opensearch-cluster-master:9200"]
    opensearch.ssl.verificationMode: none
    opensearch.username: admin
    opensearch.password: Strong_password1
    opensearch.requestHeadersWhitelist: ["securitytenant","Authorization"]
EOF

helm install opensearch-dashboards opensearch/opensearch-dashboards \
  -n opensearch \
  -f dashboards-values.yaml

echo "✓ OpenSearch Dashboards reinstalled"
