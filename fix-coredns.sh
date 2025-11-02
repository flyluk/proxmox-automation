#!/bin/bash

# Fix CoreDNS by disabling and re-enabling MicroK8s DNS addon
# Usage: ./fix-coredns.sh

echo "Fixing CoreDNS on all nodes..."

NODES="microk8s-vm1.test.local microk8s-vm2.test.local microk8s-vm3.test.local microk8s-vm4.test.local microk8s-vm5.test.local microk8s-vm6.test.local"

# Delete broken CoreDNS deployment
kubectl delete deployment coredns -n kube-system --ignore-not-found=true
kubectl delete pods -n kube-system -l k8s-app=kube-dns --force --grace-period=0 2>/dev/null || true

# Restart MicroK8s DNS addon on primary node
echo "Restarting DNS addon on primary node..."
ssh microk8s-vm1.test.local "microk8s disable dns && sleep 5 && microk8s enable dns"

echo ""
echo "Waiting for CoreDNS to be ready..."
sleep 10

kubectl wait --for=condition=ready pod -l k8s-app=kube-dns -n kube-system --timeout=60s

echo ""
echo "✓ CoreDNS fixed"
kubectl get pods -n kube-system -l k8s-app=kube-dns
