#!/bin/bash

# Defaults
MEMORY_GB=8
CORES=4
DISK_SIZE="40G"

# Parse options
while [[ $# -gt 0 ]]; do
  case $1 in
    --vid|-v)
      VMID="$2"
      shift 2
      ;;
    --ip|-i)
      IP="$2"
      shift 2
      ;;
    -n|--name)
      HOSTNAME="$2"
      shift 2
      ;;
    -c|--cores)
      CORES="$2"
      shift 2
      ;;
    -m|--memory)
      MEMORY_GB="$2"
      shift 2
      ;;
    -dz|--disk-size)
      DISK_SIZE="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 --vid <vmid> --ip <ip> -n <hostname> [-c cores] [-m memory_gb] [-dz disk_size]"
      echo "Example: $0 --vid 9107 --ip 192.168.1.17 -n test-vm -c 4 -m 16 -dz 40G"
      echo "Defaults: memory=8GB, cores=4, disk_size=40G"
      exit 0
      ;;
    *)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

# Check required parameters
if [[ -z "$VMID" || -z "$IP" || -z "$HOSTNAME" ]]; then
  echo "Error: Missing required parameters"
  echo "Usage: $0 --vid <vmid> --ip <ip> -n <hostname> [-c cores] [-m memory_gb] [-dz disk_size]"
  exit 1
fi

# Convert GB to MB for qm
MEMORY=$((MEMORY_GB * 1024))

# Configuration
TEMPLATE_ID=9000
BRIDGE="vmbr0"
SSH_USER="flyluk"

echo "Creating VM $VMID ($HOSTNAME) with IP $IP, ${MEMORY_GB}GB RAM, $CORES cores, +$DISK_SIZE disk..."

qm clone $TEMPLATE_ID $VMID --name $HOSTNAME
qm set $VMID \
  --memory $MEMORY \
  --cores $CORES \
  --net0 virtio,bridge=$BRIDGE \
  --ipconfig0 ip=$IP/24,gw=192.168.1.1 \
  --ciuser $SSH_USER \
  --cipassword "!@Silver5b" \
  --searchdomain test.local \
  --nameserver 192.168.1.176
qm resize $VMID scsi0 +$DISK_SIZE
qm start $VMID

echo "VM $VMID created and started successfully."