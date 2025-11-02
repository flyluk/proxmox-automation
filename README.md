# Proxmox Automation Scripts

Collection of bash scripts for automating Proxmox VE operations including VM creation, template management, and SSH key deployment.

## Scripts

- `create-template.sh` - Creates Ubuntu 24.04 cloud-init template with MicroK8s
- `create-single-vm.sh` - Creates single VM from template
- `create-microk8s-vms.sh` - Creates multiple MicroK8s VMs
- `delete-single-vm.sh` - Deletes single VM
- `remove-microk8s-vms.sh` - Removes multiple VMs
- `copy_ssh_keys.sh` - Copies SSH keys to target system with retry logic

## Usage

Make scripts executable:
```bash
chmod +x *.sh
```

Run scripts with appropriate parameters as documented in each file.