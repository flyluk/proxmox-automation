#!/bin/bash

# Get kubeconfig from MicroK8s VM
# Usage: ./get-kubeconfig.sh [vm-hostname]

VM_HOST="${1:-microk8s-vm1.test.local}"
KUBECONFIG_DIR="$HOME/.kube"
KUBECONFIG_FILE="$KUBECONFIG_DIR/config"

echo "Retrieving kubeconfig from $VM_HOST..."

# Create .kube directory if it doesn't exist
mkdir -p "$KUBECONFIG_DIR"

# Get kubeconfig from VM and update server address
ssh "$VM_HOST" "sudo microk8s config" | \
  sed "s/server: https:\/\/127.0.0.1:16443/server: https:\/\/$VM_HOST:16443/" > "$KUBECONFIG_FILE"

if [ $? -eq 0 ]; then
    chmod 600 "$KUBECONFIG_FILE"
    echo "✓ Kubeconfig saved to $KUBECONFIG_FILE"
    echo "✓ You can now run kubectl commands"
else
    echo "✗ Failed to retrieve kubeconfig"
    exit 1
fi
