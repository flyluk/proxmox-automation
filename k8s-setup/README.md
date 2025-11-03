# Kubernetes Monitoring Setup

Complete observability stack for Kubernetes with Grafana (metrics) and OpenSearch (logs).

## Quick Start

### 1. Install Metrics Collection (Prometheus + Grafana)
```bash
./install-metrics-exporter.sh
```

Access Grafana:
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-grafana 3000:80
```
Login: `admin` / Get password with:
```bash
kubectl get secret -n monitoring kube-prometheus-grafana -o jsonpath='{.data.admin-password}' | base64 -d
```

### 2. Install Log Collection (OpenSearch + Fluent Bit)
```bash
./install-opensearch-helm.sh
./install-fluent-bit.sh
```

Access OpenSearch Dashboards:
```bash
kubectl port-forward -n opensearch svc/opensearch-dashboards 5601:5601
```
Login: `admin` / `Strong_password1`

## Architecture

```
K8s Cluster
├── Prometheus → Grafana (CPU/RAM/Network metrics)
└── Fluent Bit → OpenSearch (Application logs)
```

## Grafana Dashboards

Import pre-built dashboards:
1. Go to **+ → Import dashboard**
2. Enter dashboard ID:
   - **15760** - Kubernetes / Views / Global (recommended)
   - **15761** - Kubernetes / Views / Namespaces
   - **15762** - Kubernetes / Views / Pods
   - **6417** - Kubernetes Cluster (Prometheus)
   - **13770** - Kubernetes Cluster Monitoring
3. Select **Prometheus** as data source
4. Click **Import**

See: `recommended-dashboards.md` for details

## OpenSearch Dashboards

Create index pattern for logs:
1. Go to **Management → Index Patterns**
2. Create pattern: `fluent-bit*`
3. Time field: `@timestamp`
4. Go to **Discover** to view logs

See: `create-log-visualizations.md` for dashboard creation

## Useful Queries

### PromQL (Grafana)

**CPU Usage:**
```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**Memory Usage:**
```promql
(1 - sum(node_memory_MemAvailable_bytes) by (instance) / sum(node_memory_MemTotal_bytes) by (instance)) * 100
```

**Disk Usage:**
```promql
(1 - sum(node_filesystem_avail_bytes{mountpoint="/"}) by (instance) / sum(node_filesystem_size_bytes{mountpoint="/"}) by (instance)) * 100
```

**Pod CPU Requests:**
```promql
sum(kube_pod_container_resource_requests{resource="cpu"}) / sum(kube_node_status_allocatable{resource="cpu"}) * 100
```

**Pod Memory Requests:**
```promql
sum(kube_pod_container_resource_requests{resource="memory"}) / sum(kube_node_status_allocatable{resource="memory"}) * 100
```

### Lucene (OpenSearch)

**Error logs:**
```
log: *error* OR log: *ERROR* OR log: *failed*
```

**Pod restarts:**
```
log: *restart* OR log: *Restarting*
```

**Crash loops:**
```
log: *CrashLoopBackOff* OR log: *Back-off*
```

## Troubleshooting

### Grafana shows N/A
- Check Prometheus is running: `kubectl get pods -n monitoring | grep prometheus`
- Verify data source: Grafana → Configuration → Data Sources → Prometheus
- Use compatible dashboards (15760, 6417, 13770)

### OpenSearch logs not appearing
- Check Fluent Bit: `kubectl get pods -n kube-system -l app.kubernetes.io/name=fluent-bit`
- Check logs: `kubectl logs -n kube-system -l app.kubernetes.io/name=fluent-bit --tail=20`
- Verify index exists: OpenSearch → Management → Index Patterns

### SSL Errors in Logs
- Harmless - services are working
- To reduce: `./reduce-opensearch-ssl-errors.sh`

## Scripts

| Script | Purpose |
|--------|---------|
| `install-metrics-exporter.sh` | Install Prometheus + Grafana |
| `install-opensearch-helm.sh` | Install OpenSearch |
| `install-fluent-bit.sh` | Install log collector |
| `setup-grafana-datasource.sh` | Configure Prometheus data source |
| `import-k8s-dashboards.sh` | Import Grafana dashboards |
| `fix-grafana-dashboards.sh` | Get Grafana password |
| `disable-prometheus-remote-write.sh` | Stop Prometheus → OpenSearch |

## Documentation

- `opensearch-vs-grafana-comparison.md` - Which tool to use
- `k8s-metrics-dashboard-guide.md` - Grafana setup guide
- `k8s-health-dashboard-guide.md` - Health monitoring
- `recommended-dashboards.md` - Best Grafana dashboards
- `fix-dashboard-queries.md` - Fix query errors

## Access URLs

```bash
# Grafana (metrics)
kubectl port-forward -n monitoring svc/kube-prometheus-grafana 3000:80
# http://localhost:3000

# OpenSearch Dashboards (logs)
kubectl port-forward -n opensearch svc/opensearch-dashboards 5601:5601
# http://localhost:5601

# Prometheus (raw metrics)
kubectl port-forward -n monitoring svc/kube-prometheus-kube-prome-prometheus 9090:9090
# http://localhost:9090
```

## Cleanup

```bash
# Remove monitoring
helm uninstall kube-prometheus -n monitoring
kubectl delete namespace monitoring

# Remove logging
helm uninstall opensearch -n opensearch
helm uninstall fluent-bit -n kube-system
kubectl delete namespace opensearch
```
