# Hybrid Storage Setup Guide

## Why Use Both?

Different workloads need different storage types:

| Storage Type | Access Mode | Best For | Performance |
|--------------|-------------|----------|-------------|
| **Proxmox CSI** | ReadWriteOnce (RWO) | Databases, single-pod apps | ⭐⭐⭐⭐⭐ Fast |
| **NFS** | ReadWriteMany (RWX) | Shared files, multi-pod apps | ⭐⭐⭐ Good |

## Quick Setup

```bash
# Get Proxmox API token first:
# Datacenter → Permissions → API Tokens → Add
# User: root@pam, Token ID: k8s

./setup-hybrid-storage.sh proxmox.test.local "PVEAPIToken=root@pam!k8s=xxx-xxx-xxx"
```

This creates:
- `proxmox-rwo` (default) - Fast block storage for databases
- `nfs-rwx` - Shared storage for files

## Usage Examples

### Example 1: PostgreSQL Database (RWO)
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: proxmox-rwo  # Fast block storage
  resources:
    requests:
      storage: 20Gi
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:16
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
        env:
        - name: POSTGRES_PASSWORD
          value: password
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: postgres-data
```

### Example 2: WordPress (RWX for shared uploads)
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: wordpress-uploads
spec:
  accessModes:
    - ReadWriteMany  # Multiple pods can access
  storageClassName: nfs-rwx  # Shared NFS storage
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
spec:
  replicas: 3  # Multiple replicas sharing same storage
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      containers:
      - name: wordpress
        image: wordpress:latest
        volumeMounts:
        - name: uploads
          mountPath: /var/www/html/wp-content/uploads
      volumes:
      - name: uploads
        persistentVolumeClaim:
          claimName: wordpress-uploads
```

### Example 3: Application with Both Storage Types
```yaml
# Fast database storage (RWO)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-database
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: proxmox-rwo
  resources:
    requests:
      storage: 10Gi
---
# Shared file storage (RWX)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-shared-files
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs-rwx
  resources:
    requests:
      storage: 5Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: myapp:latest
        volumeMounts:
        - name: db-data
          mountPath: /data/db
        - name: shared
          mountPath: /data/shared
      volumes:
      - name: db-data
        persistentVolumeClaim:
          claimName: app-database
      - name: shared
        persistentVolumeClaim:
          claimName: app-shared-files
```

## Decision Matrix

### Use Proxmox CSI (RWO) for:
- ✅ Databases (PostgreSQL, MySQL, MongoDB)
- ✅ Redis, Elasticsearch
- ✅ Single-pod applications
- ✅ High I/O workloads
- ✅ When performance is critical

### Use NFS (RWX) for:
- ✅ Shared file uploads (WordPress, Nextcloud)
- ✅ Log aggregation
- ✅ CI/CD artifacts
- ✅ Multi-pod deployments needing same data
- ✅ Static website content
- ✅ Backup storage

## Default Storage Class

The setup makes `proxmox-rwo` the default. If you don't specify `storageClassName`, it uses Proxmox CSI.

To use NFS, explicitly set:
```yaml
storageClassName: nfs-rwx
```

## Verification

```bash
# Check storage classes
kubectl get storageclass

# Should show:
# NAME                    PROVISIONER              RECLAIMPOLICY   VOLUMEBINDINGMODE
# proxmox-rwo (default)   csi.proxmox.sinextra.dev Delete          WaitForFirstConsumer
# nfs-rwx                 nfs.csi.k8s.io           Delete          Immediate

# Test RWO storage
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-rwo
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: proxmox-rwo
  resources:
    requests:
      storage: 1Gi
EOF

# Test RWX storage
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-rwx
spec:
  accessModes: [ReadWriteMany]
  storageClassName: nfs-rwx
  resources:
    requests:
      storage: 1Gi
EOF

# Check PVCs
kubectl get pvc
```

## Troubleshooting

### Proxmox CSI Issues
```bash
# Check CSI pods
kubectl get pods -n csi-proxmox

# Check logs
kubectl logs -n csi-proxmox -l app=proxmox-csi-controller
```

### NFS Issues
```bash
# Check NFS CSI pods
kubectl get pods -n kube-system -l app=csi-driver-nfs

# Test NFS mount from node
ssh microk8s-vm1.test.local
showmount -e proxmox.test.local
```

## Benefits of Hybrid Approach

1. **Performance**: Fast block storage for databases
2. **Flexibility**: Shared storage when needed
3. **Cost-effective**: Use appropriate storage for each workload
4. **Scalability**: Scale apps independently of storage type
5. **Best practices**: Match storage to workload requirements

## Migration Between Storage Types

You can't directly convert RWO to RWX or vice versa. To migrate:

```bash
# 1. Create new PVC with desired storage class
# 2. Copy data between PVCs
kubectl run -it --rm copy --image=alpine --restart=Never -- sh
# Inside pod, mount both PVCs and copy data
# 3. Update application to use new PVC
```
