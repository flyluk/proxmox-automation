#!/bin/bash

# Usage: ./setup-proxmox.sh <host> <user> <password>

if [ $# -ne 3 ]; then
    echo "Usage: $0 <host> <user> <password>"
    exit 1
fi

HOST=$1
USER=$2
PASS=$3

# Install sshpass if not available
if ! command -v sshpass &> /dev/null; then
    echo "Installing sshpass..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y sshpass
    elif command -v yum &> /dev/null; then
        sudo yum install -y sshpass
    else
        echo "Cannot install sshpass. Please install manually."
        exit 1
    fi
fi

# Remove known_hosts entry for the target host
ssh-keygen -R "$HOST" 2>/dev/null

# Copy SSH keys
echo "Copying SSH keys..."
sshpass -p "$PASS" scp -o StrictHostKeyChecking=no ~/.ssh/id_rsa ~/.ssh/id_rsa.pub "$USER@$HOST:~/.ssh/"
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no "$USER@$HOST" "cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys"

echo "SSH keys copied and authorized_keys updated on $USER@$HOST"

# SSH into target system and setup
ssh -o StrictHostKeyChecking=no "$USER@$HOST" << 'EOF'
# Remove subscription repositories
for file in /etc/apt/sources.list.d/*.list; do
    if [ -f "$file" ] && grep -q "enterprise\|subscription" "$file"; then
        sed -i 's/^deb/#deb/' "$file"
    fi
done

for file in /etc/apt/sources.list.d/*.sources; do
    if [ -f "$file" ] && grep -q "enterprise\|subscription" "$file"; then
        sed -i 's/^/#/' "$file"
    fi
done

# Remove any ceph repository files
rm -f /etc/apt/sources.list.d/*ceph*

# Add no-subscription repositories
echo "deb http://download.proxmox.com/debian/pve trixie pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list

# Update and upgrade system
apt update && apt upgrade -y

# Install git and build tools
apt install -y git build-essential gcc make

PHASE_FILE="/root/.proxmox-setup-phase"

if [ ! -f "$PHASE_FILE" ]; then
    echo "Phase 1: Initial setup"
    
    mkdir -p /root/development
    cd /root/development
    if [ ! -d proxmox-automation ]; then
        git clone https://github.com/flyluk/proxmox-automation.git
    fi
    cd proxmox-automation
    
    # Download files if they don't exist
    if [ ! -f /var/lib/vz/template/iso/noble-server-cloudimg-amd64.img ] || [ ! -f NVIDIA-Linux-x86_64-580.95.05.run ]; then
        chmod +x download-files.sh
        ./download-files.sh
    fi
    
    # Move image file if it exists and destination doesn't have it
    if [ -f noble-server-cloudimg-amd64.img ] && [ ! -f /var/lib/vz/template/iso/noble-server-cloudimg-amd64.img ]; then
        mkdir -p /var/lib/vz/template/iso
        mv noble-server-cloudimg-amd64.img /var/lib/vz/template/iso/
    fi
    mkdir -p /var/lib/vz/snippets
    cp cloud-init-runcmd.yaml /var/lib/vz/snippets/
    
    # Install required packages for NVIDIA driver
    apt install -y dkms proxmox-default-headers
    
    # Setup NVIDIA vGPU helper
    if [ -f NVIDIA-Linux-x86_64-580.95.05.run ]; then
        pve-nvidia-vgpu-helper setup NVIDIA-Linux-x86_64-580.95.05.run
    fi
    
    # Check if NVIDIA driver is already installed and map PCI if so
    if command -v nvidia-smi &> /dev/null; then
        echo "NVIDIA driver detected, configuring PCI mapping..."
        for pci in $(lspci -nn | grep -i nvidia | grep -i vga | awk '{print $1}'); do
            pci_id=$(lspci -n -s $pci | awk '{print $3}')
            screbsys_vendor=$(cat /sys/bus/pci/devices/0000:$pci/subsystem_vendor | sed 's/0x//')
            subsys_device=$(cat /sys/bus/pci/devices/0000:$pci/subsystem_device | sed 's/0x//')
            subsys_id="${subsys_vendor}:${subsys_device}"
            iommu_group=$(basename $(readlink /sys/bus/pci/devices/0000:$pci/iommu_group))
            node=$(hostname)
            echo "Found NVIDIA GPU at $pci (ID: $pci_id, Subsystem: $subsys_id, IOMMU Group: $iommu_group)"
            pvesh create /cluster/mapping/pci --id nvidia-gpu --map "id=$pci_id,iommugroup=$iommu_group,node=$node,path=0000:$pci,subsystem-id=$subsys_id" --description "NVIDIA GPU" 2>/dev/null || \
            pvesh set /cluster/mapping/pci/nvidia-gpu --map "id=$pci_id,iommugroup=$iommu_group,node=$node,path=0000:$pci,subsystem-id=$subsys_id" --description "NVIDIA GPU"
        done
        echo "PCI mapping completed in phase 1"
        echo "2" > "$PHASE_FILE"
        echo "Setup completed successfully"
        exit 0
    fi
    
    # Mark phase 1 complete and setup phase 2
    echo "1" > "$PHASE_FILE"
    
    # Create phase 2 script
    cat > /root/setup-phase2.sh << 'PHASE2'
#!/bin/bash
cd /root/development/proxmox-automation

# Check if NVIDIA driver is already installed
if command -v nvidia-smi &> /dev/null; then
    echo "NVIDIA driver already installed"
    nvidia-smi
else
    echo "Installing NVIDIA driver..."
    if [ -f NVIDIA-Linux-x86_64-580.95.05.run ]; then
        chmod +x NVIDIA-Linux-x86_64-580.95.05.run
        ./NVIDIA-Linux-x86_64-580.95.05.run --silent --no-questions --ui=none
        
        # Verify installation
        if command -v nvidia-smi &> /dev/null; then
            nvidia-smi
            echo "NVIDIA driver installed successfully"
        else
            echo "ERROR: NVIDIA driver installation failed"
            exit 1
        fi
    else
        echo "ERROR: NVIDIA driver file not found"
        exit 1
    fi
fi

# Add PCI mapping for NVIDIA GPU
echo "Configuring PCI mapping for NVIDIA GPU..."
for pci in $(lspci -nn | grep -i nvidia | grep -i vga | awk '{print $1}'); do
    pci_id=$(lspci -n -s $pci | awk '{print $3}')
    subsys_vendor=$(cat /sys/bus/pci/devices/0000:$pci/subsystem_vendor | sed 's/0x//')
    subsys_device=$(cat /sys/bus/pci/devices/0000:$pci/subsystem_device | sed 's/0x//')
    subsys_id="${subsys_vendor}:${subsys_device}"
    iommu_group=$(basename $(readlink /sys/bus/pci/devices/0000:$pci/iommu_group))
    node=$(hostname)
    echo "Found NVIDIA GPU at $pci (ID: $pci_id, Subsystem: $subsys_id, IOMMU Group: $iommu_group)"
    pvesh create /cluster/mapping/pci --id nvidia-gpu --map "id=$pci_id,iommugroup=$iommu_group,node=$node,path=0000:$pci,subsystem-id=$subsys_id" --description "NVIDIA GPU" 2>/dev/null || \
    pvesh set /cluster/mapping/pci/nvidia-gpu --map "id=$pci_id,iommugroup=$iommu_group,node=$node,path=0000:$pci,subsystem-id=$subsys_id" --description "NVIDIA GPU"
done

echo "2" > /root/.proxmox-setup-phase
rm /root/setup-phase2.sh
PHASE2
    chmod +x /root/setup-phase2.sh
    
    echo "Phase 1 completed. Rebooting in 5 seconds..."
    sleep 5
    reboot
else
    echo "Setup already completed or in progress"
fi
EOF

# Wait for server to go down
echo "Waiting for server to go down..."
sleep 10

# Poll for server to come back up
echo "Waiting for server to come back up..."
while ! ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$USER@$HOST" "echo 1" &>/dev/null; do
    echo "Server not ready yet, waiting..."
    sleep 5
done

echo "Server is back up. Running phase 2..."
ssh -o StrictHostKeyChecking=no "$USER@$HOST" "/root/setup-phase2.sh"

echo "All phases completed successfully"