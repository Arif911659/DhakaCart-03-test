# DhakaCart Kubernetes Deployment Guide

Complete step-by-step guide for deploying DhakaCart e-commerce application on AWS using Terraform and Kubernetes.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Phase 1: Infrastructure Setup (Terraform)](#phase-1-infrastructure-setup-terraform)
- [Phase 2: Automated Deployment (Recommended)](#phase-2-automated-deployment-recommended)
- [Phase 3: Kubernetes Cluster Setup (Manual Config)](#phase-3-kubernetes-cluster-setup-manual-config)
- [Phase 4: Application Deployment](#phase-4-application-deployment)
- [Phase 5: Monitoring Setup](#phase-5-monitoring-setup)
- [Phase 6: Security Hardening](#phase-6-security-hardening)
- [Phase 7: Verification](#phase-7-verification)
- [Phase 8: Enterprise Features](#phase-8-enterprise-features)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools

- ✅ **Terraform** (v1.0+): `terraform --version`
- ✅ **AWS CLI** (v2.0+): `aws --version`
- ✅ **jq**: `jq --version`
- ✅ **SSH client**: `ssh -V`

### AWS Credentials

Ensure AWS credentials are configured:
```bash
aws configure
# Or set environment variables:
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-southeast-1"
```

### Project Structure

```
DhakaCart-03-test/
├── terraform/simple-k8s/        # Infrastructure as Code
├── scripts/                      # Automation scripts
├── k8s/                          # Kubernetes manifests
├── frontend/                     # React frontend application
├── backend/                      # Node.js backend API
└── docs/                         # Documentation
```


---

## Phase 1: Infrastructure Setup (Terraform)

### Step 1.1: Navigate to Terraform Directory

```bash
cd /home/arif/DhakaCart-03-test/terraform/simple-k8s
```

### Step 1.2: Initialize Terraform

```bash
terraform init
```

### Step 1.3: Review Infrastructure Plan

```bash
terraform plan
```

**Review**: Check that the plan includes:
- 1 Bastion host (public subnet)
- 2 Master nodes (private subnet)
- 3 Worker nodes (private subnet)
- 1 Application Load Balancer
- VPC, subnets, security groups

### Step 1.4: Apply Terraform Configuration

```bash
terraform apply
```

**Confirmation**: Type `yes` when prompted

**Duration**: ~5-10 minutes

### Step 1.5: Save Terraform Outputs

```bash
terraform output > infrastructure-outputs.txt
```

**Important**: Keep this file for reference!

---

## Phase 2: Automated Deployment (Recommended)

### Step 2.1: Run the Master Deployment Script

We now use a single, resumable script that handles Infrastructure, Config, Node Setup, App Deployment, Seeding, and Enterprise Features.

```bash
cd /home/arif/DhakaCart-03-test
./scripts/deploy-full-stack.sh
```

**Features:**
- **Auto-Resume**: If it fails, run it again; it picks up where it left off.
- **Automated Seeding**: No need to run seeding scripts manually.
- **Full Stack**: Deploys Infra + K8s + App + Monitoring.
- **Enterprise Ready**: Installs Velero, Vault, and Cert-Manager automatically.

**Expected Time**: ~25-30 minutes.

---

## Phase 3: Kubernetes Cluster Setup (Manual Fallback)

*Only follow this phase if you are NOT using the master script above.*

### Step 3.1: Config Nodes
Use the scripts in `scripts/nodes-config/` to generate and propagate kubeadm commands.

### Step 3.2: Deploy Kubernetes Cluster

```bash
cd ../../scripts/k8s-deployment
./update-and-deploy.sh
```

This script will:
1. Copy K8s manifests to Master-1
2. Apply all Kubernetes configurations
3. Deploy application pods
4. Configure monitoring stack

**Duration**: ~5-10 minutes

### Step 3.3: Verify Cluster Status

SSH to Master-1 and check:

```bash
ssh -i ../../terraform/simple-k8s/dhakacart-k8s-key.pem ubuntu@<BASTION_IP>
ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@<MASTER1_IP>

# Check nodes
kubectl get nodes
```

---

## Phase 4: Application Deployment

### Step 4.1: Register Workers to ALB
(Automated by `deploy-full-stack.sh`. If manual:)
```bash
cd /home/arif/DhakaCart-03-test/terraform/simple-k8s
./register-workers-to-alb.sh
```

**Expected**: All workers registered and healthy

### Step 4.2: Seed Database (Automated)

This is handled automatically by the master script.
If you need to re-seed manually:
```bash
cd ../../scripts
./scripts/database/seed-database.sh --automated
```

### Step 4.3: Access Application

**Frontend**: http://\<ALB_DNS\>

**Test**:
- Browse products
- Add items to cart
- Test checkout flow

---

## Phase 5: Monitoring Setup

### Step 5.1: Verify Monitoring Stack

```bash
# SSH to Master-1
kubectl get pods -n monitoring
```

### Step 5.2: Access Grafana

**URL**: http://\<ALB_DNS\>/grafana/

**Credentials**:
- Username: `admin`
- Password: `dhakacart123`

### Step 5.3: Verify Dashboards

1. **Prometheus Metrics**:
   - Go to Explore → Select Prometheus
   - Query: `up`
   - Should show all targets

2. **Loki Logs**:
   - Go to Explore → Select Loki
   - Query: `{job="kubernetes-pods"}`
   - Should show logs from all pods

---

## Phase 6: Security Hardening

### Step 6.1: Run Automated Security Hardening
This single script applies network policies, scans images, and checks dependencies.

```bash
cd /home/arif/DhakaCart-03-test/scripts/security
./apply-security-hardening.sh
```

### Step 6.2: Verify Network Isolation

**Database CANNOT reach Internet** (should timeout):
```bash
kubectl exec -it -n dhakacart deployment/dhakacart-db -- curl -m 5 https://google.com
```

**Expected**: Timeout after ~5 seconds (this proves isolation is working)

---

## Phase 7: Verification

### Checklist

- [ ] **Infrastructure**
  - [ ] Bastion accessible via SSH
  - [ ] All nodes showing in `kubectl get nodes`
  - [ ] ALB health checks passing

- [ ] **Application**
  - [ ] Frontend loads at ALB URL
  - [ ] Backend API responding
  - [ ] Database connected
  - [ ] Redis caching working

- [ ] **Monitoring**
  - [ ] Grafana accessible
  - [ ] Prometheus collecting metrics
  - [ ] Loki collecting logs
  - [ ] Dashboards showing data

### Phase 7.1: Performance Testing (Optional)

Validate system performance under load:

```bash
cd /home/arif/DhakaCart-03-test/testing/load-tests
./run-load-test.sh
```
*   **Select**: Option 2 (Load Test) for standard validation.
*   **Auto-detection**: The script automatically finds the ALB URL.

---

## Phase 8: Enterprise Features

> **✨ Automated:** This phase is now handled automatically by `deploy-full-stack.sh` (Step 8).
> Use the steps below **only** if you need to run them manually or for troubleshooting.

To meet the 10 Exam Constraints, these scripts must be run **on the Master Node**.

### Step 8.1: Connect to Master Node
```bash
# 1. SSH to Master-1 (via Bastion)
ssh -i terraform/simple-k8s/dhakacart-k8s-key.pem ubuntu@<BASTION_IP>
ssh -i ~/.ssh/dhakacart-k8s-key.pem ubuntu@<MASTER1_IP>

# 2. Go to scripts directory
cd ~/scripts/enterprise-features
```

### Step 8.2: Run Enterprise Scripts

**A. Enable Automated Backups (Velero):**
```bash
./install-velero.sh
```

**B. Enable HTTPS (Cert-Manager):**
```bash
./install-cert-manager.sh
```

**C. Enable Vault Secrets:**
```bash
./install-vault.sh
```

---

## Troubleshooting

### Common Issues

#### 1. Terraform Apply Fails
**Error**: "Error creating EC2 instance"
**Solution**: Check AWS credentials, region, and quotas.

#### 2. Pods Not Starting
**Error**: "ImagePullBackOff" or "CrashLoopBackOff"
**Solution**: `kubectl describe pod <POD_NAME> -n dhakacart`

#### 3. ALB Health Checks Failing
**Solution**: Check NodePort services and Security Groups.

#### 4. Grafana Not Accessible
**Solution**: Run `./scripts/monitoring/setup-grafana-alb.sh`

---

## Summary

You have successfully deployed:
- ✅ AWS infrastructure (VPC, EC2, ALB)
- ✅ Kubernetes cluster (2 masters, 3 workers)
- ✅ DhakaCart application (frontend, backend, database)
- ✅ Monitoring stack (Prometheus, Grafana, Loki)
- ✅ Enterprise Features (Velero, Vault, Cert-Manager)

**Total deployment time**: ~20-30 minutes
