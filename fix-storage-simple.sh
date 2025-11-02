#!/bin/bash

# Remove Proxmox CSI and use NFS only (simpler, works better with MicroK8s)
# Usage: ./fix-storage-simple.sh <proxmox-host> <nfs-path>

PROXMOX_HOST="${1:-proxmox.test.local}"
NFS_PATH="${2:-/mnt/k8s-storage}"

echo "Removing Proxmox CSI (incompatible with MicroK8s)..."
kubectl delete namespace csi-proxmox --ignore-not-found=true

echo "Setting up NFS storage only..."

# Setup NFS on Proxmox
ssh "$PROXMOX_HOST" bash -s <<ENDSSH
apt update
apt install -y nfs-kernel-server
mkdir -p $NFS_PATH
chmod 777 $NFS_PATH
grep -q "$NFS_PATH" /etc/exports || echo "$NFS_PATH *(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
exportfs -ra
systemctl restart nfs-kernel-server
echo "✓ NFS server ready at $NFS_PATH"
ENDSSH

# Install NFS CSI driver
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm repo update
helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs -n kube-system --set driver.name=nfs.csi.k8s.io

# Create NFS StorageClass for RWO (default)
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-rwo
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: nfs.csi.k8s.io
parameters:
  server: $PROXMOX_HOST
  share: $NFS_PATH
reclaimPolicy: Delete
volumeBindingMode: Immediate
allowVolumeExpansion: true
EOF

# Create NFS StorageClass for RWX
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-rwx
provisioner: nfs.csi.k8s.io
parameters:
  server: $PROXMOX_HOST
  share: $NFS_PATH
reclaimPolicy: Delete
volumeBindingMode: Immediate
allowVolumeExpansion: true
EOF

echo ""
echo "✓ NFS storage configured"
echo ""
echo "Storage Classes:"
echo "  - nfs-rwo (default) - ReadWriteOnce"
echo "  - nfs-rwx - ReadWriteMany"
echo ""
echo "Both use NFS (simpler and works with MicroK8s)"
