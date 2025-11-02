#!/bin/bash

# VM IDs to remove (matching create-microk8s-vms.sh)
VM_IDS=(9101 9102 9103 9104 9105 9106)

echo "Removing MicroK8s VMs..."

for VMID in "${VM_IDS[@]}"; do
  echo "Processing VM $VMID..."
  
  # Stop VM if running
  if qm status $VMID >/dev/null 2>&1; then
    echo "  Stopping VM $VMID..."
    qm stop $VMID
    
    # Wait for VM to stop
    while qm status $VMID | grep -q "running"; do
      sleep 2
    done
    
    # Destroy VM
    echo "  Destroying VM $VMID..."
    qm destroy $VMID
  else
    echo "  VM $VMID not found, skipping..."
  fi
done

echo "All MicroK8s VMs removed."