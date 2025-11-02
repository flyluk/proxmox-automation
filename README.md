# Proxmox Automation Scripts

Collection of bash scripts for automating Proxmox VE operations including VM creation, template management, and SSH key deployment.

## Scripts

### Setup Scripts
- `setup-proxmox.sh` - Complete Proxmox setup with NVIDIA vGPU support (includes SSH key setup, repository configuration, driver installation, and PCI mapping)
- `copy_ssh_keys.sh` - Copies SSH keys to target system with password authentication
- `download-files.sh` - Downloads required Ubuntu cloud image and NVIDIA driver

### VM Management Scripts
- `create-template.sh` - Creates Ubuntu 24.04 cloud-init template with MicroK8s
- `create-single-vm.sh` - Creates single VM from template
- `create-microk8s-vms.sh` - Creates multiple MicroK8s VMs
- `delete-single-vm.sh` - Deletes single VM
- `remove-microk8s-vms.sh` - Removes multiple VMs
- `add-gpu-to-vm.sh` - Adds NVIDIA GPU support to existing VM

## Quick Start

### 1. Setup Proxmox with NVIDIA vGPU
```bash
./setup-proxmox.sh <host> <user> <password>
```
This script will:
- Copy SSH keys for passwordless access
- Configure Proxmox repositories (remove subscription, add no-subscription)
- Update and upgrade system
- Install NVIDIA vGPU driver
- Configure PCI mapping for GPU
- Reboot and verify installation

### 2. Add GPU to VM
```bash
./add-gpu-to-vm.sh <vmid>
```
This script will:
- Change VM machine type to q35
- Add GPU with PCI mapping
- Start VM and verify GPU presence

## Usage

Make scripts executable:
```bash
chmod +x *.sh
```

Run scripts with appropriate parameters as documented in each file.