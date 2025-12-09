# 🚀 Node Configuration Automation

This directory contains automation scripts for configuring Kubernetes nodes based on Terraform outputs.

## 📁 Directory Structure

```
scripts/nodes-config/
├── automate-node-config.sh          # Main script (manual trigger)
├── extract-terraform-outputs.sh     # Dynamically extracts IPs from Terraform state
├── generate-scripts.sh              # Generates node config scripts from templates
├── upload-to-bastion.sh             # Uploads generated scripts to Bastion
│
├── templates/                       # Template files (Master/Worker config)
│   ├── master-1.sh.template
│   ├── master-2.sh.template
│   └── workers.sh.template
│
└── generated/                       # Auto-generated scripts (ignored by git)
    ├── master-1.sh
    ├── master-2.sh
    └── workers.sh
```

## 🎯 Usage

**Recommended:** This is automatically run by the main deployment script:
```bash
./scripts/deploy-4-hour-window.sh
```

**Manual Run (Debugging):**
If you need to regenerate scripts manually:

```bash
cd scripts/nodes-config
./automate-node-config.sh
```

## 🛠 What it does

1.  **Extracts IPs**: Reads `terraform.tfstate` from `terraform/simple-k8s/` locally.
2.  **Generates Scripts**: Creates `master-1.sh`, `master-2.sh`, etc. with actual IPs.
3.  **Uploads**: Copies these scripts to the Bastion host (`~/nodes-config/`).

## 📋 Prerequisites

1.  **Terraform Applied**: Infrastructure must be running.
2.  **Dependencies**: `jq` or `python3` (installed on local machine).
3.  **SSH Key**: `terraform/simple-k8s/dhakacart-k8s-key.pem` must exist.

## 🐛 Troubleshooting

### Terraform state not found
Ensure you run this from the project root or correct directory. The script expects `terraform/simple-k8s/terraform.tfstate`.

### Scripts not configured
Check `generated/` folder to see if scripts were created.

---
**Last Updated:** 08 December 2025
**Version:** 2.0 (Refactored Structure)
