#!/bin/bash

# Install iSCSI initiator tools on all MicroK8s nodes
# Usage: ./install-iscsi-tools.sh

NODES="microk8s-vm1.test.local microk8s-vm2.test.local microk8s-vm3.test.local"

for NODE in $NODES; do
    echo "Installing iSCSI tools on $NODE..."
    ssh "$NODE" "sudo apt update && sudo apt install -y open-iscsi && sudo systemctl enable --now iscsid"
    echo "✓ $NODE configured"
done

echo "✓ All nodes ready for iSCSI storage"
