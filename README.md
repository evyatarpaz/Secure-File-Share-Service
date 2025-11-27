# 🔒 Secure One-Time File Share  
A Serverless, Ephemeral & Cyber-Secure File Sharing Platform

![Terraform](https://img.shields.io/badge/Infrastructure-Terraform-purple?style=for-the-badge&logo=terraform)
![AWS](https://img.shields.io/badge/Cloud-AWS-orange?style=for-the-badge&logo=amazon-aws)
![Python](https://img.shields.io/badge/Backend-Python_3.12-blue?style=for-the-badge&logo=python)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

A fully serverless solution for **secure, self-destructing, one-time file sharing**.  
Upload a file → receive a one-time link → the file is deleted immediately after use.  

---

## 🚀 Live Application  
Try the production environment:

### 👉 **[Open Secure File Share](https://d1iokx6vicwr0c.cloudfront.net/evyatar-file-share-service/)**  
*(Hosted on AWS CloudFront + S3)*

---

## 📖 Overview  
Traditional file-sharing leaves persistent traces on cloud platforms, inboxes, and servers.  
This project eliminates that risk with a **one-time, ephemeral file-transfer system**, inspired by a security-first architecture.

**Key Features:**
- 🔥 **One-Time Downloads** — link becomes invalid the moment it’s used, implemented via atomic DynamoDB updates.  
- ⏱️ **Auto-Expiration** — files + metadata auto-delete after 24 hours using S3 Lifecycle + DynamoDB TTL.  
- ⚡ **Direct-to-S3 Uploads** — browser uploads file directly via presigned URL; the backend never processes file bytes.  
- 🛡️ **Hardened Security** — strict IAM, rate limiting, scoped access, CORS protection.

```

## 🧩 Component Breakdown

| Component | Purpose | Technology |
|----------|----------|------------|
| **Frontend Hosting** | Static UI, global delivery, HTTPS | S3 + CloudFront |
| **API Gateway** | REST API, throttling, validation | AWS API Gateway |
| **Compute Layer** | Business logic, presigned URLs | Lambda (Python 3.12) |
| **Database** | Metadata, single-use state, TTL | DynamoDB |
| **Storage** | Secure file persistence, encryption, lifecycle rules | S3 |
| **IaC** | Declarative infrastructure | Terraform |

---

## 🛡️ Security Highlights  
Built with a **“Security First”** approach inspired by OWASP recommendations.

1. **Presigned URLs Only**  
   Backend never accesses file content; users get 5-minute signed URLs.

2. **Atomic One-Time Validation**  
   DynamoDB *Conditional Writes* guarantee the download can occur exactly once.

3. **Least Privilege IAM**  
   - Upload Lambda: *write-only*  
   - Download Lambda: *read-only*

4. **API Throttling / Rate Limiting**  
   Protects from Abuse + Denial-of-Wallet (AWS spending spikes).

5. **Strict CORS Policy**  
   Prevents unauthorized domain access.

---

## 🔌 API Reference  
**Base URL:**  
`https://s9jweghuxc.execute-api.us-east-1.amazonaws.com/prod/files`

### 1) Upload Request  
**POST /**  
Request a presigned upload URL.

**Body Example:**
```json
{
  "filename": "secret.pdf",
  "content_type": "application/pdf",
  "file_size": 1048576
}
```

**Success Response:**
- `file_id`
- `upload_url` (PUT)

---

### 2) Download Request  
**GET** `/?file_id={uuid}`  
Returns a **302 redirect** to S3 if valid.  
If expired / already used → `403 Forbidden`.

---

## 🛠️ Deployment (Terraform)  
Deploy your own fully serverless instance.

### Requirements
- AWS CLI (configured)
- Terraform v1+
- Python 3.12

### Steps
```bash
git clone https://github.com/your-username/secure-file-share.git
cd secure-file-share/infrastructure
terraform init
terraform apply
```

After deployment finishes, Terraform outputs a **CloudFront URL** for your application.

---

## 📂 Project Structure  

```
.
├── backend/                 
│   ├── upload_handler/      # Generates presigned upload URLs
│   └── download_handler/    # Validates & redirects on download
├── frontend/
│   ├── index.html.tpl       # HTML template with injected API URL
│   ├── style.css            # UI styling
│   └── script.js            # Upload & download logic
└── infrastructure/
    ├── main.tf              # Core resources (Lambda, S3, DB)
    ├── api.tf               # API Gateway + throttling
    ├── cloudfront.tf        # CDN
    ├── frontend.tf          # Static hosting
    ├── iam.tf               # IAM policies
    ├── outputs.tf           # Outputs
    └── variables.tf         # Config variables
```

---

## 🔗 Environment Links

| Purpose | Link |
|--------|------|
| **Production App (CloudFront)** | https://d1iokx6vicwr0c.cloudfront.net/evyatar-file-share-service/ |
| **Backend API – Prod** | https://s9jweghuxc.execute-api.us-east-1.amazonaws.com/prod/files |
| **Backend API – Dev** | https://s9jweghuxc.execute-api.us-east-1.amazonaws.com/dev/files |
| **Raw S3 Frontend** | http://secure-share-frontend-20251126112323806000000001.s3-website-us-east-1.amazonaws.com |

---

**Author:** Evyatar  
Built with ❤️, Cloud, and Clean Architecture.
