# Recommended Grafana Dashboards for kube-prometheus-stack

## Import These Dashboards

Access Grafana: `kubectl port-forward -n monitoring svc/kube-prometheus-grafana 3000:80`

Go to: **+ → Import dashboard**

### Best Dashboards for Your Setup:

1. **Dashboard 6417** - Kubernetes Cluster (Prometheus)
   - Works perfectly with kube-prometheus-stack
   - Shows: CPU, Memory, Network, Disk
   - Import ID: `6417`

2. **Dashboard 15760** - Kubernetes / Views / Global
   - Modern, clean interface
   - Cluster-wide overview
   - Import ID: `15760`

3. **Dashboard 15761** - Kubernetes / Views / Namespaces
   - Per-namespace metrics
   - Import ID: `15761`

4. **Dashboard 15762** - Kubernetes / Views / Pods
   - Per-pod metrics
   - Import ID: `15762`

5. **Dashboard 13770** - Kubernetes Cluster Monitoring
   - Simple and effective
   - Import ID: `13770`

## Import Steps:

1. Click **+ → Import dashboard**
2. Enter dashboard ID (e.g., `6417`)
3. Click **Load**
4. Select **Prometheus** as data source
5. Click **Import**

## If Metrics Show N/A:

Check if metrics are available:
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-kube-prome-prometheus 9090:9090
```

Open: http://localhost:9090

Try queries:
- `node_memory_MemTotal_bytes`
- `container_memory_usage_bytes`
- `kube_pod_info`

If queries return data, the dashboard query might be wrong. Use dashboard **6417** or **15760** instead.
