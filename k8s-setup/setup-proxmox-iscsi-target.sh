#!/bin/bash

# Setup Proxmox as iSCSI Target with ZFS
# Usage: ./setup-proxmox-iscsi-target.sh <proxmox-host>

PROXMOX_HOST="${1:-proxmox.test.local}"

echo "Setting up iSCSI target on $PROXMOX_HOST..."

ssh "$PROXMOX_HOST" 'bash -s' <<'ENDSSH'

# Install iSCSI target software
echo "Installing targetcli..."
apt update
apt install -y targetcli-fb

# Enable and start target service
systemctl enable --now rtslib-fb-targetctl
systemctl enable --now target

# Create ZFS datasets for Kubernetes storage
echo "Creating ZFS datasets..."
POOL=$(zpool list -H -o name | head -n1)
echo "Using ZFS pool: $POOL"

zfs create -o mountpoint=/k8s $POOL/k8s 2>/dev/null || echo "Dataset $POOL/k8s exists"
zfs create $POOL/k8s/iscsi 2>/dev/null || echo "Dataset $POOL/k8s/iscsi exists"
zfs create $POOL/k8s/iscsi-snapshots 2>/dev/null || echo "Dataset $POOL/k8s/iscsi-snapshots exists"

# Set permissions
zfs set compression=lz4 $POOL/k8s/iscsi
zfs set atime=off $POOL/k8s/iscsi

echo "✓ ZFS datasets created:"
zfs list -r $POOL/k8s

# Configure basic iSCSI target
echo "Configuring iSCSI target..."
targetcli <<EOF
/backstores/block create name=test-lun dev=/dev/zvol/$POOL/test-volume
/iscsi create iqn.2024-01.local.proxmox:target1
/iscsi/iqn.2024-01.local.proxmox:target1/tpg1/luns create /backstores/block/test-lun
/iscsi/iqn.2024-01.local.proxmox:target1/tpg1/acls create iqn.2024-01.local.proxmox:initiator
/iscsi/iqn.2024-01.local.proxmox:target1/tpg1 set attribute authentication=0
/iscsi/iqn.2024-01.local.proxmox:target1/tpg1 set attribute generate_node_acls=1
/iscsi/iqn.2024-01.local.proxmox:target1/tpg1 set attribute demo_mode_write_protect=0
saveconfig
exit
EOF

echo "✓ iSCSI target configured"
echo ""
echo "Target Portal: $(hostname -I | awk '{print $1}'):3260"
echo "IQN: iqn.2024-01.local.proxmox:target1"

ENDSSH

echo "✓ Setup complete on $PROXMOX_HOST"
