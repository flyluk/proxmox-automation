#!/bin/bash

# Configuration
VMID=9000
TEMPLATE_NAME="ubuntu-24.04-template"
STORAGE="local-lvm"
BRIDGE="vmbr0"
IMAGE_FILE="/var/lib/vz/template/iso/noble-server-cloudimg-amd64.img"

echo "Creating cloud-init template $VMID..."

# Check if image exists
if [ ! -f "$IMAGE_FILE" ]; then
  echo "Error: Image file not found at $IMAGE_FILE"
  exit 1
fi

echo "Using Ubuntu 24.04 Noble cloud image: $IMAGE_FILE"

# Create VM
qm create $VMID --name $TEMPLATE_NAME --memory 8192 --cores 4 --net0 virtio,bridge=$BRIDGE

# Import disk
qm importdisk $VMID $IMAGE_FILE $STORAGE

# Set disk as scsi0
qm set $VMID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$VMID-disk-0

# Resize disk to 40GB
qm resize $VMID scsi0 +37G

# Add cloud-init drive
qm set $VMID --ide2 $STORAGE:cloudinit

# Configure cloud-init
qm set $VMID --ciuser flyluk
qm set $VMID --cipassword "!@Silver5b"
qm set $VMID --ipconfig0 ip=192.168.1.10/24,gw=192.168.1.1
qm set $VMID --nameserver "192.168.1.176 192.168.1.1"
qm set $VMID --searchdomain "test.local"
qm set $VMID --sshkeys ~/.ssh/authorized_keys

# Enable QEMU guest agent
qm set $VMID --agent enabled=1

# Use runcmd YAML for cloud-init
cat > /var/lib/vz/snippets/cloud-init-runcmd.yaml << 'EOF'
#cloud-config
runcmd:
  - apt update
  - apt install -y qemu-guest-agent snapd
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
  - snap install microk8s --classic
  - usermod -a -G microk8s flyluk
  - mkdir -p /home/flyluk/.kube
  - chown -R flyluk:flyluk /home/flyluk/.kube
EOF

# Set the cloud-init vendor data
qm set $VMID --cicustom "vendor=local:snippets/cloud-init-runcmd.yaml"

# Set boot order
qm set $VMID --boot c --bootdisk scsi0

# Add serial console
qm set $VMID --serial0 socket --vga serial0

# Start VM to verify cloud-init
echo "Starting VM to verify cloud-init setup..."
qm start $VMID

# Wait for VM to boot and cloud-init to complete
echo "Waiting for VM to boot and cloud-init to complete..."
sleep 60 # Wait time may vary depending on the environment

# Remove host key before verification
ssh-keygen -R 192.168.1.10 2>/dev/null

# Verify cloud-init status with retry
echo "Verifying cloud-init status..."
for i in {1..3}; do
  if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 flyluk@192.168.1.10 "cloud-init status --wait"; then
    break
  fi
  echo "Cloud-init verification attempt $i failed, retrying in 30 seconds..."
  [ $i -lt 3 ] && sleep 30
done

# Verify services installation with retry
echo "Verifying qemu-guest-agent and microk8s installation..."
for i in {1..3}; do
  if ssh -o StrictHostKeyChecking=no flyluk@192.168.1.10 "systemctl is-active qemu-guest-agent && microk8s status"; then
    break
  fi
  echo "Service verification attempt $i failed, retrying in 30 seconds..."
  [ $i -lt 3 ] && sleep 30
done

# Stop VM before converting to template
echo "Stopping VM before template conversion..."
qm stop $VMID

# Wait for VM to stop
while qm status $VMID | grep -q "running"; do
  sleep 2
done

# Convert to template
echo "Converting to template..."
qm template $VMID

# Cleanup
# Keep the original image file

echo "Template $VMID created successfully."