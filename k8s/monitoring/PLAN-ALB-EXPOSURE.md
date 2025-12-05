# Plan: Expose Prometheus via ALB

## 🎯 Goal
Access Prometheus dashboard via the public Load Balancer URL: `http://dhakacart-k8s-alb-98601629.ap-southeast-1.elb.amazonaws.com/prometheus/`

## 🧩 Challenge
The AWS ALB is configured via Terraform to forward **ALL** traffic to the Frontend Service (NodePort 30080). It does not use the Kubernetes Ingress Controller. To avoid complex Terraform updates, we will configure the **Frontend Nginx** to act as a reverse proxy for Prometheus.

## 🛠 Proposed Changes

### 1. Prometheus Deployment Update
*   **File**: `k8s/monitoring/prometheus/deployment.yaml`
*   **Change**: Add `--web.external-url=/prometheus/` argument.
    *   This tells Prometheus it is being served under this path so it generates correct links for CSS/JS assets.

### 2. Frontend Nginx Configuration
*   **New File**: `k8s/configmaps/frontend-nginx-config.yaml`
*   **Content**: A standard Nginx config (based on `frontend/nginx.conf`) but with an added `location` block:
    ```nginx
    location /prometheus/ {
        proxy_pass http://prometheus-service.monitoring.svc.cluster.local:9090/prometheus/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    ```

### 3. Frontend Deployment Update
*   **File**: `k8s/deployments/frontend-deployment.yaml`
*   **Change**: Mount the new ConfigMap to `/etc/nginx/conf.d/default.conf`.
    *   This overrides the `nginx.conf` baked into the Docker image.

## 🧪 Verification Plan

1.  **Deploy Changes**:
    *   `kubectl apply -f k8s/monitoring/prometheus/deployment.yaml`
    *   `kubectl apply -f k8s/configmaps/frontend-nginx-config.yaml`
    *   `kubectl apply -f k8s/deployments/frontend-deployment.yaml`
2.  **Verify Pods**: Ensure updated pods are running.
3.  **Access URL**: Open `http://dhakacart-k8s-alb-98601629.ap-southeast-1.elb.amazonaws.com/prometheus/` in the browser.
