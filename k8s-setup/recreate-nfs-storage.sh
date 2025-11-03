#!/bin/bash
set -e

PROXMOX_HOST="${1:-proxmox.test.local}"
NFS_PATH="${2:-/mnt/k8s-storage}"

echo "Removing existing NFS storage..."

# Delete StorageClass
kubectl delete storageclass nfs-storage --ignore-not-found=true

# Uninstall NFS CSI driver
helm uninstall csi-driver-nfs -n kube-system --ignore-not-found 2>/dev/null || true

echo "Reinstalling NFS storage..."

# Install NFS CSI driver
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm repo update
helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs -n kube-system

# Wait for CSI driver
echo "Waiting for CSI driver pods..."
sleep 10
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=csi-driver-nfs -n kube-system --timeout=120s 2>/dev/null || echo "Pods starting..."

# Create StorageClass
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-storage
provisioner: nfs.csi.k8s.io
parameters:
  server: $PROXMOX_HOST
  share: $NFS_PATH
reclaimPolicy: Delete
volumeBindingMode: Immediate
EOF

echo "✓ NFS storage recreated successfully"
echo "StorageClass: nfs-storage"
