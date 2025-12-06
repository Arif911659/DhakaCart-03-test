# 🚀 Project Deployment Steps (06-12-2025)

This is the **Master Guide** to deploying the entire **DhakaCart** platform from scratch. It covers Infrastructure (AWS), Kubernetes Setup, Application Deployment, and Observability.

---

## 🏗️ Phase 1: Infrastructure Provisioning (AWS)

**Prerequisites:** AWS CLI configured, Terraform installed.

1.  **Navigate to Terraform Directory:**
    ```bash
    cd terraform/simple-k8s
    ```
2.  **Initialize & Apply:**
    ```bash
    terraform init
    terraform apply -auto-approve
    ```
    *This creates the VPC, 3 EC2 Instances (Bastion, Master, Worker), Security Groups, and ALB.*

3.  **Save Key:** Ensure `dhakacart-k8s-key.pem` is in this directory.

---

## ☸️ Phase 2: Kubernetes Cluster Setup (Kubeadm)

1.  **SSH into Master Node** (via Bastion if needed, or direct if configured):
    ```bash
    ssh -i dhakacart-k8s-key.pem ubuntu@<MASTER_IP>
    ```
2.  **Initialize Cluster:**
    ```bash
    sudo kubeadm init --pod-network-cidr=10.244.0.0/16
    ```
3.  **Setup Kubeconfig:** Copy the config as instructed by kubeadm output.
4.  **Install Network Plugin (Flannel):**
    ```bash
    kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
    ```
5.  **Join Worker Node:** Run the `kubeadm join` command (generated in Step 2) on the **Worker Node**.

---

## 📦 Phase 3: Application Deployment (Automated)

We have automated the entire deployment process.

1.  **Sync Files to Master:**
    From your local machine (root directory), run:
    ```bash
    ./scripts/k8s-deployment/sync-k8s-to-master1.sh
    ```

2.  **Run Deployment Script (On Master Node):**
    SSH into the Master Node and run:
    ```bash
    cd ~/k8s
    chmod +x deploy-prod.sh
    ./deploy-prod.sh
    ```
    *This script automates:*
    - Namespace creation (`dhakacart` & `monitoring`)
    - Secrets & ConfigMaps
    - Database & Redis
    - Backend & Frontend
    - **Monitoring Stack** (Prometheus, Grafana, Loki, Promtail)
    - Ingress Configuration

3.  **Seed Database (First Time Only):**
    ```bash
    kubectl exec -i -n dhakacart deployment/dhakacart-db -- psql -U dhakacart -d dhakacart_db < database/init.sql
    ```

---

## 📊 Phase 4: Monitoring & Logging

Once Phase 3 is completed, the entire observability stack (Metrics + Logs) is running. Here is how to use it.

### 1. Verification
Check if all pods are running in the monitoring namespace:
```bash
kubectl get pods -n monitoring
```
*Expected: Prometheus, Grafana, Loki, Promtail (DaemonSet), and Node-Exporter should be `Running`.*

### 2. Accessing Grafana
Grafana is exposed via the public Application Load Balancer (ALB).
*   **URL:** `http://<ALB-DNS-NAME>/grafana/`
    *   *(Replace `<ALB-DNS-NAME>` with your actual AWS Load Balancer DNS, e.g., `dhakacart-k8s-alb-....elb.amazonaws.com`)*
*   **Username:** `admin`
*   **Password:** `dhakacart123`

### 3. Setting up Dashboards (Visualizing Metrics)
1.  Log in to Grafana.
2.  Go to **Dashboards** (Menu) > **New** > **Import**.
3.  Enter Dashboard ID `315` (Kubernetes Cluster Monitoring) and click **Load**.
4.  Select `Prometheus` as the Data Source.
5.  Click **Import**.
    *   *Now you can see CPU/Memory usage of all your pods!*

### 4. Viewing Logs (Loki & Promtail)
To see logs without SSH-ing into servers:
1.  In Grafana, go to **Explore** (Compass icon on the left).
2.  Select **Loki** from the datasource dropdown (top-left).
3.  Under **Label filters**:
    *   Select Label: `namespace`
    *   Select Value: `dhakacart`
4.  Click **Run query** (Top right).
    *   *You will see real-time logs from your Backend, Frontend, and Database!*

---

## 🛠️ Maintenance & Updates

*   **Update Code:**
    1. Make changes locally.
    2. Build & Push Docker Images.
    3. Update `image` tags in `k8s/deployments/*.yaml`.
    4. Run `./deploy-prod.sh` again to roll out updates.

---
**Prepared by:** Antigravity  
**Date:** 06 Dec 2025
