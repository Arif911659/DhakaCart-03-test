# 🚀 4-Hour Deployment Guide

Complete deployment automation for AWS 4-hour access windows.

---

## Quick Start (One Command)

```bash
cd ~/DhakaCart-03-test
./scripts/deploy-4-hour-window.sh
```

**This single script will:**
1. ✅ Deploy infrastructure (Terraform)
2. ✅ Configure Kubernetes cluster
3. ✅ Deploy application
4. ✅ Setup monitoring
5. ✅ Register ALB targets
6. ✅ Verify everything

**Estimated Time:** ~25-35 minutes

---

## What Happens Step-by-Step

### [1/7] Infrastructure (5-8 mins)
- Terraform creates VPC, EC2 instances, ALB
- Generates SSH keys
- Outputs configuration

### [2/7] Configuration (1 min)
- Loads IPs from Terraform
- Updates all scripts with dynamic values

### [3/7] Node Scripts (1 min)
- Generates node configuration scripts
- Updates with current IPs

### [4/7] Cluster Setup (10-15 mins)
- Uploads scripts to Bastion
- Configures Master-1 (kubeadm init)
- Joins Worker nodes in parallel

### [5/7] Application (5-7 mins)
- Updates ConfigMap with ALB DNS
- Syncs manifests to Master-1
- Runs deploy-prod.sh
- Seeds database

### [6/7] ALB Registration (2 mins)
- Registers workers to target groups
- Waits for health checks

### [7/7] Verification (1 min)
- Checks nodes status
- Verifies pods running
- Displays access URLs

---

## Prerequisites

Before running, ensure:

1. **AWS Credentials** configured:
   ```bash
   aws configure
   ```

2. **Terraform** installed:
   ```bash
   terraform --version
   ```

3. **In project root**:
   ```bash
   cd ~/DhakaCart-03-test
   ```

---

## Manual Step-by-Step (If Needed)

If automation fails, run manually:

### Step 1: Infrastructure
```bash
cd terraform/simple-k8s
terraform init
terraform apply
```

### Step 2: Configure Nodes
```bash
cd nodes-config-steps
./automate-node-config.sh
```

### Step 3: SSH to Bastion
```bash
ssh -i ../dhakacart-k8s-key.pem ubuntu@<BASTION_IP>
```

### Step 4: Configure Master-1
```bash
ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@<MASTER1_IP>
cd ~/nodes-config
bash master-1.sh
```

### Step 5: Get Join Command
```bash
kubeadm token create --print-join-command
```

### Step 6: Join Workers
```bash
# On each worker
ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@<WORKER_IP>
cd ~/nodes-config
bash workers-prereq.sh
sudo <JOIN_COMMAND_FROM_STEP_5>
```

### Step 7: Deploy Application
```bash
# On local machine
cd ~/DhakaCart-03-test
./scripts/k8s-deployment/sync-k8s-to-master1.sh

# On Master-1
cd ~/k8s
./deploy-prod.sh
```

### Step 8: Register ALB
```bash
# On local machine
cd terraform/simple-k8s
./register-workers-to-alb.sh
```

---

## After Deployment

### Access Application
```bash
# Get ALB DNS
cd terraform/simple-k8s
terraform output load_balancer_dns

# Open in browser
http://<ALB_DNS>
http://<ALB_DNS>/grafana/
```

### Verify Everything
```bash
# SSH to Master-1
kubectl get nodes
kubectl get pods -n dhakacart
kubectl get pods -n monitoring

# Test frontend
curl -I http://<ALB_DNS>

# Test backend
curl http://<ALB_DNS>/api/health
```

### Run Security Hardening (Optional)
```bash
cd ~/DhakaCart-03-test
./scripts/security/apply-security-hardening.sh
```

### Deploy Alerting (Optional)
```bash
./scripts/monitoring/deploy-alerting-stack.sh
```

---

## Troubleshooting

### Script Fails at Infrastructure Step
**Error:** Terraform apply fails

**Solution:**
```bash
cd terraform/simple-k8s
terraform destroy
terraform apply
```

### Script Fails at Node Configuration
**Error:** Cannot SSH to Bastion

**Solution:**
```bash
# Check security group allows your IP
aws ec2 describe-security-groups

# Try manual SSH
ssh -i terraform/simple-k8s/dhakacart-k8s-key.pem ubuntu@<BASTION_IP>
```

### Nodes Not Joining
**Error:** Workers fail to join cluster

**Solution:**
```bash
# On Master-1, generate new token
kubeadm token create --print-join-command

# On worker, run manually
sudo <NEW_JOIN_COMMAND>
```

### Application Not Accessible
**Error:** ALB shows 503

**Solution:**
```bash
# Re-register targets
cd terraform/simple-k8s
./register-workers-to-alb.sh

# Wait 2-3 minutes for health checks
```

---

## Time Optimization Tips

**To complete in <30 minutes:**

1. **Run during off-peak hours** - Better AWS performance
2. **Use larger instance types** - Faster node initialization
3. **Skip optional steps** initially:
   - Security hardening (add later)
   - Alerting setup (add later)
4. **Run verification in parallel** - Check pods while ALB registers

---

## Cleanup (End of Session)

```bash
cd ~/DhakaCart-03-test/terraform/simple-k8s
terraform destroy -auto-approve
```

**Estimated Time:** ~5 minutes

---

## Quick Commands Reference

```bash
# Full deployment
./scripts/deploy-4-hour-window.sh

# Just infrastructure
cd terraform/simple-k8s && terraform apply

# Just application
./scripts/k8s-deployment/sync-k8s-to-master1.sh
# Then on Master-1: cd ~/k8s && ./deploy-prod.sh

# Just ALB registration
cd terraform/simple-k8s && ./register-workers-to-alb.sh

# Full cleanup
cd terraform/simple-k8s && terraform destroy
```

---

**Last Updated:** 07 December 2025  
**Target:** <30 minutes full deployment  
**Success Rate:** Optimized for AWS 4-hour windows
