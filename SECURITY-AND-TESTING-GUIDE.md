# 🔐 Security & Testing - Complete Implementation Guide

This guide shows you how to use DhakaCart's security hardening and performance testing tools to ensure your application is **secure**, **stable**, and **performant**.

---

## 📁 Overview

You have **2 important directories**:

### 1. `/security` - Application Security
- **Network Policies** - Controls pod-to-pod communication
- **Vulnerability Scanning** - Finds security bugs in code and containers
- **SSL/TLS Setup** - HTTPS encryption automation

### 2. `/testing` - Performance Testing  
- **Load Testing** - Simulates real user traffic
- **Performance Benchmarks** - Measures response times

**Why you need these:**
- Production applications MUST be secure and tested
- Employers expect knowledge of security and testing
- 4-hour lab demos impress evaluators

---

## 🚀 Part 1: Security Implementation

### Step 1: Install Trivy (Vulnerability Scanner)

**On your local machine:**
```bash
# Install Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Verify
trivy --version
```

### Step 2: Scan Your Docker Images

```bash
cd ~/DhakaCart-03-test/security/scanning

# Run security scan
./trivy-scan.sh
```

**What this does:**
- Scans `arifhossaincse22/dhakacart-backend:latest`
- Scans `arifhossaincse22/dhakacart-frontend:latest`  
- Finds CRITICAL/HIGH/MEDIUM vulnerabilities
- Creates report in `/tmp/trivy-reports-<timestamp>/`

**Example Output:**
```
========================================
   DhakaCart Security Scan (Trivy)
========================================
Scanning: arifhossaincse22/dhakacart-backend:latest
  CRITICAL: 0
  HIGH: 2
  MEDIUM: 5
  LOW: 10

Reports saved to: /tmp/trivy-reports-20251207_100000/
```

**View detailed report:**
```bash
cat /tmp/trivy-reports-*/arifhossaincse22_dhakacart-backend_latest.txt
```

### Step 3: Check NPM Dependencies

```bash
cd ~/DhakaCart-03-test/security/scanning

# Check for vulnerable packages
./dependency-check.sh
```

**Output shows:**
- Backend vulnerabilities (from `package.json`)
- Frontend vulnerabilities
- Severity levels

**Fix vulnerabilities:**
```bash
# Backend
cd ~/DhakaCart-03-test/backend
npm audit fix

# Frontend  
cd ~/DhakaCart-03-test/frontend
npm audit fix
```

### Step 4: Apply Network Policies (Kubernetes)

**These policies block unauthorized access between pods.**

**SSH to Master-1 and run:**
```bash
cd ~/k8s

# Create a security directory
mkdir -p security/network-policies

# Copy policies (if not already synced)
# Files: frontend-policy.yaml, backend-policy.yaml, database-policy.yaml
```

**On local machine, add policies to k8s folder:**
```bash
cd ~/DhakaCart-03-test

# Copy network policies to k8s
cp -r security/network-policies k8s/security/

# Sync to Master
./scripts/k8s-deployment/sync-k8s-to-master1.sh
```

**On Master-1:**
```bash
cd ~/k8s/security/network-policies

# Apply policies
kubectl apply -f frontend-policy.yaml
kubectl apply -f backend-policy.yaml  
kubectl apply -f database-policy.yaml

# Verify
kubectl get networkpolicies -n dhakacart
```

**Expected Output:**
```
NAME                      POD-SELECTOR              AGE
dhakacart-frontend-policy   app=dhakacart-frontend    10s
dhakacart-backend-policy    app=dhakacart-backend     10s
dhakacart-database-policy   app=dhakacart-db          10s
```

### Step 5: Test Network Policies

**Verify frontend can reach backend (should work):**
```bash
kubectl exec -it -n dhakacart deployment/dhakacart-frontend -- curl -s http://dhakacart-backend-service:5000/health
```

**Verify database CANNOT reach internet (should fail):**
```bash
kubectl exec -it -n dhakacart deployment/dhakacart-db -- curl -m 5 https://google.com
# Expected: timeout
```

---

## 🧪 Part 2: Load Testing Implementation

### Step 1: Install K6 (Load Testing Tool)

**On your local machine (Ubuntu/WSL):**
```bash
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6

# Verify
k6 version
```

### Step 2: Run Load Tests

```bash
cd ~/DhakaCart-03-test/testing/load-tests

# Interactive mode (choose test type)
./run-load-test.sh

# Or specify your ALB URL
BASE_URL=http://dhakacart-k8s-alb-1190423189.ap-southeast-1.elb.amazonaws.com ./run-load-test.sh
```

**Test Options:**
1. **Smoke Test** - Quick 30-second check (2 users)
2. **Load Test** - Normal traffic (100 users, 10 mins)  
3. **Stress Test** - High load (500 users, 15 mins)
4. **Spike Test** - Sudden surge (1000 users, 5 mins)
5. **Endurance Test** - Long-term stability (50 users, 1 hour)

**Example: Run Smoke Test**
```
Select test type:
1) Smoke Test (Quick - 2 VUs, 30s)
2) Load Test (Normal - 100 VUs, 10m)
3) Stress Test (High - 500 VUs, 15m)
4) Spike Test (Burst - 1000 VUs, 5m)
5) Endurance Test (Long - 50 VUs, 1h)
6) Custom
Enter choice [1-6]: 1
```

### Step 3: Understand Results

**K6 Output Explanation:**
```
checks.........................: 98.50% ✓ 2955   ✗ 45  
http_req_duration..............: avg=145ms min=12ms med=98ms max=2.1s p(90)=280ms p(95)=450ms
http_req_failed................: 1.50%  ✓ 45    ✗ 2955
http_reqs......................: 3000   50/s
```

**What each metric means:**
- **checks**: 98.50% of tests passed ✅ (Good: >95%)
- **http_req_duration**: 
  - Average: 145ms
  - p(95): 450ms ← 95% of requests finished in <450ms ✅ (Goal: <2s)
- **http_req_failed**: 1.5% error rate ⚠️ (Goal: <1%)
- **http_reqs**: 50 requests/second

**Performance Goals:**

| Metric | ✅ Good | ⚠️ Acceptable | ❌ Poor |
|--------|---------|--------------|---------|
| p95 Response Time | <500ms | <1s | >1s |
| Error Rate | <0.1% | <1% | >1% |
| Requests/sec | >100 | >50 | <50 |

### Step 4: Monitor During Test

**While K6 is running**, open another terminal and SSH to Master-1:

```bash
# Watch pod resource usage
kubectl top pods -n dhakacart --watch

# Check pod status
kubectl get pods -n dhakacart -w
```

**Look for:**
- High CPU usage (>80%) - needs more replicas
- High memory (>80%) - increase limits
- Pod restarts - indicates crashes

---

## 📊 Part 3: Real-World Usage Scenarios

### Scenario 1: Before Production Deployment

**Run these checks:**
```bash
# 1. Security scan
cd ~/DhakaCart-03-test/security/scanning
./trivy-scan.sh
./dependency-check.sh

# 2. Apply network policies
kubectl apply -f ../network-policies/*.yaml

# 3. Run smoke test
cd ~/DhakaCart-03-test/testing/load-tests
BASE_URL=http://your-alb-url ./run-load-test.sh
# Select: 1 (Smoke Test)
```

**Acceptable criteria to proceed:**
- ✅ CRITICAL vulnerabilities = 0
- ✅ Network policies applied
- ✅ Smoke test >95% success rate

### Scenario 2: Performance Validation

**After deploying to production:**
```bash
# Run load test (normal traffic)
cd ~/DhakaCart-03-test/testing/load-tests
BASE_URL=http://your-production-url ./run-load-test.sh
# Select: 2 (Load Test)
```

**Monitor Grafana during test:**
1. Open `http://<ALB-DNS>/grafana`
2. Dashboard 1860 (Node Exporter)
3. Watch CPU/Memory graphs spike

**If performance is poor:**
- Add more replicas: `kubectl scale deployment/dhakacart-backend --replicas=5 -n dhakacart`
- Increase resources in `k8s/deployments/backend-deployment.yaml`

### Scenario 3: Security Audit for Presentation

**Demonstrate security knowledge:**
```bash
# 1. Show network policies
kubectl get networkpolicies -n dhakacart
kubectl describe networkpolicy dhakacart-backend-policy -n dhakacart

# 2. Show scanning results
cd ~/DhakaCart-03-test/security/scanning
./trivy-scan.sh
cat /tmp/trivy-reports-*/SUMMARY.txt

# 3. Test pod isolation
kubectl exec -it -n dhakacart deployment/dhakacart-db -- curl -m 5 https://google.com
# Should timeout - database can't reach internet!
```

---

## 🎯 Recommended Workflow (4-Hour Lab)

**Time-boxed implementation:**

### Hour 1-2: Infrastructure + Deployment ✅ (Already Done)
- Terraform infrastructure
- Kubernetes setup
- Application deployment

### Hour 3: Security Hardening (30 mins)
```bash
# 1. Quick security scan (5 mins)
cd ~/DhakaCart-03-test/security/scanning
./trivy-scan.sh

# 2. Apply network policies (10 mins)
cd ~/DhakaCart-03-test
cp -r security/network-policies k8s/security/
./scripts/k8s-deployment/sync-k8s-to-master1.sh

# On Master-1:
kubectl apply -f ~/k8s/security/network-policies/

# 3. Test policies (5 mins)
kubectl exec -it -n dhakacart deployment/dhakacart-frontend -- curl http://dhakacart-backend-service:5000/health
```

### Hour 3-4: Load Testing (30 mins)
```bash
# 1. Install K6 (10 mins - if not installed)
# Follow Step 1 above

# 2. Run smoke test (5 mins)
cd ~/DhakaCart-03-test/testing/load-tests
BASE_URL=http://<YOUR-ALB> ./run-load-test.sh
# Select: 1

# 3. Run load test (15 mins)
# Select: 2
```

---

## 🔧 Troubleshooting

### Issue 1: Trivy Not Found
```bash
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
```

### Issue 2: Network Policy Blocks Everything
```bash
# Check policies
kubectl get networkpolicies -n dhakacart

# Delete specific policy
kubectl delete networkpolicy dhakacart-backend-policy -n dhakacart

# Reapply correctly
kubectl apply -f ~/k8s/security/network-policies/backend-policy.yaml
```

### Issue 3: K6 Shows High Error Rate
**Possible causes:**
- ALB health checks failing
- Pods not ready
- Database connection issues

**Debug:**
```bash
# Check pod status
kubectl get pods -n dhakacart

# Check backend logs
kubectl logs -n dhakacart deployment/dhakacart-backend --tail=50

# Check database
kubectl exec -n dhakacart deployment/dhakacart-db -- psql -U dhakacart -d dhakacart_db -c "SELECT COUNT(*) FROM products;"
```

---

## 📚 Key Files Reference

### Security Files
```
security/
├── scanning/
│   ├── trivy-scan.sh          # Run: ./trivy-scan.sh
│   └── dependency-check.sh     # Run: ./dependency-check.sh
└── network-policies/
    ├── frontend-policy.yaml    # kubectl apply -f
    ├── backend-policy.yaml     # kubectl apply -f
    └── database-policy.yaml    # kubectl apply -f
```

### Testing Files
```
testing/
├── load-tests/
│   ├── k6-load-test.js        # K6 test script
│   └── run-load-test.sh        # Run: ./run-load-test.sh
└── performance/
    └── benchmark.sh            # Apache Bench tests
```

---

## 🎓 What You've Learned

After implementing security and testing, you can demonstrate:

✅ **Security:**
- Container vulnerability scanning
- Network segmentation with policies
- Dependency management
- Zero-trust architecture

✅ **Performance:**
- Load testing methodology
- Reading performance metrics
- Identifying bottlenecks
- Scaling strategies

✅ **DevOps Best Practices:**
- Continuous security scanning
- Performance benchmarking
- Monitoring under load
- Production readiness validation

---

## 💡 Quick Commands Cheat Sheet

```bash
# === SECURITY ===

# Scan containers
cd ~/DhakaCart-03-test/security/scanning && ./trivy-scan.sh

# Check dependencies
cd ~/DhakaCart-03-test/security/scanning && ./dependency-check.sh

# Apply network policies (on Master-1)
kubectl apply -f ~/k8s/security/network-policies/

# Test network isolation
kubectl exec -it -n dhakacart deployment/dhakacart-db -- curl -m 5 https://google.com

# === TESTING ===

# Run load test
cd ~/DhakaCart-03-test/testing/load-tests
BASE_URL=http://<YOUR-ALB-URL> ./run-load-test.sh

# Monitor during test (on Master-1)
kubectl top pods -n dhakacart --watch

# Check application health
kubectl get pods -n dhakacart
kubectl logs -n dhakacart deployment/dhakacart-backend --tail=50
```

---

## 🚀 Next Steps

1. **Add to deployment guide** - Update `Project-Deployment-Steps-(06-12-2025).md` with security phase
2. **CI/CD Integration** - Add Trivy scans to GitHub Actions
3. **Scheduled Testing** - Run weekly load tests automatically
4. **Alerting** - Set up alerts for high error rates in Grafana

---

**📝 Created:** 07 December 2025  
**🎯 Purpose:** Production-ready security and performance validation  
**⏱️ Time Required:** ~1 hour total (Security: 30min, Testing: 30min)

---

**🔐 Security + 🧪 Testing = 💪 Production-Ready Application!**
