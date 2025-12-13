# ✅ Post-Deployment Verification Guide

This guide provides a structured, step-by-step workflow to verify your **DhakaCart** deployment. Run these commands in order to ensure everything is running correctly.

## 🛠️ Phase 1: Setup & Access

Before running checks, ensure your `kubectl` is configured correctly. You can easily fetch the config from the cluster:

```bash
# 1. Fetch Kubeconfig (Automated Helper)
./scripts/fetch-kubeconfig.sh

# 2. Export Kubeconfig (Copy the output from the previous command)
export KUBECONFIG=$(pwd)/kubeconfig_fetched

# 3. Verify Cluster Access
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
kubectl get pods -n dhakacart -o wide

# 2. Inspect Deployments (READY column should match DESIRED)
kubectl get deployments -n dhakacart

# 3. Check StatefulSets (Important for Databases if not managed externally)
kubectl get statefulsets -n dhakacart
```

> **Tip:** If any pod is not running, use: `kubectl describe pod <pod-name> -n dhakacart`

---

## 🌐 Phase 4: Networking & External Access

Verify how the outside world connects to your services.

```bash
# 1. List all Services (Check ClusterIP and LoadBalancer IPs)
kubectl get svc -n dhakacart

# 2. Get the External IP/DNS of the Load Balancer (from Terraform output)
terraform -chdir=terraform/simple-k8s output load_balancer_dns
```

---

## 🗄️ Phase 5: Database & Storage Verification

Ensure the application can reach the database and cache.

### Psql Connectivity Check
```bash
# Check postgres logs to see if it started correctly
kubectl logs -l app=postgres -n dhakacart

# (Optional) Exec into a backend pod to test connection
# Replace <backend-pod-name> with an actual pod name
kubectl exec -it -n dhakacart <backend-pod-name> -- env | grep DB_
```

### Redis Connectivity Check
```bash
# Check Redis logs
kubectl logs -l app=redis -n dhakacart

# Ping Redis from inside the cluster
kubectl exec -it -n dhakacart $(kubectl get pod -l app=redis -n dhakacart -o jsonpath="{.items[0].metadata.name}") -- redis-cli ping
# Expected Output: PONG
```

---

## 🚀 Phase 6: Application Health Checks

Verify the actual application logic via HTTP requests.

### Backend Health Check
```bash
# Replace <ALB_DNS> with your Load Balancer DNS
curl -I http://<ALB_DNS>/api/health
# Expected: HTTP/1.1 200 OK
```

### Frontend Accessibility
```bash
# Simply curl the frontend URL
curl -I http://<ALB_DNS>
# Expected: HTTP/1.1 200 OK
```

---

## 🔍 Phase 7: Troubleshooting (If things go wrong)

If you find issues in the steps above, use these commands to debug.

```bash
# 1. View logs of a specific failing pod
kubectl logs <pod-name> -n dhakacart

# 2. View logs of the previous instance (if pod restarted)
kubectl logs <pod-name> -n dhakacart --previous

# 3. Describe pod to see events (Scheduling errors, ImagePullBackOff, etc.)
kubectl describe pod <pod-name> -n dhakacart

# 4. Check events in the namespace
kubectl get events -n dhakacart --sort-by='.lastTimestamp'
```
