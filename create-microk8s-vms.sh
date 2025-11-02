#!/bin/bash

# Template ID and storage
TEMPLATE_ID=9000
STORAGE="local-lvm"
BRIDGE="vmbr0"
SSH_USER="flyluk"

# VM definitions
declare -A VMS=(
  [9101]="microk8s-vm1"
  [9102]="microk8s-vm2"
  [9103]="microk8s-vm3"
  [9104]="microk8s-vm4"
  [9105]="microk8s-vm5"
  [9106]="microk8s-vm6"
)

declare -A IPs=(
  [9101]="192.168.1.11"
  [9102]="192.168.1.12"
  [9103]="192.168.1.13"
  [9104]="192.168.1.14"
  [9105]="192.168.1.15"
  [9106]="192.168.1.16"
)



# Create and start VMs
for VMID in "${!VMS[@]}"; do
  HOSTNAME="${VMS[$VMID]}"
  IP="${IPs[$VMID]}"

  echo "Creating VM $VMID ($HOSTNAME)..."
  qm clone $TEMPLATE_ID $VMID --name $HOSTNAME
  qm set $VMID \
    --memory 8192 \
    --cores 4 \
    --net0 virtio,bridge=$BRIDGE \
    --ipconfig0 ip=$IP/24,gw=192.168.1.1 \
    --ciuser $SSH_USER \
    --cipassword "!@Silver5b"  \
    --searchdomain test.local \
    --nameserver 192.168.1.176
  qm resize $VMID scsi0 +40G
  qm start $VMID
done

# Wait for VMs to boot
echo "Waiting 60 seconds for VMs to initialize..."
sleep 60

# Wait for MicroK8s to be ready (installed via cloud-init)
echo "Waiting for MicroK8s to be ready on all nodes..."
for VMID in "${!VMS[@]}"; do
  IP="${IPs[$VMID]}"
  echo "Waiting for MicroK8s on ${IP}..."
  ssh -o StrictHostKeyChecking=no "${SSH_USER}@${IP}" "sudo snap remove microk8s && sudo snap install microk8s --classic && sudo microk8s status --wait-ready"
done

# Join workers to master
JOIN_CMD=$(ssh -o StrictHostKeyChecking=no "${SSH_USER}@${IPs[9101]}" "microk8s add-node --token-ttl 3600 | grep 'microk8s join' | head -n 1")

for VMID in 9102 9103 9104 9105 9106; do
  echo "Joining ${IPs[$VMID]} to cluster..."
  ssh -o StrictHostKeyChecking=no "${SSH_USER}@${IPs[$VMID]}" "$JOIN_CMD --worker"
done

# Verify cluster
echo "Cluster nodes:"
ssh -o StrictHostKeyChecking=no "${SSH_USER}@${IPs[9101]}" "microk8s kubectl get nodes"

# Remove ubuntu-24 node if it exists
echo "Removing ubuntu-24 node if present..."
ssh -o StrictHostKeyChecking=no "${SSH_USER}@${IPs[9101]}" "microk8s kubectl delete node ubuntu-24 --ignore-not-found=true"