# 🔒 Secure One-Time File Share

A serverless, security-driven platform for **one-time, self-destructing file sharing**.  
Upload a file → get a unique link → it can be downloaded *exactly once* → the file disappears automatically.

![Terraform](https://img.shields.io/badge/Infra-Terraform-purple?style=flat-square&logo=terraform)
![AWS](https://img.shields.io/badge/Cloud-AWS-orange?style=flat-square&logo=amazon-aws)
![Python](https://img.shields.io/badge/Backend-Python_3.12-blue?style=flat-square&logo=python)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

---

## 🚀 Live Application  
Try the production environment:

### 👉 **[Open Secure File Share](https://d1iokx6vicwr0c.cloudfront.net/evyatar-file-share-service/)**  
*(Hosted on AWS CloudFront + S3)*
---

## ✨ Highlights

- **One-Time Downloads** — atomic DynamoDB validation ensures each file is downloadable once.  
- **Automatic Expiration** — files & metadata auto-delete after 24h.  
- **Direct-to-S3 Uploads** — backend only generates presigned URLs.  
- **Security-First** — strict IAM roles, rate limiting, CORS enforcement.

---

# 🏗️ Architecture

### 📌 High-Level System Flow (Improved Diagram – GitHub Compatible)

```mermaid
flowchart TD

    %% USER LAYER
    User["👤 End User"]
    Browser["🌐 Browser UI (Frontend)"]

    %% EDGE LAYER
    CDN["🚀 CloudFront (CDN)"]
    StaticSite["📄 S3 Static Website"]

    %% API LAYER
    APIGW["🛡️ API Gateway"]

    %% COMPUTE
    subgraph ComputeLayer["Compute Layer"]
        UploadFunc["Lambda: Upload Handler"]
        DownloadFunc["Lambda: Download Handler"]
    end

    %% DATA + STORAGE
    subgraph DataLayer["Data Layer"]
        DB["DynamoDB (File Metadata + TTL)"]
        S3Bucket["S3 Bucket (Encrypted Files)"]
    end

    %% FLOW CONNECTIONS

    User --> Browser

    Browser -->|1. Access Website| CDN
    CDN --> StaticSite

    %% UPLOAD FLOW
    Browser -->|2. POST /upload| APIGW
    APIGW --> UploadFunc
    UploadFunc -->|3. Generate Presigned URL| S3Bucket
    UploadFunc -->|4. Save Metadata & TTL| DB
    Browser -->|5. PUT File (Direct Upload)| S3Bucket

    %% DOWNLOAD FLOW
    Browser -->|6. GET /download?file_id| APIGW
    APIGW --> DownloadFunc
    DownloadFunc -->|7. Atomic Status Update| DB
    DownloadFunc -->|8. 302 Redirect| S3Bucket
```

---

## 🔌 API Endpoints  

### Upload – `POST /`
Request presigned URL:

```json
{
  "filename": "secret.pdf",
  "content_type": "application/pdf",
  "file_size": 1048576
}
```

### Download – `GET /?file_id={uuid}`
- `302 Redirect` to S3 (if valid)  
- `403 Forbidden` if expired or already used  

**Base URL:**  
`https://s9jweghuxc.execute-api.us-east-1.amazonaws.com/prod/files`

---

## 🛠 Deployment (Terraform)

```bash
git clone https://github.com/your-username/secure-file-share.git
cd secure-file-share/infrastructure
terraform init
terraform apply
```

Terraform outputs the CloudFront URL.

---

## 📁 Project Structure

```
backend/
  upload_handler/
  download_handler/
frontend/
  index.html.tpl
  style.css
  script.js
infrastructure/
  main.tf
  api.tf
  cloudfront.tf
  frontend.tf
  iam.tf
  outputs.tf
  variables.tf
```

---

## 🔗 Environment Links  
- **Production App:** https://d1iokx6vicwr0c.cloudfront.net/evyatar-file-share-service/  
- **API (Prod):** https://s9jweghuxc.execute-api.us-east-1.amazonaws.com/prod/files  
- **API (Dev):** https://s9jweghuxc.execute-api.us-east-1.amazonaws.com/dev/files  
- **S3 Raw Frontend:** http://secure-share-frontend-20251126112323806000000001.s3-website-us-east-1.amazonaws.com  

---

**Author:** Evyatar  
Built with AWS, Terraform & ❤️
