# 🚀 4-Hour Deployment Guide: Error-Free Workflow

This guide details the exact structure, files, and steps to follow for a flawless deployment within your 4-hour AWS access window.

---

## 📂 Key Files & Directories Structure

| Phase | Directory / File | Purpose |
|-------|------------------|---------|
| **1. Infra** | `terraform/simple-k8s/` | Infrastructure Code (VPC, EC2, ALB) |
| **2. Auto** | `scripts/deploy-4-hour-window.sh` | **MASTER SCRIPT** - Runs everything |
| **3. Config** | `scripts/load-infrastructure-config.sh` | Loads IPs from Terraform to scripts |
| **4. K8s** | `scripts/k8s-deployment/` | K8s manifest syncing & deploying |
| **5. Verify** | `scripts/monitoring/` | Check Grafana/Prometheus health |
| **6. CI/CD** | `Makefile` & `.github/` | Future updates & manual releases |

---

## ✅ Phase 1: Pre-Deployment Check (First 5 Mins)

Before running any script, ensure your environment is clean and ready.

1.  **Check AWS Credentials**:
    ```bash
    aws sts get-caller-identity
    ```
    *If this fails, run `aws configure`.*

2.  **Clean Previous State** (If restarting):
    ```bash
    cd ~/DhakaCart-03-test/terraform/simple-k8s
    rm -rf .terraform/providers  # Optional, usually just 'terraform init' is enough
    ```

3.  **Verify Project Root**:
    You must always start from the root:
    ```bash
    cd ~/DhakaCart-03-test
    ```

---

## 🚀 Phase 2: Automated Deployment (The "One-Click" Step)

We use a single master script to handle 90% of the work. This avoids manual errors.

**Command:**
```bash
./scripts/deploy-4-hour-window.sh
```

**What this script does (and which files it touches):**

1.  **Infrastructure (`terraform/simple-k8s/main.tf`)**:
    -   Creates VPC, Bastion, Masters, Workers.
    -   Outputs IPs to `terraform/simple-k8s/terraform.tfstate`.

2.  **Configuration (`scripts/load-infrastructure-config.sh`)**:
    -   Reads the `.tfstate`.
    -   Updates `scripts/k8s-deployment/` scripts with new IPs.

3.  **Cluster Init (`scripts/nodes-config-steps/`)**:
    -   SSH into Master-1.
    -   Runs `kubeadm init`.
    -   SSH into Workers and joins them.

4.  **Hostname Setup (Automated)**:
    -   Updates all node hostnames (Bastion, Masters, Workers).

5.  **App Deploy (`scripts/k8s-deployment/update-and-deploy.sh`)**:
    -   Copies `k8s/` folder to Master.
    -   Applies `kubectl apply -f k8s/`.

---

## 🔍 Phase 3: Verification (Critical Step)

Once the script finishes (~25 mins), **DO NOT ASSUME SUCCESS**. Verify manually.

### 1. Check Infrastructure
```bash
cd terraform/simple-k8s
terraform output
```
*   Copy `bastion_public_ip` and `load_balancer_dns`.

### 2. Check Kubernetes Nodes
Login to Master-1 (via Bastion) and run:
```bash
kubectl get nodes
```
*   **Success**: 2 Masters, 3 Workers, all `Ready`.

### 3. Check Pods
```bash
kubectl get pods -n dhakacart
```
*   **Success**: `frontend`, `backend`, `db`, `redis` all `Running`.

### 4. Check Access
Open `http://<ALB_DNS>` in your browser.
*   **Success**: You see the DhakaCart Storefront.

---


---

## 🔒 Phase 3.5: Security Hardening & Testing (Manual Steps)

After verifying the app is running, secure it and test performance.

### 1. Apply Security Policies
```bash
cd scripts/security
./apply-security-hardening.sh
```
*Note: This applies Network Policies (Front/DB) and runs Trivy scans.*

### 2. Run Load Test (Smoke Test)
```bash
cd ../../testing/load-tests
./run-load-test.sh
```
*   **Select Option 1** (Smoke Test).
*   **Success**: Products load, 0% Error Rate (or <1%), Response time <200ms.

---

## 🛠 Phase 4: CI/CD & Management

### 1. Setup GitHub Actions
```bash
./scripts/fetch-kubeconfig.sh
# Add output to GitHub Secrets as KUBECONFIG
```

### 2. Manage Servers via Ansible (Optional)
Use Ansible to run commands on all nodes (Master/Workers) at once.
See `ansible/README.md` for setup.
```bash
cd ansible && ansible all -m ping
```

---

## 🆘 Emergency Manual Fallbacks (When Automation Fails)

If a specific step fails, go to the corresponding directory and fix it manually.

| Error Location | Directory to Fix | Command to Try |
|----------------|------------------|----------------|
| **Terraform Error** | `terraform/simple-k8s/` | `terraform apply` (Run again) |
| **SSH Error** | `terraform/simple-k8s/` | Check `dhakacart-k8s-key.pem` permissions (600) |
| **Nodes Not Ready** | `scripts/nodes-config/` | Log in to worker, run `kubeadm join` manually |
| **App Not Loading** | `k8s/deployments/` | Check `kubectl logs deployment/dhakacart-backend -n dhakacart` |
| **ALB 503 Error** | `terraform/simple-k8s/` | `./register-workers-to-alb.sh` (Re-run registration) |

---

## 🏢 Phase 4: Enterprise Features (Post-Deployment)

Once the core system is stable, enable the "Wow" features (Backup, HTTPS, Secrets).

### 1. Enable Automated Backups (Velero)
```bash
./scripts/enterprise-features/install-velero.sh
```
*   **Result**: Velero pod running, Daily backup scheduled for 2:00 AM.

### 2. Enable HTTPS (Cert-Manager)
```bash
./scripts/enterprise-features/install-cert-manager.sh
```
*   **Result**: Cert-Manager installed. Ingress needs update (see `PHASE-2-TECH-SPEC.md`).

### 3. Enable Vault Secrets
```bash
./scripts/enterprise-features/install-vault.sh
```
*   **Result**: Vault running. Ready for manual secret configuration.

---

## 🧹 Cleanup (End of 4-Hour Window)

**CRITICAL**: Destroy resources to avoid extra bills.

```bash
cd ~/DhakaCart-03-test/terraform/simple-k8s
terraform destroy -auto-approve
```

---

**Last Updated**: 08 December 2025
**Guide Version**: 2.0 (Error-Free Structure)
