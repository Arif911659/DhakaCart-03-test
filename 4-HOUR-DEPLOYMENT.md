# 🚀 4-Hour Deployment Guide: Error-Free Workflow

This guide details the exact structure, files, and steps to follow for a flawless deployment within your 4-hour AWS access window.

---

## 📂 Key Files & Directories Structure

| Phase | Directory / File | Purpose |
|-------|------------------|---------|
| **1. Infra** | `terraform/simple-k8s/` | Infrastructure Code (VPC, EC2, ALB) |
| **2. Auto** | `scripts/deploy-4-hour-window.sh` | **MASTER SCRIPT** - Runs *everything* (Infra+K8s+App+Seed) |
| **3. Config** | `scripts/load-infrastructure-config.sh` | Loads IPs from Terraform to scripts |
| **4. K8s** | `scripts/k8s-deployment/` | K8s manifest syncing & deploying |
| **5. Verify** | `scripts/monitoring/` | Check Grafana/Prometheus health |
| **6. Enterprise** | `scripts/enterprise-features/` | Phase 2 features (Velero, Vault, Cert-Manager) |

---

## ✅ Phase 1: Pre-Deployment Check (First 5 Mins)

Before running any script, ensure your environment is clean and ready.

1.  **Check AWS Credentials**:
    ```bash
    aws sts get-caller-identity
    ```
    *If this fails, run `aws configure`.*

2.  **Verify Project Root**:
    You must always start from the root:
    ```bash
    cd ~/DhakaCart-03-test
    ```

---

## 🚀 Phase 2: Automated Deployment (The "One-Click" Step)

We use a smart, resumable master script to handle 95% of the work.

### **Features:**
- **Checkpoint System**: Tracks progress in `.deploy_state`. If it fails, fix the issue and re-run; it resumes automatically.
- **Automated Seeding**: Automatically seeds the database with initial product data.
- **Idempotent**: Can be run multiple times without breaking things.

**Command:**
```bash
./scripts/deploy-4-hour-window.sh
```

**Options:**
- `force`: Restart from the beginning (Warning: Clears state).
  ```bash
  ./scripts/deploy-4-hour-window.sh --force
  ```

**What the script does (Steps 1-7):**
1.  **Infrastructure**: Terraforms VPC, Bastion, Masters, Workers.
2.  **Config**: Loads IPs dynamically.
3.  **Scripts**: Generates node config scripts.
4.  **Nodes**: Uploads scripts, updates hostnames across cluster.
5.  **Cluster**: Inits Master-1, Joins Master-2 & Workers.
6.  **App**: Deploys frontend, backend, DB, Redis, Monitoring.
    - **6.1 DB Seed**: Populates `products` table automatically.
7.  **ALB**: Registers workers with Target Groups for external access.

---

## 🔍 Phase 3: Verification (Critical Step)

Once the script finishes (~25 mins), perform these manual checks.

### 1. Check Access
Open the **Frontend URL** shown at the end of the script output.
*   **Success**: You see the DhakaCart Storefront with products loaded.

### 2. Check Monitoring
Open the **Grafana URL** (also shown in output).
- **User**: `admin`
- **Pass**: `dhakacart123`
- **Action**: Import Dashboard ID `1860` (Node Exporter Full) to see metrics.

---

## 🔒 Phase 3.5: Security & Testing (Manual Steps)

### 1. Apply Security Policies
```bash
cd scripts/security
./apply-security-hardening.sh
```

### 2. Run Load Test (Smoke Test)
```bash
cd ../../testing/load-tests
./run-load-test.sh
```
*   **Select Option 1** (Smoke Test).

---

## 🏢 Phase 4: Exam Compliance: Enterprise Features

To meet the **10 Constraints** of the exam, you MUST run these scripts after the main deployment.

### 1. Enable Automated Backups (Velero)
*Use `sudo` password if prompted.*
```bash
./scripts/enterprise-features/install-velero.sh
```
*   **Result**: Velero installed, S3 backup bucket configured.

### 2. Enable HTTPS (Cert-Manager)
```bash
./scripts/enterprise-features/install-cert-manager.sh
```

### 3. Enable Vault Secrets
```bash
./scripts/enterprise-features/install-vault.sh
```

---

## 🆘 Emergency Manual Fallbacks

If the automated script stops, check the error message.
- **Fix the specific error**.
- **Re-run `./scripts/deploy-4-hour-window.sh`** to resume.

| Error | Fix |
|-------|-----|
| **Terraform Lock** | `cd terraform/simple-k8s && terraform force-unlock <ID>` |
| **SSH Permission** | `chmod 600 terraform/simple-k8s/dhakacart-k8s-key.pem` |
| **DB Not Seeding** | Run `./scripts/database/seed-database.sh --automated` manually |

---

## 🧹 Cleanup (End of 4-Hour Window)

**CRITICAL**: Destroy resources to avoid extra bills.

```bash
cd ~/DhakaCart-03-test/terraform/simple-k8s
terraform destroy -auto-approve
```

---

**Last Updated**: 10 December 2025
**Guide Version**: 3.0 (Smart Resumable Automation)
