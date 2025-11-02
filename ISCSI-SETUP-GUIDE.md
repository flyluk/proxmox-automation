# iSCSI Storage Setup Guide for Kubernetes

## Prerequisites

### On Storage Server (Proxmox/TrueNAS)
1. **ZFS pool configured**
   ```bash
   # Check existing pools
   zpool list
   
   # Create dataset for Kubernetes
   zfs create pool/k8s
   zfs create pool/k8s/iscsi
   zfs create pool/k8s/iscsi-snapshots
   ```

2. **iSCSI target service enabled**
   - Proxmox: Install `targetcli` or use TrueNAS VM
   - TrueNAS: Enable iSCSI service in UI

3. **API access configured**
   - Create API user with storage permissions
   - Note the IP, username, and password

### On Kubernetes Nodes
1. **Install iSCSI initiator tools**
   ```bash
   # Run on ALL MicroK8s nodes
   sudo apt update
   sudo apt install -y open-iscsi
   sudo systemctl enable --now iscsid
   ```

## Installation Steps

### Step 1: Run Setup Script
```bash
./setup-iscsi-storage.sh
```
This creates `democratic-csi-iscsi-values.yaml`

### Step 2: Edit Configuration
```bash
nano democratic-csi-iscsi-values.yaml
```

**Update these values:**
```yaml
httpConnection:
  host: 192.168.1.100              # Your storage server IP
  username: root                    # API username
  password: your-password           # API password

zfs:
  datasetParentName: tank/k8s/iscsi  # Your ZFS path

iscsi:
  targetPortal: "192.168.1.100:3260"  # Storage server IP:3260
```

### Step 3: Install Democratic CSI
```bash
helm install democratic-csi-iscsi \
  democratic-csi/democratic-csi \
  -n democratic-csi \
  -f democratic-csi-iscsi-values.yaml
```

### Step 4: Verify Installation
```bash
# Check pods
kubectl get pods -n democratic-csi

# Check StorageClass
kubectl get storageclass

# Check CSI driver
kubectl get csidrivers
```

## Usage Example

### Create PVC
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-storage
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: iscsi-storage
  resources:
    requests:
      storage: 10Gi
```

### Use in Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: my-app-storage
```

## What Happens Automatically

1. **PVC Created** → CSI driver receives request
2. **API Call** → Creates ZFS dataset on storage server
3. **iSCSI Target** → Creates and configures iSCSI target
4. **Node Connection** → Kubernetes node connects via iSCSI
5. **Volume Mount** → Formatted and mounted to pod

## Troubleshooting

### Check CSI Driver Logs
```bash
kubectl logs -n democratic-csi -l app=democratic-csi-controller
```

### Verify iSCSI Connection on Node
```bash
# SSH to node
sudo iscsiadm -m session
sudo iscsiadm -m node
```

### Check ZFS Datasets
```bash
# On storage server
zfs list -r pool/k8s/iscsi
```

## Benefits

- **Dynamic Provisioning**: No manual volume creation
- **Snapshots**: Built-in snapshot support
- **Expansion**: Resize volumes without downtime
- **Multi-node**: ReadWriteMany with NFS mode
- **ZFS Features**: Compression, deduplication, snapshots
