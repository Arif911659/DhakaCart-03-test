# 🚀 DhakaCart - Complete Deployment Guide (06-12-2025)

This is the **Master Step-by-Step Guide** to deploying the entire **DhakaCart** e-commerce platform from scratch on AWS with Kubernetes. Follow these steps sequentially for a successful deployment.

---

## 📋 Prerequisites

Before starting, ensure you have:
- ✅ AWS Account with CLI configured (`aws configure`)
- ✅ Terraform installed (`terraform --version`)
- ✅ Git repository cloned locally
- ✅ SSH client (for accessing EC2 instances)

---

## 🏗️ Phase 1: Infrastructure Provisioning (AWS)

### Step 1.1: Navigate to Terraform Directory
```bash
cd ~/DhakaCart-03-test/terraform/simple-k8s
```

### Step 1.2: Initialize Terraform
```bash
terraform init
```
*This downloads required AWS providers and prepares the Terraform workspace.*

### Step 1.3: Deploy Infrastructure
```bash
terraform apply -auto-approve
```

**What this creates:**
- 1 VPC with public and private subnets
- 1 Bastion Host (Jump server)
- 2 Master Nodes (for HA control plane)
- 3 Worker Nodes (for application workloads)
- 1 Application Load Balancer (ALB)
- Security Groups and IAM roles
- SSH Key Pair (`dhakacart-k8s-key.pem`)

**⏱️ Duration:** ~5-8 minutes

### Step 1.4: Save Important Outputs
```bash
terraform output
```

**Note down:**
- `bastion_public_ip` - for SSH access
- `load_balancer_dns` - for accessing the application
- `master_private_ips` - Master node IPs
- `worker_private_ips` - Worker node IPs

**Example Output:**
```
load_balancer_dns = "dhakacart-k8s-alb-1190423189.ap-southeast-1.elb.amazonaws.com"
bastion_public_ip = "54.169.237.62"
```

---

## ☸️ Phase 2: Kubernetes Cluster Setup (Kubeadm)

### Step 2.1: Copy SSH Key to Bastion
```bash
scp -i dhakacart-k8s-key.pem dhakacart-k8s-key.pem ubuntu@<BASTION_IP>:~/.ssh/
```

### Step 2.2: SSH to Master-1 (via Bastion)
```bash
# First, SSH to Bastion
ssh -i dhakacart-k8s-key.pem ubuntu@<BASTION_IP>

# From Bastion, SSH to Master-1
ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@<MASTER1_PRIVATE_IP>
```

### Step 2.3: Initialize Kubernetes Cluster on Master-1
```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

**⏱️ Duration:** ~2-3 minutes

### Step 2.4: Setup kubectl Configuration
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Step 2.5: Install Flannel Network Plugin
```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

### Step 2.6: Join Worker Nodes

**On Master-1**, generate the join command:
```bash
kubeadm token create --print-join-command
```

**Copy the output** (example):
```
kubeadm join 10.0.10.128:6443 --token abc123.xyz --discovery-token-ca-cert-hash sha256:...
```

**Exit Master-1** and SSH to **each Worker Node** (Worker-1, Worker-2, Worker-3):
```bash
# From Bastion
ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@<WORKER_IP>

# Run the join command with sudo
sudo kubeadm join 10.0.10.128:6443 --token abc123.xyz --discovery-token-ca-cert-hash sha256:...

# Exit and repeat for other workers
exit
```

### Step 2.7: Verify Cluster
**Back on Master-1:**
```bash
kubectl get nodes
```

**Expected Output:**
```
NAME       STATUS   ROLES           AGE   VERSION
master-1   Ready    control-plane   5m    v1.28.0
worker-1   Ready    <none>          2m    v1.28.0
worker-2   Ready    <none>          2m    v1.28.0
worker-3   Ready    <none>          2m    v1.28.0
```

---

## 📦 Phase 3: Application Deployment (Automated)

### Step 3.1: Return to Local Machine
Exit from Bastion/Master and return to your local machine where the project is cloned.

### Step 3.2: Update ConfigMap with ALB DNS
**Edit the ConfigMap:**
```bash
cd ~/DhakaCart-03-test
nano k8s/configmaps/app-config.yaml
```

**Update this line** with your actual ALB DNS (from Phase 1):
```yaml
REACT_APP_API_URL: http://<YOUR_ALB_DNS>/api
```

**Example:**
```yaml
REACT_APP_API_URL: http://dhakacart-k8s-alb-1190423189.ap-southeast-1.elb.amazonaws.com/api
```

Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X`).

### Step 3.3: Sync Files to Master-1
```bash
./scripts/k8s-deployment/sync-k8s-to-master1.sh
```

**This script:**
- Copies the entire `k8s/` directory to Bastion
- Forwards it to Master-1
- Places files in `~/k8s/` on Master-1

**⏱️ Duration:** ~30 seconds

### Step 3.4: Deploy Application (On Master-1)

**SSH back to Master-1:**
```bash
ssh -i terraform/simple-k8s/dhakacart-k8s-key.pem ubuntu@<BASTION_IP>
ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@<MASTER1_IP>
```

**Run the deployment script:**
```bash
cd ~/k8s
chmod +x deploy-prod.sh
./deploy-prod.sh
```

**This automated script:**
1. ✅ Creates namespaces (`dhakacart`, `monitoring`)
2. ✅ Applies Secrets and ConfigMaps
3. ✅ Creates PersistentVolumes for Database and Redis
4. ✅ Deploys PostgreSQL Database
5. ✅ Deploys Redis Cache
6. ✅ Deploys Backend API (3 replicas)
7. ✅ Deploys Frontend (2 replicas)
8. ✅ Seeds Database automatically (if empty)
9. ✅ Deploys Prometheus + Grafana + Loki + Promtail
10. ✅ Applies Ingress rules

**⏱️ Duration:** ~3-5 minutes

### Step 3.5: Verify Deployment
```bash
# Check all pods
kubectl get pods -n dhakacart

# Check services
kubectl get svc -n dhakacart

# Check monitoring pods
kubectl get pods -n monitoring
```

**All pods should show `Running` status.**

---

## 🌐 Phase 4: ALB Configuration & Access

### Step 4.1: Register Worker Nodes to ALB

**Return to your local machine** and run:
```bash
cd ~/DhakaCart-03-test/terraform/simple-k8s
./register-workers-to-alb.sh
```

**This script:**
- Finds all Worker Instance IDs
- Registers them to Frontend Target Group (Port 30080)
- Registers them to Backend Target Group (Port 30081)
- Waits for health checks

**⏱️ Duration:** ~1-2 minutes

**Expected Output:**
```
✅ Registered i-xxxxx to Frontend TG
✅ Registered i-xxxxx to Backend TG
...
🎉 Registration Complete!
```

### Step 4.2: Access the Application

**Wait 2-3 minutes** for ALB health checks to pass, then open in browser:

**Frontend:**
```
http://<YOUR_ALB_DNS>
```

**Example:**
```
http://dhakacart-k8s-alb-1190423189.ap-southeast-1.elb.amazonaws.com
```

You should see the DhakaCart homepage with products!

---

## 📊 Phase 5: Monitoring & Observability

### Step 5.1: Access Grafana

**Grafana URL:**
```
http://<YOUR_ALB_DNS>/grafana/
```

**Login Credentials:**
- Username: `admin`
- Password: `dhakacart123`

### Step 5.2: Import Dashboard for Metrics

1. Click **Dashboards** (left menu) → **New** → **Import**
2. Enter Dashboard ID: `1860`
3. Click **Load**
4. Select **Prometheus** as Data Source
5. Click **Import**

**You can now see:**
- ✅ Real-time CPU/Memory usage
- ✅ Network I/O
- ✅ Disk usage
- ✅ Pod health status

### Step 5.3: Access Prometheus (Optional)

**Prometheus URL:**
```
http://<YOUR_ALB_DNS>/prometheus/
```

Use for raw metrics and custom queries.

### Step 5.4: View Logs (Loki - if configured)

1. Go to **Explore** (compass icon)
2. Select **Loki** datasource
3. Add label filter: `namespace` = `dhakacart`
4. Click **Run query**

---

## 🔧 Troubleshooting

### Issue 1: Frontend shows "Cannot load products"
**Solution:**
- Verify `REACT_APP_API_URL` in ConfigMap (Step 3.2)
- Check Backend pods: `kubectl get pods -n dhakacart | grep backend`
- Restart Frontend: `kubectl rollout restart deployment/dhakacart-frontend -n dhakacart`

### Issue 2: Database is empty
**Solution:**
```bash
kubectl exec -i -n dhakacart deployment/dhakacart-db -- psql -U dhakacart -d dhakacart_db < ~/k8s/../database/init.sql
```

### Issue 3: ALB shows 503 error
**Solution:**
- Re-run: `./register-workers-to-alb.sh`
- Check Target Health in AWS Console

---

## 🚀 Popular Grafana Dashboards

Import these for enhanced monitoring:

### Cluster Monitoring
- **315** - Kubernetes cluster monitoring
- **1860** - Node Exporter Full ⭐ (Recommended)
- **6417** - Kubernetes Cluster
- **8588** - Deployment/StatefulSet metrics

### Node/Pod Metrics
- **6781** - Node Exporter Dashboard
- **13332** - Kubernetes Global View
- **13473** - Cluster Monitoring

### Application Specific
- **12486** - PostgreSQL Database
- **11835** - Redis Dashboard
- **7362** - NGINX Ingress

---

## 🎯 Quick Reference Commands

### On Local Machine
```bash
# Sync files to Master
./scripts/k8s-deployment/sync-k8s-to-master1.sh

# Register ALB targets
cd terraform/simple-k8s && ./register-workers-to-alb.sh

# Get ALB DNS
terraform output load_balancer_url
```

### On Master-1 (via SSH)
```bash
# Check all resources
kubectl get all -n dhakacart
kubectl get all -n monitoring

# View logs
kubectl logs -n dhakacart deployment/dhakacart-backend --tail=50
kubectl logs -n dhakacart deployment/dhakacart-frontend --tail=50

# Restart deployments
kubectl rollout restart deployment/dhakacart-backend -n dhakacart
kubectl rollout restart deployment/dhakacart-frontend -n dhakacart
```

---

## 📝 Summary of Automated vs Manual Steps

### ✅ Fully Automated by Scripts
- Namespace creation
- All Kubernetes manifests application
- Database seeding (conditional)
- Monitoring stack deployment
- ConfigMap application

### ⚙️ Manual Steps Required
1. Run `terraform apply`
2. Initialize Kubernetes with `kubeadm init`
3. Join worker nodes
4. Update ALB DNS in ConfigMap
5. Run `sync` script
6. Run `deploy-prod.sh` on Master
7. Run `register-workers-to-alb.sh`

---

**Total Deployment Time:** ~20-30 minutes (from scratch)

**Prepared by:** Antigravity AI  
**Last Updated:** 06 December 2025  
**Version:** 1.0
