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

# Wait for VM to boot
echo "Waiting for VM to boot..."
sleep 30

# Get VM IP address
VM_IP=$(qm guest cmd $VMID network-get-interfaces 2>/dev/null | grep -oP '(?<="ip-address":")[^"]*' | grep -v '^127\.' | grep -v '^::' | head -1)

if [ -z "$VM_IP" ]; then
    echo "WARNING: Could not get VM IP address. Please verify GPU manually with: ssh <vm-ip> lspci | grep -i nvidia"
    exit 0
fi

echo "VM IP: $VM_IP"
echo "Verifying GPU in VM..."

# Verify GPU with lspci
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@$VM_IP "lspci | grep -i nvidia" && \
echo "GPU successfully detected in VM" || \
echo "WARNING: GPU not detected in VM"
