# 🔧 Fix Database Products Issue

**Problem**: Frontend loads but no products are displayed  
**Likely Causes**: 
1. Database doesn't have products (not seeded)
2. Backend can't connect to database
3. Frontend API URL is incorrect

---

## Quick Fix Steps

### Step 1: Diagnose the Issue

```bash
./scripts/diagnose-db-products-issue.sh
```

This will check:
- ✅ Database pod status
- ✅ Products table exists
- ✅ Product count in database
- ✅ Backend pod status and logs
- ✅ API connectivity
- ✅ Frontend ConfigMap

### Step 2: Seed Database (if no products)

If diagnostic shows `PRODUCT_COUNT = 0`:

```bash
./scripts/seed-database.sh
```

This will:
- ✅ Create tables if they don't exist
- ✅ Insert 15 sample products
- ✅ Clear Redis cache
- ✅ Restart backend pods

### Step 3: Update ALB DNS (if ConfigMap has placeholder)

If diagnostic shows ConfigMap has placeholder URL:

```bash
./scripts/update-alb-dns-dynamic.sh
```

---

## Manual Fix (Alternative)

### Check Database Products

**On Master-1:**

```bash
# Get database pod
DB_POD=$(kubectl get pod -l app=dhakacart-db -n dhakacart -o jsonpath="{.items[0].metadata.name}")

# Check product count
kubectl exec -n dhakacart $DB_POD -- psql -U dhakacart -d dhakacart_db -c "SELECT COUNT(*) FROM products;"

# If count is 0, seed database
kubectl exec -i -n dhakacart $DB_POD -- psql -U dhakacart -d dhakacart_db < /path/to/database/init.sql
```

### Check Backend Logs

```bash
# Get backend pod
BACKEND_POD=$(kubectl get pod -l app=dhakacart-backend -n dhakacart -o jsonpath="{.items[0].metadata.name}")

# Check logs
kubectl logs -n dhakacart $BACKEND_POD --tail=50
```

Look for:
- Database connection errors
- "Error fetching products" messages
- Redis connection issues

### Check Frontend ConfigMap

```bash
# Check API URL
kubectl get configmap dhakacart-config -n dhakacart -o jsonpath='{.data.REACT_APP_API_URL}'

# Should show actual ALB DNS, not placeholder
```

### Test Backend API

```bash
# Test from inside cluster
kubectl run -i --rm --restart=Never test-api --image=curlimages/curl:latest -n dhakacart -- \
  curl http://dhakacart-backend-service:5000/api/products

# Test from worker node (replace WORKER_IP)
curl http://<WORKER_IP>:30081/api/products
```

---

## Common Issues & Solutions

### Issue 1: Database Empty (No Products)

**Symptom**: Diagnostic shows `PRODUCT_COUNT = 0`

**Solution**:
```bash
./scripts/seed-database.sh
```

**Or manually**:
```bash
# On Master-1, copy init.sql first
# Then:
DB_POD=$(kubectl get pod -l app=dhakacart-db -n dhakacart -o jsonpath="{.items[0].metadata.name}")
kubectl exec -i -n dhakacart $DB_POD -- psql -U dhakacart -d dhakacart_db < ~/init.sql
```

### Issue 2: Backend Can't Connect to Database

**Symptom**: Backend logs show connection errors

**Check**:
```bash
# Verify database service
kubectl get svc dhakacart-db-service -n dhakacart

# Verify ConfigMap
kubectl get configmap dhakacart-config -n dhakacart -o yaml | grep DB_HOST

# Should show: DB_HOST: "dhakacart-db-service"
```

**Solution**: Restart backend pods
```bash
kubectl rollout restart deployment/dhakacart-backend -n dhakacart
```

### Issue 3: Frontend API URL Wrong

**Symptom**: Frontend shows but can't fetch products, browser console shows API errors

**Check**:
```bash
kubectl get configmap dhakacart-config -n dhakacart -o yaml | grep REACT_APP_API_URL
```

**Solution**:
```bash
# Update with current ALB DNS
./scripts/update-alb-dns-dynamic.sh
```

### Issue 4: Products Table Doesn't Exist

**Symptom**: Diagnostic shows table doesn't exist

**Solution**:
```bash
# Seed database (creates tables)
./scripts/seed-database.sh
```

---

## Verification

After fixing, verify:

### 1. Database has products
```bash
DB_POD=$(kubectl get pod -l app=dhakacart-db -n dhakacart -o jsonpath="{.items[0].metadata.name}")
kubectl exec -n dhakacart $DB_POD -- psql -U dhakacart -d dhakacart_db -c "SELECT COUNT(*) FROM products;"
```
**Expected**: Count > 0

### 2. Backend API works
```bash
# Get ALB DNS
cd terraform/simple-k8s
ALB_DNS=$(terraform output -raw load_balancer_dns)

# Test API
curl http://$ALB_DNS/api/products | jq '.data | length'
```
**Expected**: JSON with products array

### 3. Frontend loads products
- Open browser: `http://ALB_DNS`
- Check browser console (F12) for errors
- Products should be visible

---

## Quick Checklist

- [ ] Run diagnostic script
- [ ] If no products → Run seed-database.sh
- [ ] If ConfigMap has placeholder → Run update-alb-dns-dynamic.sh
- [ ] Check backend logs for errors
- [ ] Restart backend pods after seeding
- [ ] Clear Redis cache
- [ ] Test API endpoint
- [ ] Verify in browser

---

**Last Updated**: 2025-12-06

