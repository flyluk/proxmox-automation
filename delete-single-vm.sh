#!/bin/bash

# Parse options
while [[ $# -gt 0 ]]; do
  case $1 in
    --vid|-v)
      VMID="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 --vid <vmid>"
      echo "Example: $0 --vid 9107"
      exit 0
      ;;
    *)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

# Check required parameters
if [[ -z "$VMID" ]]; then
  echo "Error: Missing required parameter --vid"
  echo "Usage: $0 --vid <vmid>"
  exit 1
fi

echo "Deleting VM $VMID..."

# Check if VM exists
if ! qm status $VMID >/dev/null 2>&1; then
  echo "VM $VMID not found"
  exit 1
fi

# Stop VM if running
if qm status $VMID | grep -q "running"; then
  echo "Stopping VM $VMID..."
  qm stop $VMID
  
  # Wait for VM to stop
  while qm status $VMID | grep -q "running"; do
    sleep 2
  done
fi

# Destroy VM
echo "Destroying VM $VMID..."
qm destroy $VMID

echo "VM $VMID deleted successfully."