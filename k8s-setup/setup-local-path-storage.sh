#!/bin/bash

# Setup local-path storage provisioner (simplest option)
# Usage: ./setup-local-path-storage.sh

echo "Installing local-path-provisioner..."

kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.28/deploy/local-path-storage.yaml

# Set as default storage class
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

echo "✓ Local path storage installed"
echo ""
echo "Usage:"
echo "  storageClassName: local-path"
echo ""
echo "Note: Storage is local to each node (not shared)"
