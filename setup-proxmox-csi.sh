#!/bin/bash

# Setup Proxmox CSI plugin for native Proxmox storage
# Usage: ./setup-proxmox-csi.sh <proxmox-host> <api-token>

PROXMOX_HOST="${1}"
API_TOKEN="${2}"

if [ -z "$PROXMOX_HOST" ] || [ -z "$API_TOKEN" ]; then
    echo "Usage: ./setup-proxmox-csi.sh <proxmox-host> <api-token>"
    echo ""
    echo "To create API token in Proxmox:"
    echo "1. Datacenter → Permissions → API Tokens"
    echo "2. Add → User: root@pam, Token ID: k8s"
    echo "3. Copy the token"
    exit 1
fi

echo "Installing Proxmox CSI plugin..."

# Create namespace
kubectl create namespace proxmox-csi 2>/dev/null || true

# Create secret with Proxmox credentials
kubectl create secret generic proxmox-csi-plugin \
    -n proxmox-csi \
    --from-literal=token="$API_TOKEN" \
    --dry-run=client -o yaml | kubectl apply -f -

# Install Proxmox CSI
kubectl apply -f https://raw.githubusercontent.com/sergelogvinov/proxmox-csi-plugin/main/docs/deploy/proxmox-csi-plugin.yml

# Create StorageClass
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: proxmox-storage
provisioner: csi.proxmox.sinextra.dev
parameters:
  storage: local-lvm
  cache: writethrough
  ssd: "true"
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
EOF

echo "✓ Proxmox CSI installed"
echo "StorageClass: proxmox-storage"
