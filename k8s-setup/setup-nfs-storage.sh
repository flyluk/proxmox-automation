#!/bin/bash

# Setup NFS storage on Proxmox for Kubernetes
# Usage: ./setup-nfs-storage.sh <proxmox-host> <nfs-path>

PROXMOX_HOST="${1:-proxmox.test.local}"
NFS_PATH="${2:-/mnt/k8s-storage}"

echo "Setting up NFS server on $PROXMOX_HOST..."

ssh "$PROXMOX_HOST" bash -s <<ENDSSH
# Install NFS server
apt update
apt install -y nfs-kernel-server

# Create NFS export directory
mkdir -p $NFS_PATH
chmod 777 $NFS_PATH

# Configure NFS export
echo "$NFS_PATH *(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports

# Apply exports
exportfs -ra
systemctl restart nfs-kernel-server

echo "✓ NFS server configured"
echo "Export: $NFS_PATH"
ENDSSH

# Install NFS CSI driver on Kubernetes
echo "Installing NFS CSI driver..."
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm repo update
helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs -n kube-system

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

echo "✓ NFS storage configured"
echo "StorageClass: nfs-storage"
