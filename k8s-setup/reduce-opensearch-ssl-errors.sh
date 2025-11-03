#!/bin/bash
set -e

echo "Reducing OpenSearch SSL error logging..."

# Update OpenSearch values to reduce SSL error logging
cat > opensearch-values-quiet.yaml <<EOF
config:
  opensearch.yml: |
    cluster.name: opensearch-cluster
    network.host: 0.0.0.0
  log4j2.properties: |
    logger.securecomm.name = org.opensearch.http.netty4.ssl
    logger.securecomm.level = warn

extraEnvs:
  - name: OPENSEARCH_INITIAL_ADMIN_PASSWORD
    value: Strong_password1

persistence:
  enabled: true
  size: 30Gi
  storageClass: nfs-storage

resources:
  requests:
    memory: "4Gi"
    cpu: "2"
  limits:
    memory: "8Gi"
    cpu: "4"

replicas: 3

image:
  repository: opensearchproject/opensearch
  tag: "2.9.0"

securityConfig:
  enabled: false

podSecurityContext:
  fsGroup: null

sysctlInit:
  enabled: false
EOF

# Upgrade OpenSearch with new config
helm upgrade opensearch opensearch/opensearch \
  -n opensearch \
  -f opensearch-values-quiet.yaml

echo "✓ OpenSearch log level reduced - SSL errors will be less verbose"
