# 🔧 Fix Prometheus "No Data" in Grafana

**Issue**: Grafana dashboard shows "No data" even though Prometheus is healthy  
**Root Cause**: Prometheus not scraping node-exporter metrics correctly

---

## Problem Analysis

The Prometheus configuration for `kubernetes-nodes` job was trying to use Kubernetes API proxy method, which doesn't work well with node-exporter running as a DaemonSet with `hostNetwork: true`.

---

## Solution

Updated Prometheus configuration to scrape node-exporter pods directly via pod discovery instead of using Kubernetes API proxy.

---

## Fix Applied

### Updated Prometheus ConfigMap

Changed `kubernetes-nodes` job to:
- Discover node-exporter pods directly
- Use pod IP and port 9100
- Better label mapping

---

## Verification Steps

### 1. Check Prometheus Targets

```bash
# On Master-1
kubectl port-forward -n monitoring svc/prometheus-service 9090:9090

# Then open in browser:
# http://localhost:9090/prometheus/targets
```

**Expected**: All targets should show "UP"

### 2. Test Prometheus Queries

```bash
# On Master-1
PROM_POD=$(kubectl get pod -n monitoring -l app=prometheus-server -o jsonpath="{.items[0].metadata.name}")

# Test node metrics
kubectl exec -n monitoring $PROM_POD -- wget -q -O- 'http://localhost:9090/prometheus/api/v1/query?query=up{job="kubernetes-nodes"}' | grep -o '"value":\[[^]]*\]'
```

**Expected**: Should return metrics with values

### 3. Check Node Exporter Pods

```bash
kubectl get pods -n monitoring -l app=node-exporter
```

**Expected**: Should show pods on all nodes (3 pods for 3 nodes)

### 4. Verify Grafana Datasource

```bash
# Check datasource config
kubectl get configmap grafana-datasources -n monitoring -o yaml | grep -A 5 "url:"
```

**Should show:**
```yaml
url: http://prometheus-service.monitoring.svc.cluster.local:9090/prometheus/
```

---

## Apply the Fix

### Option 1: Using Script (Recommended)

```bash
# Update Prometheus config and restart
./scripts/update-prometheus-config.sh
```

### Option 2: Manual Update

**On Master-1:**

```bash
# Apply updated config
kubectl apply -f ~/k8s/monitoring/prometheus/configmap.yaml

# Restart Prometheus to pick up new config
kubectl rollout restart deployment/prometheus-deployment -n monitoring

# Wait for rollout
kubectl rollout status deployment/prometheus-deployment -n monitoring
```

---

## Restart Required Services

After updating Prometheus config:

```bash
# Restart Prometheus
kubectl rollout restart deployment/prometheus-deployment -n monitoring

# Wait for it to restart
kubectl rollout status deployment/prometheus-deployment -n monitoring

# Verify Prometheus is running
kubectl get pods -n monitoring -l app=prometheus-server
```

---

## Troubleshooting

### Issue: Still "No data" after fix

**Check:**

1. **Prometheus targets:**
   ```bash
   kubectl port-forward -n monitoring svc/prometheus-service 9090:9090
   # Open: http://localhost:9090/prometheus/targets
   ```
   - All targets should be "UP"
   - Check for any "DOWN" targets

2. **Node-exporter pods:**
   ```bash
   kubectl get pods -n monitoring -l app=node-exporter -o wide
   ```
   - Should be on all nodes
   - Status should be "Running"

3. **Prometheus logs:**
   ```bash
   PROM_POD=$(kubectl get pod -n monitoring -l app=prometheus-server -o jsonpath="{.items[0].metadata.name}")
   kubectl logs -n monitoring $PROM_POD --tail=50 | grep -i error
   ```

4. **Grafana datasource test:**
   - Go to Grafana → Configuration → Data Sources → Prometheus
   - Click "Save & Test"
   - Should show "Data source is working"

### Issue: Prometheus not restarting

```bash
# Force delete and recreate
kubectl delete pod -n monitoring -l app=prometheus-server
# Wait for new pod to start
kubectl get pods -n monitoring -l app=prometheus-server
```

---

## Common Queries to Test

After fix, test these queries in Prometheus:

```promql
# Node availability
up{job="kubernetes-nodes"}

# CPU usage
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage
100 * (1 - ((node_memory_MemAvailable_bytes) / (node_memory_MemTotal_bytes)))

# Disk usage
100 * (1 - (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}))
```

---

## Expected Results

After fix:

1. ✅ Prometheus targets show "UP"
2. ✅ Grafana datasource test passes
3. ✅ Dashboard shows metrics (not "No data")
4. ✅ CPU/Memory/Network panels display data

---

**Last Updated**: 2025-12-06  
**Status**: Configuration fixed, restart required

