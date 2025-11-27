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

### Key Features

- 🔥 **One-Time Downloads**: Links become invalid immediately after the first use.
- ⏱️ **Auto-Expiration**: Files and metadata automatically expire after 24 hours.
- ⚡ **Direct-to-S3 Uploads**: Files are uploaded directly to S3 via presigned URLs, reducing server load and increasing security.
- 🛡️ **Security First**: Strict IAM policies, CORS protection, and minimal attack surface.

---

## 🏗️ Architecture & Workflow

The application follows a serverless architecture on AWS, ensuring scalability and low maintenance.

### How it Works

#### 1. Upload Process

1. **User** selects a file on the frontend.
2. **Frontend** requests a *Presigned Upload URL* from the API Gateway.
3. **Lambda (Upload Handler)** generates the URL and a unique `file_id`, storing metadata in **DynamoDB**.
4. **Frontend** uploads the file directly to **S3** using the secure URL.

#### 2. Download Process

1. **Recipient** clicks the shared link (containing `file_id`).
2. **Frontend** requests a *Presigned Download URL* from the API.
3. **Lambda (Download Handler)** checks **DynamoDB**:
    - If status is `ACTIVE`, it atomically updates it to `DOWNLOADED`.
    - If already `DOWNLOADED`, access is denied.
4. If successful, the API returns the S3 download URL.
5. **Frontend** downloads and displays the file.

### Component Breakdown

| Component | Purpose | Technology |
|----------|----------|------------|
| **Frontend Hosting** | Static UI, global delivery, HTTPS | S3 + CloudFront |
| **API Gateway** | REST API, throttling, validation | AWS API Gateway |
| **Compute Layer** | Business logic, presigned URLs | Lambda (Python 3.12) |
| **Database** | Metadata, single-use state, TTL | DynamoDB |
| **Storage** | Secure file persistence, encryption | S3 |
| **IaC** | Declarative infrastructure | Terraform |

---

## 📂 Project Structure

```text
.
├── backend/                 
│   ├── upload_handler/     # Lambda: Generates presigned upload URLs
│   └── download_handler/   # Lambda: Validates & generates download URLs
├── frontend/
│   ├── index.html.tpl      # HTML template (API URL injected by Terraform)
│   ├── script.js           # Frontend logic (Upload/Download handling)
│   └── style.css           # UI styling
├── infrastructure/
│   ├── main.tf             # Core resources (S3, DynamoDB)
│   ├── api.tf              # API Gateway & Lambda setup
│   ├── cloudfront.tf       # CDN configuration
│   ├── iam.tf              # IAM roles and policies
│   ├── outputs.tf          # Terraform outputs
│   └── variables.tf        # Configuration variables
└── README.md
```

---

## 🚀 Deployment Guide

Deploy your own fully serverless instance using Terraform.

### Prerequisites

- **AWS Account** and configured credentials (`aws configure`).
- **Terraform** installed (v1.0+).
- **Python 3.12** (for local testing/linting).

### Steps

1. **Clone the repository:**

   ```bash
   git clone https://github.com/evyatarpaz/Secure-File-Share-Service.git
   cd Secure-File-Share-Service
   ```

2. **Initialize Terraform:**

   Navigate to the infrastructure directory.

   ```bash
   cd infrastructure
   terraform init
   ```

3. **Deploy:**

   Review and apply the plan.

   ```bash
   terraform apply
   ```

   *Confirm with `yes` when prompted.*

4. **Access the Application:**

   After deployment, Terraform will output the `cloudfront_url`. Open this URL in your browser to start sharing files!

### Configuration

You can customize the deployment by modifying `infrastructure/variables.tf` or passing variables to `terraform apply`:

- `aws_region`: AWS Region (default: `us-east-1`)
- `project_name`: Prefix for resources (default: `secure-share`)
- `max_file_size_mb`: Max file size limit (default: `10`)

---

## 🔌 API Reference

### `POST /files`

Initiates a file upload.

- **Body:**

  ```json
  {
    "filename": "example.txt",
    "content_type": "text/plain",
    "file_size": 1024
  }
  ```

- **Response:**

  ```json
  {
    "file_id": "uuid...",
    "upload_url": "https://s3-presigned-url...",
    "expires_in": 3600
  }
  ```

### `GET /files?file_id={id}`

Retrieves a download link.

- **Query Param:** `file_id` (The UUID of the file)
- **Response:**

  ```json
  {
    "download_url": "https://s3-presigned-url...",
    "filename": "example.txt"
  }
  ```

- **Error:** `403 Forbidden` if the file has already been downloaded or expired.

---

## 🛡️ Security Highlights

Built with a **“Security First”** approach inspired by OWASP recommendations.

1. **Presigned URLs Only**: The backend never processes file bytes; users upload/download directly from S3 using short-lived (5-minute) signed URLs.
2. **Atomic One-Time Validation**: DynamoDB *Conditional Writes* guarantee the download can occur exactly once. Race conditions are handled at the database level.
3. **Least Privilege IAM**:
    - Upload Lambda: *write-only* access to S3.
    - Download Lambda: *read-only* access to S3.
4. **API Throttling**: Protects against abuse and Denial-of-Wallet attacks.
5. **Strict CORS Policy**: Prevents unauthorized domain access.

---

**Author:** Evyatar
Built with ❤️, Cloud, and Clean Architecture.
