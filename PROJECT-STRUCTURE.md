# Project Structure - DhakaCart Kubernetes Deployment

Complete organized structure of the DhakaCart project.

## Root Directory

```
DhakaCart-03-test/
├── DEPLOYMENT-GUIDE.md          # Master deployment guide
├── QUICK-REFERENCE.md            # One-page cheat sheet
│
├── terraform/                    # Infrastructure as Code
├── scripts/                      # Automation scripts
├── k8s/                          # Kubernetes manifests
├── docs/                         # Documentation
├── frontend/                     # Frontend application
├── backend/                      # Backend application
└── testing/                      # Load tests
```

## Terraform Directory

```
terraform/simple-k8s/
├── main.tf                       # Main infrastructure
├── variables.tf                  # Input variables
├── outputs.tf                    # Output values
├── alb-backend-config.tf         # ALB configuration
├── terraform.tfstate             # State file
├── dhakacart-k8s-key.pem         # SSH key
│
├── scripts/                      # Terraform scripts
│   ├── post-apply.sh
│   ├── register-workers-to-alb.sh
│   └── update-configmap-auto.sh
│
├── docs/                         # Terraform docs
│   ├── README.md
│   ├── DEPLOYMENT_SUCCESS.md
│   └── README_AUTOMATION_2025-12-01.md
│
├── outputs/                      # Output files
│   └── aws_instances_output.txt
│
├── backups/                      # State backups
└── nodes-config-steps/           # Node configs
```

## Scripts Directory

```
scripts/
├── load-infrastructure-config.sh # Config loader
├── post-terraform-setup.sh       # Post-terraform automation
│
├── k8s-deployment/               # K8s deployment
│   ├── update-and-deploy.sh
│   ├── copy-k8s-to-master1.sh
│   ├── sync-k8s-to-master1.sh
│   └── update-configmap-with-lb.sh
│
├── security/                     # Security hardening
│   └── apply-security-hardening.sh
│
├── monitoring/                   # Monitoring & Alerting
│   ├── deploy-alerting-stack.sh
│   ├── setup-grafana-alb.sh
│   ├── apply-prometheus-fix.sh
│   ├── check-prometheus-metrics.sh
│   ├── fix-grafana-config.sh
│   ├── diagnose-grafana-issues.sh
│   ├── fix-promtail-logs.sh
│   └── update-grafana-alb-dns.sh
│
├── database/                     # Database scripts
│   ├── seed-database.sh
│   └── diagnose-db-products-issue.sh
│
└── hostname/                     # Hostname management
    ├── change-hostname.sh
    ├── change-hostname-via-bastion.sh
    └── README-hostname-change.md
```

## Documentation Directory

```
docs/
├── TROUBLESHOOTING.md            # Comprehensive troubleshooting
├── LOKI-TROUBLESHOOTING.md       # Loki-specific issues
└── LOCAL_K8S_SETUP.md            # Local K8s setup
```

## Key Files by Purpose

### Deployment

| File | Purpose |
|------|---------|
| `DEPLOYMENT-GUIDE.md` | Complete 6-phase deployment guide |
| `QUICK-REFERENCE.md` | One-page command reference |
| `scripts/post-terraform-setup.sh` | Interactive post-terraform automation |
| `terraform/simple-k8s/main.tf` | Infrastructure definition |

### Configuration

| File | Purpose |
|------|---------|
| `scripts/load-infrastructure-config.sh` | Auto-load IPs from Terraform |
| `terraform/simple-k8s/variables.tf` | Terraform variables |
| `terraform/simple-k8s/outputs.tf` | Terraform outputs |

### Troubleshooting

| File | Purpose |
|------|---------|
| `docs/TROUBLESHOOTING.md` | General troubleshooting |
| `docs/LOKI-TROUBLESHOOTING.md` | Loki log collection issues |
| `QUICK-REFERENCE.md` | Quick fixes reference |

### Security

| File | Purpose |
|------|---------|
| `scripts/security/apply-security-hardening.sh` | Automated security hardening |

### Monitoring & Alerting

| File | Purpose |
|------|---------|
| `scripts/monitoring/deploy-alerting-stack.sh` | Deploy alerting stack |
| `scripts/monitoring/setup-grafana-alb.sh` | Setup Grafana ALB routing |
| `scripts/monitoring/fix-promtail-logs.sh` | Fix Promtail log collection |
| `scripts/monitoring/check-prometheus-metrics.sh` | Verify Prometheus |

### Database

| File | Purpose |
|------|---------|
| `scripts/database/seed-database.sh` | Populate database with sample data |
| `scripts/database/diagnose-db-products-issue.sh` | Debug database issues |

## Workflow

### 1. Infrastructure Setup

```
terraform/simple-k8s/
  └── terraform apply
      └── Creates: VPC, EC2, ALB, etc.
```

### 2. Post-Terraform Configuration

```
scripts/
  └── post-terraform-setup.sh
      ├── Loads config from Terraform
      ├── Updates all scripts with IPs
      ├── Changes hostnames (optional)
      └── Setups Grafana ALB (optional)
```

### 3. Application Deployment

```
scripts/k8s-deployment/
  └── update-and-deploy.sh
      ├── Copies K8s manifests to Master-1
      ├── Applies all configurations
      └── Deploys application pods
```

### 4. Monitoring Setup

```
scripts/monitoring/
  └── setup-grafana-alb.sh
      ├── Creates Grafana target group
      ├── Registers workers
      └── Adds ALB listener rule
```

### 5. Database Seeding

```
scripts/database/
  └── seed-database.sh
      └── Populates database with products
```

## Important Notes

### Security

- **SSH Key**: `terraform/simple-k8s/dhakacart-k8s-key.pem` (chmod 600)
- **Terraform State**: Contains sensitive data, keep secure
- **Grafana Password**: `dhakacart123` (change in production)

### State Management

- **Terraform State**: `terraform/simple-k8s/terraform.tfstate`
- **Backups**: `terraform/simple-k8s/backups/`
- **Never edit state manually**

### Configuration

- **Auto-resolved IPs**: Use `load-infrastructure-config.sh`
- **Manual updates**: Run `post-terraform-setup.sh`
- **All scripts updated automatically**

## Quick Access

### Most Used Commands

```bash
# Deploy infrastructure
cd terraform/simple-k8s && terraform apply

# Post-terraform setup
cd scripts && ./post-terraform-setup.sh

# Deploy application
cd scripts/k8s-deployment && ./update-and-deploy.sh

# Security hardening
cd scripts/security && ./apply-security-hardening.sh

# Deploy alerting
cd scripts/monitoring && ./deploy-alerting-stack.sh

# Seed database
cd scripts/database && ./seed-database.sh

# Setup Grafana
cd scripts/monitoring && ./setup-grafana-alb.sh
```

### Most Used Documentation

- Deployment: `DEPLOYMENT-GUIDE.md`
- Quick commands: `QUICK-REFERENCE.md`
- Troubleshooting: `docs/TROUBLESHOOTING.md`
- Terraform: `terraform/simple-k8s/README.md`

---

**Last Updated**: 2025-12-07  
**Version**: 1.0
