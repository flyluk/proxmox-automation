#!/bin/bash

# Setup TrueNAS VM on Proxmox for iSCSI storage
# Usage: ./setup-truenas-vm.sh <proxmox-host> <vmid> <storage-disk-size-gb>

PROXMOX_HOST="${1:-proxmox.test.local}"
VMID="${2:-200}"
DISK_SIZE="${3:-100}"

echo "Creating TrueNAS VM on $PROXMOX_HOST (VMID: $VMID)..."

ssh "$PROXMOX_HOST" bash -s <<ENDSSH
# Download TrueNAS SCALE ISO
cd /var/lib/vz/template/iso
if [ ! -f TrueNAS-SCALE-24.10.0.iso ]; then
    echo "Downloading TrueNAS SCALE ISO..."
    wget -O TrueNAS-SCALE-24.10.0.iso https://download.truenas.com/TrueNAS-SCALE-Dragonfish/24.10.0/TrueNAS-SCALE-24.10.0.iso
fi

# Create VM
qm create $VMID \
    --name truenas \
    --memory 8192 \
    --cores 4 \
    --cpu host \
    --net0 virtio,bridge=vmbr0 \
    --ostype l26 \
    --scsihw virtio-scsi-pci

# Add boot disk (for TrueNAS OS)
qm set $VMID --scsi0 local-lvm:32,format=raw

# Add storage disk (for ZFS pool)
qm set $VMID --scsi1 local-lvm:${DISK_SIZE},format=raw

# Add ISO
qm set $VMID --ide2 local:iso/TrueNAS-SCALE-24.10.0.iso,media=cdrom

# Set boot order
qm set $VMID --boot order=ide2

# Start VM
qm start $VMID

echo "✓ TrueNAS VM created (VMID: $VMID)"
echo ""
echo "Next steps:"
echo "1. Access Proxmox console for VM $VMID"
echo "2. Install TrueNAS to scsi0 disk"
echo "3. After reboot, access TrueNAS web UI"
echo "4. Run: ./configure-truenas.sh <truenas-ip>"
ENDSSH
