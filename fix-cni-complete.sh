#!/bin/bash

# Complete CNI cleanup and reset to MicroK8s default
# Usage: ./fix-cni-complete.sh

NODES="microk8s-vm1.test.local microk8s-vm2.test.local microk8s-vm3.test.local microk8s-vm4.test.local microk8s-vm5.test.local microk8s-vm6.test.local"

echo "Cleaning up Calico CNI from all nodes..."

for NODE in $NODES; do
    echo "Cleaning $NODE..."
    ssh "$NODE" bash -s <<'ENDSSH'
# Stop MicroK8s
microk8s stop

# Remove Calico CNI config
rm -rf /var/snap/microk8s/current/args/cni-network/*calico*
rm -rf /var/snap/microk8s/current/opt/cni/bin/calico*
rm -rf /etc/cni/net.d/*calico*

# Start MicroK8s
microk8s start
sleep 5
ENDSSH
    echo "✓ $NODE cleaned"
done

echo ""
echo "Waiting for cluster to stabilize..."
sleep 15

echo "Checking cluster status..."
kubectl get nodes
kubectl get pods -n kube-system

echo ""
echo "✓ CNI cleanup complete"
