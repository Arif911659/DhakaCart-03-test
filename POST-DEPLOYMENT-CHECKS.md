# ✅ Post-Deployment Verification Guide

This guide provides a structured, step-by-step workflow to verify your **DhakaCart** deployment. Run these commands in order to ensure everything is running correctly.

## 🛠️ Phase 1: Setup & Access

Before running checks, ensure your `kubectl` is configured correctly.

```bash
# 1. Export Kubeconfig (if not already set)
export KUBECONFIG=$(pwd)/kubeconfig_fetched

# 2. Verify Cluster Access
kubectl cluster-info
```

---

## 🏗️ Phase 2: Infrastructure & Node Status

Check if the underlying infrastructure is healthy.

```bash
# 1. Check all Nodes (Status should be Ready)
kubectl get nodes -o wide

# 2. Check if all Namespaces represent your expectation
kubectl get namespaces
```

---

## 📦 Phase 3: Workload Status (Pods & Deployments)

Verify that the application components are deployed and running.

```bash
# 1. Check all Pods in the default namespace (or your target namespace)
# Status should be 'Running' or 'Completed' (for jobs).
kubectl get pods -o wide

# 2. Inspect Deployments (READY column should match DESIRED)
kubectl get deployments

# 3. Check StatefulSets (Important for Databases if not managed externally)
kubectl get statefulsets
```

> **Tip:** If any pod is not running, use: `kubectl describe pod <pod-name>`

---

## 🌐 Phase 4: Networking & External Access

Verify how the outside world connects to your services.

```bash
# 1. List all Services (Check ClusterIP and LoadBalancer IPs)
kubectl get svc

# 2. Get the External IP/DNS of the Load Balancer (for frontend/ingress)
kubectl get svc -n ingress-nginx
# OR if you used a direct LoadBalancer service for frontend:
kubectl get svc frontend-service

# 3. Check Ingress resources (if applicable)
kubectl get ingress
```

---

## 🗄️ Phase 5: Database & Storage Verification

Ensure the application can reach the database and cache.

### Psql Connectivity Check
```bash
# Check postgres logs to see if it started correctly
kubectl logs -l app=postgres

# (Optional) Exec into a backend pod to test connection
# Replace <backend-pod-name> with an actual pod name
kubectl exec -it <backend-pod-name> -- env | grep DB_
```

### Redis Connectivity Check
```bash
# Check Redis logs
kubectl logs -l app=redis

# Ping Redis from inside the cluster
kubectl exec -it $(kubectl get pod -l app=redis -o jsonpath="{.items[0].metadata.name}") -- redis-cli ping
# Expected Output: PONG
```

---

## 🚀 Phase 6: Application Health Checks

Verify the actual application logic via HTTP requests.

### Backend Health Check
```bash
# Replace <EXTERNAL-IP> with your LoadBalancer IP or Localhost port
curl -I http://<EXTERNAL-IP>/api/health
# Expected: HTTP/1.1 200 OK
```

### Frontend Accessibility
```bash
# Simply curl the frontend URL
curl -I http://<EXTERNAL-IP>
# Expected: HTTP/1.1 200 OK
```

---

## 🔍 Phase 7: Troubleshooting (If things go wrong)

If you find issues in the steps above, use these commands to debug.

```bash
# 1. View logs of a specific failing pod
kubectl logs <pod-name>

# 2. View logs of the previous instance (if pod restarted)
kubectl logs <pod-name> --previous

# 3. Describe pod to see events (Scheduling errors, ImagePullBackOff, etc.)
kubectl describe pod <pod-name>

# 4. Check events in the namespace
kubectl get events --sort-by='.lastTimestamp'
```
