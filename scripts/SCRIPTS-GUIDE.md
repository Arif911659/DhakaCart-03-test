# 📜 DhakaCart Scripts Guide

This directory contains all the automation scripts for deploying, managing, and securing the DhakaCart application.

## 📂 Directory Structure

```
scripts/
├── deploy-4-hour-window.sh        # 🚀 MASTER SCRIPT: Deploys everything (Infra + K8s + App)
├── post-terraform-setup.sh        # 🛠️ SETUP: Interactive config after Terraform
├── fetch-kubeconfig.sh            # 🔑 ACCESS: Get Kubeconfig for local access
├── load-infrastructure-config.sh  # ⚙️ CONFIG: Helper to load Terraform outputs
│
├── k8s-deployment/                # ☸️ KUBERNETES
│   ├── sync-k8s-to-master1.sh     # Syncs files to Master Node
│   └── update-and-deploy.sh       # Deploys App Manifests
│
├── database/                      # 💾 DATABASE
│   ├── seed-database.sh           # Seeds sample data
│   └── init.sql                   # SQL seed file
│
├── security/                      # 🔒 SECURITY
│   └── apply-security-hardening.sh # Applies policies & scans
│
└── monitoring/                    # 📊 MONITORING
    ├── deploy-alerting-stack.sh   # Sets up Prometheus/Grafana alerts
    └── setup-grafana-alb.sh       # Configures Grafana access
└── internal/                      # 🔧 INTERNAL (Helper/Fix scripts)
    ├── generate-ansible-inventory.sh
    ├── update-alb-dns-dynamic.sh
    ├── database/
    │   └── diagnose-db-products-issue.sh
    ├── k8s-deployment/
    │   └── update-configmap-with-lb.sh
    ├── monitoring/
    │   ├── fix-grafana-config.sh
    │   └── ... (other monitoring fix scripts)
    └── hostname/                  # Hostname management
```

---

## 🚦 Application Workflow: Which Script? When?

### 1. **I want to deploy everything from scratch** (Start Here)
*   **Script**: `./deploy-4-hour-window.sh`
*   **What it does**:
    1.  Provisions AWS Infra (Terrform).
    2.  Configures K8s Cluster (Kubeadm).
    3.  Deploys Backend, Frontend, DB, Redis.
    4.  Sets up Monitoring & Security.
*   **Use Case**: Fresh 4-hour deployment window.

### 2. **I just updated the code and want to re-deploy**
*   **Option A (Automated)**:
    1.  `./scripts/k8s-deployment/sync-k8s-to-master1.sh` (Syncs files).
    2.  SSH to Master-1: `ssh ubuntu@<MASTER_IP>`.
    3.  Run: `./k8s/deploy-prod.sh`.
*   **Option B (Manual)**:
    *   Run `./scripts/k8s-deployment/update-and-deploy.sh` (from local, if connected).

### 3. **I want to fix/reset the Database**
*   **Script**: `./scripts/database/seed-database.sh`
*   **What it does**: Drops existing data (if configured) or inserts missing products.
*   **Use Case**: Products not showing on Frontend.

### 4. **I want to secure the cluster**
*   **Script**: `./scripts/security/apply-security-hardening.sh`
*   **What it does**:
    1.  Runs Trivy vulnerability scans.
    2.  Applies Network Policies (Frontend/DB isolation).
*   **Use Case**: Before presentation or production handover.

### 5. **I want to access the cluster from my laptop**
*   **Script**: `./scripts/fetch-kubeconfig.sh`
*   **What it does**: Downloads `admin.conf` from Master-1 to your `~/.kube/config`.
*   **Use Case**: Using `kubectl` locally.

### 6. **Monitoring is broken / Alerts not working**
*   **Script**: `./scripts/monitoring/deploy-alerting-stack.sh`
*   **What it does**: Re-applies Prometheus rules and Alertmanager config.

---

## 🛠 Helper Scripts (Internal Use)

*   `load-infrastructure-config.sh`: Used by other scripts to find IP addresses.
*   `internal/generate-ansible-inventory.sh`: Creates Ansible hosts file.
*   `internal/update-alb-dns-dynamic.sh`: Updates source code with new Load Balancer URL.

---

## ⚠️ Important Notes

*   **Always run from project root**: `cd ~/DhakaCart-03-test` before running `./scripts/...`.
*   **Execution Permission**: If permission denied, run `chmod +x scripts/**/*.sh`.

---

## 🔧 Troubleshooting Common Script Issues

| Issue | Solution |
|-------|----------|
| `Permission denied` | Run `chmod +x <script_name>` |
| `terraform/terraform.tfstate not found` | Run `terraform apply` first to generate state file |
| `SSH connection failed` | Check `dhakacart-k8s-key.pem` permissions (must be 400/600) |
| `kubectl: command not found` | Run execution on Master Node or install kubectl locally |

