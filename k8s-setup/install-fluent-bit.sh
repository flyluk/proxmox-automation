#!/bin/bash
set -e

echo "Installing Fluent Bit for log collection..."

helm repo add fluent https://fluent.github.io/helm-charts
helm repo update

cat > fluent-bit-values.yaml <<EOF
config:
  outputs: |
    [OUTPUT]
        Name opensearch
        Match kube.*
        Host opensearch-cluster-master.opensearch.svc.cluster.local
        Port 9200
        HTTP_User admin
        HTTP_Passwd Strong_password1
        Index fluent-bit
        Suppress_Type_Name On
        tls On
        tls.verify Off

  filters: |
    [FILTER]
        Name kubernetes
        Match kube.*
        Kube_URL https://kubernetes.default.svc:443
        Kube_CA_File /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        Kube_Token_File /var/run/secrets/kubernetes.io/serviceaccount/token
        Merge_Log On
        Keep_Log Off
EOF

helm upgrade fluent-bit fluent/fluent-bit \
  -n kube-system \
  -f fluent-bit-values.yaml

echo "✓ Fluent Bit installed - K8s logs will be sent to OpenSearch"
