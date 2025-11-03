# Fix Dashboard Queries for kube-prometheus-stack

## Problem
Dashboard queries use `kubernetes_node` label, but metrics use `instance` instead.

## Fixed Queries

### Disk Usage by Node
**Original (broken):**
```promql
sum(node_filesystem_size_bytes{kubernetes_node="microk8s-vm2"} - node_filesystem_avail_bytes{kubernetes_node="microk8s-vm2"}) by (kubernetes_node) / sum(node_filesystem_size_bytes{kubernetes_node="microk8s-vm2"}) by (kubernetes_node)
```

**Fixed:**
```promql
sum(node_filesystem_size_bytes{mountpoint="/"} - node_filesystem_avail_bytes{mountpoint="/"}) by (instance) / sum(node_filesystem_size_bytes{mountpoint="/"}) by (instance)
```

### Memory Usage by Node
**Fixed:**
```promql
(1 - sum(node_memory_MemAvailable_bytes) by (instance) / sum(node_memory_MemTotal_bytes) by (instance)) * 100
```

### CPU Usage by Node
**Fixed:**
```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

### All Nodes Disk Usage
**Fixed:**
```promql
sum(node_filesystem_size_bytes{mountpoint="/"} - node_filesystem_avail_bytes{mountpoint="/"}) / sum(node_filesystem_size_bytes{mountpoint="/"}) * 100
```

## Solution: Use Compatible Dashboards

Instead of fixing queries manually, use dashboards designed for kube-prometheus-stack:

### Import Dashboard 15760 (Best Option)
1. Go to Grafana: `kubectl port-forward -n monitoring svc/kube-prometheus-grafana 3000:80`
2. Click **+ → Import dashboard**
3. Enter ID: **15760**
4. Select **Prometheus** data source
5. Click **Import**

This dashboard uses correct label names and works out of the box.

### Other Compatible Dashboards:
- **15761** - Kubernetes / Views / Namespaces
- **15762** - Kubernetes / Views / Pods  
- **13770** - Kubernetes Cluster Monitoring
- **6417** - Kubernetes Cluster (Prometheus)

## Manual Fix for Existing Dashboard

If you want to fix dashboard 315:

1. Click dashboard title → **Edit**
2. For each panel showing N/A:
   - Click panel title → **Edit**
   - Replace `kubernetes_node` with `instance`
   - Replace `node` with `instance` (if needed)
   - Click **Apply**
3. Save dashboard

## Verify Metrics Work

Test in Prometheus:
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-kube-prome-prometheus 9090:9090
```

Open: http://localhost:9090

Try these queries:
```promql
node_memory_MemTotal_bytes
node_filesystem_size_bytes{mountpoint="/"}
rate(node_cpu_seconds_total[5m])
```

If they return data, the dashboards will work.
