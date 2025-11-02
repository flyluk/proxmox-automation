#!/bin/bash

# Fix cluster certificates after IP change
# Usage: ./fix-cluster-certificates.sh

echo "Checking cluster configuration..."

# Get current kubeconfig
kubectl config view --minify

echo ""
echo "Current API server endpoint:"
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'
echo ""

# Check which node is the primary
echo ""
echo "Checking nodes..."
kubectl get nodes -o wide

echo ""
read -p "Is microk8s-vm1 (192.168.1.11) the primary node? (y/n): " confirm

if [ "$confirm" != "y" ]; then
    echo "Please specify the correct primary node IP"
    exit 1
fi

echo ""
echo "Regenerating certificates on microk8s-vm1..."
ssh microk8s-vm1.test.local bash -s <<'ENDSSH'
# Refresh certificates
sudo microk8s refresh-certs -e ca.crt
sudo microk8s refresh-certs -e server.crt
sudo microk8s refresh-certs -e front-proxy-client.crt

# Restart MicroK8s
sudo microk8s stop
sleep 5
sudo microk8s start
sleep 10

echo "✓ Certificates refreshed"
ENDSSH

echo ""
echo "Getting new kubeconfig..."
ssh microk8s-vm1.test.local "sudo microk8s config" > ~/.kube/config.new
mv ~/.kube/config.new ~/.kube/config
chmod 600 ~/.kube/config

echo ""
echo "✓ Cluster certificates fixed"
echo "Testing connection..."
kubectl get nodes
