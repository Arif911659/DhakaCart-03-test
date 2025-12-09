# 🏗️ DhakaCart Terraform Infrastructure

This directory contains Infrastructure-as-Code (IaC) for provisioning Kubernetes clusters on AWS.

## 📁 Directory Structure

```
terraform/
├── simple-k8s/              # Standard Production setup (Used by Automation)
│   ├── main.tf              # Main configuration
│   ├── scripts/             # Infrastructure specific scripts
│   └── README.md            # Detailed guide
│
├── k8s-ha-cluster/          # High-Availability Setup (Alternative)
│   ├── main.tf
│   └── README.md
│
└── README.md                # This file
```

---

## 🚀 Option 1: Simple Kubernetes (Recommended)

This is the standard infrastructure used by the **4-Hour Deployment** automation.

### Architecture
```
Internet
    │
    ├─────► Bastion (Public IP) ──┐
    │                              │
    └─────► NAT Gateway            │
                │                  │ SSH
    ┌───────────▼──────────────────▼───────┐
    │        Private Subnet                │
    │  ┌──────────┐      ┌──────────┐      │
    │  │ Master-1 │      │ Worker-1 │      │
    │  │ Master-2 │      │ Worker-2 │      │
    │  └──────────┘      │ Worker-3 │      │
    │                                      │
    └──────────────────────────────────────┘
```

### Components
-   **1 Bastion Server**: Public access point (t3.small)
-   **2 Master Nodes**: Control plane (t3.medium)
-   **3 Worker Nodes**: Workloads (t3.medium)
-   **ALB**: Application Load Balancer for public access

### Quick Start
This is automated by the project root scripts, but to run infrastructure manually:

```bash
cd simple-k8s
terraform init
terraform apply
```

**Cost Estimate:** ~$7.20/day (approx $0.30/hour)

---

## 🚀 Option 2: HA Cluster (Advanced)

For high-availability requirements with 3 masters and multi-AZ support.

 **Guide:** `k8s-ha-cluster/README.md`

### Features
-   3 Master Nodes (Etcd HA)
-   Internal Load Balancer for API Server
-   Multi-AZ deployment

---

## 📚 Documentation Links
-   **Full Deployment Guide:** `../DEPLOYMENT-GUIDE.md`
-   **Automation Script:** `../scripts/deploy-4-hour-window.sh`
