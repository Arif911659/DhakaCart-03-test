# Organized Folder Structure (Updated: 06-12-2025)

This document reflects the current project structure of **DhakaCart-03-test** as of 06 Dec 2025.

## Project Root: `DhakaCart-03-test`

### 1. Application Code
*   **backend/**: Python Flask API source code.
*   **frontend/**: React.js source code.
*   **database/**: SQL initialization scripts (`init.sql`).

### 2. Infrastructure & Deployment (Kubernetes - Production)
*   **k8s/**
    *   **deployments/**: Application deployments (backend, frontend, db, redis).
    *   **services/**: Kubernetes Services (ClusterIP, NodePort).
    *   **configmaps/**: Configuration files (Nginx, App configs).
    *   **secrets/**: Secret management (credentials).
    *   **ingress/**: AWS ALB Ingress resources.
    *   **monitoring/**: **(NEW)** Complete Observability Stack.
        *   **prometheus/**: Metrics collection (Deployment, ConfigMap, RBAC).
        *   **grafana/**: Visualization (Deployment, Datasources).
        *   **loki/**: Log aggregation system.
        *   **promtail/**: Log shipping agent.
        *   **node-exporter/**: Hardware metrics.
        *   `guided-steps-2025-12-06.md`: Monitoring setup guide.
    *   `deploy-prod.sh`: **(Automated)** Full deployment script including monitoring.

### 3. Infrastructure (Terraform)
*   **terraform/simple-k8s/**: AWS Infrastructure as Code (VPC, EC2, ALB, Security Groups).

### 4. Configuration & Documentation
*   `README.md`: Main project documentation.
*   `PLAN-2025-12-06.md`: Current execution plan.
*   `Project-Deployment-Steps-(06-12-2025).md`: Detailed step-by-step deployment guide.
*   `Organized_folder-files-06-12-2025.md`: This file.

### 5. Utilities
*   **scripts/**: Miscellaneous helper scripts.
*   **ansible/**: Configuration management (if used).
