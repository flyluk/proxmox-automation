# K8s Health Monitoring Dashboard

## Access OpenSearch Dashboards
```bash
kubectl port-forward -n opensearch svc/opensearch-dashboards 5601:5601
```
Open: http://localhost:5601 (Login: admin / Strong_password1)

## Create Index Pattern
1. Go to **Management** → **Index Patterns**
2. Create pattern: `fluent-bit*`
3. Time field: `@timestamp`

## Dashboard Visualizations

### 1. Pod Restart Count (Line Chart)
- **Visualize** → **Line**
- Y-axis: **Count**
- X-axis: **Date Histogram** (`@timestamp`)
- Filter: `log: *restart* OR log: *Restarting*`
- Split Series: `kubernetes.pod_name`

### 2. Error Logs by Namespace (Pie Chart)
- **Visualize** → **Pie**
- Slice: **Terms** aggregation on `kubernetes.namespace_name`
- Filter: `log: *error* OR log: *ERROR* OR log: *failed*`

### 3. Pod Status (Data Table)
- **Visualize** → **Data Table**
- Buckets:
  - **Terms**: `kubernetes.namespace_name`
  - **Terms**: `kubernetes.pod_name`
  - **Terms**: `stream` (stdout/stderr)
- Metrics: **Count**

### 4. Node Resource Alerts (Metric)
- **Visualize** → **Metric**
- Filter: `log: *OOM* OR log: *memory* OR log: *disk*`
- Metric: **Count**

### 5. Container Crash Loop (Line Chart)
- **Visualize** → **Line**
- Y-axis: **Count**
- X-axis: **Date Histogram**
- Filter: `log: *CrashLoopBackOff* OR log: *Back-off*`
- Split Series: `kubernetes.pod_name`

### 6. Failed Scheduling (Data Table)
- **Visualize** → **Data Table**
- Filter: `log: *FailedScheduling* OR log: *Insufficient*`
- Buckets: **Terms** on `kubernetes.pod_name`

### 7. Image Pull Errors (Metric)
- **Visualize** → **Metric**
- Filter: `log: *ImagePullBackOff* OR log: *ErrImagePull*`
- Metric: **Count**

### 8. Liveness/Readiness Probe Failures (Line Chart)
- **Visualize** → **Line**
- Filter: `log: *Liveness* OR log: *Readiness* OR log: *probe failed*`
- Y-axis: **Count**
- X-axis: **Date Histogram**

## Create Dashboard
1. **Dashboard** → **Create dashboard**
2. **Add** each visualization
3. Arrange in grid:
   - Top row: Error count, Pod restarts, Crash loops
   - Middle: Error logs by namespace, Pod status table
   - Bottom: Failed scheduling, Image pull errors, Probe failures
4. **Save** as: `K8s Health Monitor`

## Add Filters
- Time range: Last 15 minutes (auto-refresh: 10s)
- Namespace filter
- Pod name filter
- Log level filter

## Alerts (Optional)
Create alerts for:
- Error count > 100 in 5 minutes
- Pod restarts > 5 in 10 minutes
- CrashLoopBackOff detected
