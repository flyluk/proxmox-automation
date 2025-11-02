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

# Stop VM if running
if qm status $VMID | grep -q "running"; then
    echo "VM $VMID is running. Stopping it..."
    qm stop $VMID
    sleep 5
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
sleep 10

echo "Verifying GPU in VM..."

# Verify GPU with lspci using qemu-guest-agent
if qm guest exec $VMID --timeout 60 -- lspci 2>/dev/null | grep -i nvidia; then
    echo "GPU successfully detected in VM"
    
    # Install NVIDIA driver in VM
    echo "Installing NVIDIA driver in VM..."
    qm guest exec $VMID --timeout 600 -- bash -c "apt update && apt install -y ubuntu-drivers-common && ubuntu-drivers install"
    
    echo "NVIDIA driver installation completed"
    echo "Rebooting VM to load driver..."
    qm reboot $VMID
    
    sleep 30
    
    # Verify driver installation
    echo "Verifying NVIDIA driver..."
    if qm guest exec $VMID --timeout 60 -- bash -c "lsmod | grep -i nvidia" 2>/dev/null; then
        echo "NVIDIA driver loaded successfully"
        
        # Install nvidia-utils for nvidia-smi
        echo "Installing nvidia-utils..."
        qm guest exec $VMID --timeout 300 -- bash -c "apt install -y nvidia-utils-*"
        
        # Verify nvidia-smi
        if qm guest exec $VMID --timeout 60 -- nvidia-smi 2>/dev/null; then
            echo "nvidia-smi working successfully"
        fi
        
        # Install Docker
        echo "Installing Docker..."
        qm guest exec $VMID --timeout 600 -- bash -c "apt install -y ca-certificates curl && install -m 0755 -d /etc/apt/keyrings && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && chmod a+r /etc/apt/keyrings/docker.asc && echo 'deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable' > /etc/apt/sources.list.d/docker.list && apt update && apt install -y docker-ce docker-ce-cli containerd.io"
        
        # Add current user to docker group
        echo "Adding user to docker group..."
        qm guest exec $VMID --timeout 60 -- bash -c "usermod -aG docker \$(logname 2>/dev/null || echo \$SUDO_USER || whoami)"
        
        # Install NVIDIA Container Toolkit
        echo "Installing NVIDIA Container Toolkit..."
        qm guest exec $VMID --timeout 600 -- bash -c "curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' > /etc/apt/sources.list.d/nvidia-container-toolkit.list && apt update && apt install -y nvidia-container-toolkit && nvidia-ctk runtime configure --runtime=docker && systemctl restart docker"
        
        echo "Docker and NVIDIA Container Toolkit installed successfully"
        echo "Testing GPU in Docker..."
        qm guest exec $VMID --timeout 120 -- docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi
    else
        echo "WARNING: nvidia-smi not available. Driver may need manual verification."
    fi
else
    echo "WARNING: GPU not detected in VM. Make sure qemu-guest-agent is installed."
fi
