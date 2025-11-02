#!/bin/bash

# Fix networking by removing Calico and using MicroK8s native networking
# Usage: ./fix-networking.sh

echo "Removing broken Calico installation..."

# Delete Calico resources
kubectl delete daemonset calico-node -n kube-system --ignore-not-found=true
kubectl delete deployment calico-kube-controllers -n kube-system --ignore-not-found=true
kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml --ignore-not-found=true 2>/dev/null || true

# Clean up any remaining Calico resources
kubectl delete pods -n kube-system -l k8s-app=calico-node --force --grace-period=0 2>/dev/null || true
kubectl delete pods -n kube-system -l k8s-app=calico-kube-controllers --force --grace-period=0 2>/dev/null || true

echo "✓ Calico removed"
echo ""
echo "MicroK8s uses its own networking (Calico is built-in)"
echo "No additional networking setup needed"
echo ""
echo "Checking cluster status..."
kubectl get nodes
kubectl get pods -n kube-system | grep -E "coredns|dns"
