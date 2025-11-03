#!/bin/bash

# Setup hybrid storage: NFS (RWX) + Proxmox CSI (RWO)
# Usage: ./setup-hybrid-storage.sh <proxmox-host> <api-token> <nfs-path>

PROXMOX_HOST="${1}"
API_TOKEN="${2}"
NFS_PATH="${3:-/mnt/k8s-nfs}"

if [ -z "$PROXMOX_HOST" ] || [ -z "$API_TOKEN" ]; then
    echo "Usage: ./setup-hybrid-storage.sh <proxmox-host> <api-token> [nfs-path]"
    echo ""
    echo "Example: ./setup-hybrid-storage.sh proxmox.test.local 'PVEAPIToken=root@pam!k8s=xxx' /mnt/k8s-nfs"
    exit 1
fi

echo "Setting up hybrid storage on $PROXMOX_HOST..."

# 1. Setup NFS for ReadWriteMany
echo "=== Setting up NFS (ReadWriteMany) ==="
ssh "$PROXMOX_HOST" bash -s <<ENDSSH
apt update
apt install -y nfs-kernel-server
mkdir -p $NFS_PATH
chmod 777 $NFS_PATH
grep -q "$NFS_PATH" /etc/exports || echo "$NFS_PATH *(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
exportfs -ra
systemctl restart nfs-kernel-server
echo "✓ NFS server ready"
ENDSSH

# Install NFS CSI driver
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm repo update
helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs -n kube-system --set driver.name=nfs.csi.k8s.io

# Create NFS StorageClass
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-rwx
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: nfs.csi.k8s.io
parameters:
  server: $PROXMOX_HOST
  share: $NFS_PATH
reclaimPolicy: Delete
volumeBindingMode: Immediate
allowVolumeExpansion: true
EOF

echo "✓ NFS storage class created: nfs-rwx"

# 2. Setup Proxmox CSI for ReadWriteOnce
echo ""
echo "=== Setting up Proxmox CSI (ReadWriteOnce) ==="

kubectl create namespace csi-proxmox 2>/dev/null || true

# Create config file
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: proxmox-csi-config
  namespace: csi-proxmox
data:
  config.yaml: |
    clusters:
    - url: https://$PROXMOX_HOST:8006/api2/json
      insecure: true
      token_id: "$API_TOKEN"
      region: cluster
EOF

# Install Proxmox CSI
kubectl apply -f https://raw.githubusercontent.com/sergelogvinov/proxmox-csi-plugin/main/docs/deploy/proxmox-csi-plugin.yml

# Create Proxmox StorageClass (RWO - fast block storage)
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: proxmox-rwo
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: csi.proxmox.sinextra.dev
parameters:
  storage: local-lvm
  cache: writethrough
  ssd: "true"
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF

echo "✓ Proxmox CSI storage class created: proxmox-rwo (default)"

echo ""
echo "=========================================="
echo "✓ Hybrid storage setup complete!"
echo "=========================================="
echo ""
echo "Storage Classes:"
echo "  1. proxmox-rwo (default) - ReadWriteOnce - Fast block storage"
echo "     Use for: Databases, high-performance apps"
echo ""
echo "  2. nfs-rwx - ReadWriteMany - Shared file storage"
echo "     Use for: Shared files, web apps, logs"
echo ""
echo "Examples:"
echo "  # Database (RWO)"
echo "  storageClassName: proxmox-rwo"
echo ""
echo "  # Shared files (RWX)"
echo "  storageClassName: nfs-rwx"
