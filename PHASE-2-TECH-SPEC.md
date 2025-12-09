# 🚀 Phase 2 Technical Specification: Enterprise Features
> **Codebase Location:** `scripts/enterprise-features/` & `k8s/enterprise-features/`

এই ডকুমেন্টটি আপনাকে বোঝাবে **Phase 2** তে আমরা আসলে কী করব এবং কেন করব। আগামীকাল আমরা এই স্টেপগুলোই ফলো করব।

---

## 1. Automated Backups (Velero)
**Objective:** ডাটাবেস এবং কুবারনেটিস রিসোর্স অটোমেটিক ব্যাকআপ নেওয়া, যাতে ক্র্যাশ করলে ১ কমান্ডে রিস্টোর করা যায়।

### 🛠️ Architecture
*   **Tool:** Velero (Industry Standard for K8s Backup).
*   **Storage:** AWS S3 Bucket (Cloud Storage).
*   **Mechanism:** Snapshot of Persistent Volume (Database) + YAML Backups.

### 📋 Implementation Steps (Execution Guide)
**Step 1:** Run the automation script:
```bash
./scripts/enterprise-features/install-velero.sh
```
*(This will check credentials, create S3 bucket if needed, install Velero, and schedule daily backups.)*

**Step 2:** Verify Backup:
```bash
velero backup create test-backup
velero backup get
```

**Step 3:** Disaster Recovery Test (Optional):
```bash
kubectl delete namespace dhakacart
velero restore create --from-backup test-backup
```

---

## 2. HTTPS & SSL (Cert-Manager)
**Objective:** ব্রাউজারে "Not Secure" ওয়ার্নিং দূর করা এবং ডাটা এনক্রিপ্ট করা (Green Lock Icon)।

### 🛠️ Architecture
*   **Tool:** Cert-Manager (Runs inside K8s).
*   **Authority:** Let's Encrypt (Provides Free Global SSL Certs).
*   **Integration:** AWS ALB Ingress Controller.

### 📋 Implementation Steps (Execution Guide)
**Step 1:** Run the automation script:
```bash
./scripts/enterprise-features/install-cert-manager.sh
```
*(This installs Jetstack Cert-Manager and applies the ClusterIssuer for Let's Encrypt.)*

**Step 2:** Update Ingress (One-time Manual Step):
`k8s/ingress.yaml` ফাইলে `annotations` সেকশনে এই লাইনটি অ্যাড করুন:
```yaml
cert-manager.io/cluster-issuer: "letsencrypt-prod"
```

**Step 3:** Verify:
Wait 1-2 minutes, then visit `https://<YOUR-ALB-DNS>`. You should see the Green Lock.

---

## 3. Advanced Secrets (HashiCorp Vault)
**Objective:** পাসওয়ার্ড এবং সেনসিটিভ ডাটা পড-এর এনভায়রনমেন্ট ভেরিয়েবলে প্লেইন টেক্সট হিসেবে না রাখা।

### 🛠️ Architecture
*   **Tool:** HashiCorp Vault (Bank-grade security).
*   **Mechanism:** "Secret Injection" (পড চালু হওয়ার সময় ভল্ট থেকে পাসওয়ার্ড নিয়ে মেমোরিতে রাখে, ফাইলে না)।

### 📋 Implementation Steps (Execution Guide)
**Step 1:** Run the automation script:
```bash
./scripts/enterprise-features/install-vault.sh
```
*(This installs Vault in Dev Mode and enables K8s Auth.)*

**Step 2:** Store a Secret:
```bash
# Run this inside the Vault Pod
kubectl exec -it -n vault vault-0 -- sh
vault kv put secret/dhakacart db_pass=supersecret
exit
```

**Step 3:** Inject into App (Manual Update):
Add this annotation to your `deployment.yaml`:
```yaml
vault.hashicorp.com/agent-inject: "true"
vault.hashicorp.com/role: "dhakacart-role"
vault.hashicorp.com/agent-inject-secret-config: "secret/dhakacart"
```

---

## 💡 Summary for You
আগামীকাল আপনার কাজ হবে মূলত:
1.  **Velero CLI** এবং **Helm** আপনার ল্যাপটপে ইন্সটল করা।
2.  টার্মিনালে এই ৩টি স্ক্রিপ্ট রান করা:
    ```bash
    ./scripts/enterprise-features/install-velero.sh
    ./scripts/enterprise-features/install-cert-manager.sh
    ./scripts/enterprise-features/install-vault.sh
    ```

এগুলো ইমপ্লিমেন্ট করলে আপনার প্রজেক্ট **"Production Grade"** হয়ে যাবে। রেডি তো? 🚀
```
