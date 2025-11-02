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
- `add-gpu-to-vm.sh` - Adds NVIDIA GPU support to existing VM with Docker and NVIDIA Container Toolkit

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
- Stop VM if running
- Change VM machine type to q35
- Add GPU with PCI mapping (rombar disabled)
- Start VM and verify GPU presence
- Install NVIDIA drivers in VM
- Install Docker and NVIDIA Container Toolkit
- Test GPU in Docker container

## Requirements

- Proxmox VE 8.x (tested on Trixie)
- NVIDIA GPU with vGPU support
- Ubuntu 24.04 (Noble) for VMs
- SSH access to Proxmox host
- `sshpass` (automatically installed by scripts)
- `qemu-guest-agent` in VMs (included in cloud-init template)

## Usage

Make scripts executable:
```bash
chmod +x *.sh
```

Run scripts with appropriate parameters as documented in each file.

## Features

- **Automated Setup**: Complete Proxmox NVIDIA vGPU configuration in one command
- **Two-Phase Installation**: Handles reboots automatically with polling
- **PCI Mapping**: Automatic GPU detection and PCI device mapping
- **VM GPU Support**: Full GPU passthrough with driver and Docker installation
- **Error Handling**: Comprehensive validation and retry logic
- **Idempotent**: Safe to run multiple times, skips already completed steps