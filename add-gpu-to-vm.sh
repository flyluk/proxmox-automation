#!/bin/bash

# Usage: ./add-gpu-to-vm.sh <vmid>

if [ $# -ne 1 ]; then
    echo "Usage: $0 <vmid>"
    exit 1
fi

VMID=$1

# Check if VM exists
if ! qm status $VMID &>/dev/null; then
    echo "ERROR: VM $VMID does not exist"
    exit 1
fi

# Check if VM is running
if qm status $VMID | grep -q "running"; then
    echo "ERROR: VM $VMID is running. Please stop it first."
    exit 1
fi

echo "Adding GPU support to VM $VMID..."

# Change machine type to q35
qm set $VMID --machine q35

# Add PCI device mapping with rombar disabled
qm set $VMID --hostpci0 mapping=nvidia-gpu,rombar=0

echo "GPU added to VM $VMID successfully"
echo "Machine type changed to q35"

# Start the VM
echo "Starting VM $VMID..."
qm start $VMID

# Wait for VM to boot and qemu-guest-agent to start
echo "Waiting for VM to boot..."
sleep 30

echo "Verifying GPU in VM..."

# Verify GPU with lspci using qemu-guest-agent
if qm guest exec $VMID -- lspci 2>/dev/null | grep -i nvidia; then
    echo "GPU successfully detected in VM"
else
    echo "WARNING: GPU not detected in VM. Make sure qemu-guest-agent is installed."
fi
