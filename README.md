# Ping Pong API Deployment on Google Kubernetes Engine (GKE)

## Endpoints
- /ping - Responds with {'pong'}
- /pong - Responds with {'ping'}
- /professional-ping-pong - Responds with {'pong'} 90% of the time
- /amateur-ping-pong - Responds with {'pong'} 70% of the time
- /chance-ping-pong - Responds with {'ping'} 50% of the time and {'pong'} 50% of the time

## Description
This is a simple API to test that the RapidAPI/Mashape API Proxy is working. When you access /ping, the API will return a JSON that contains "pong".

This repository contains the source code and deployment pipeline for the Ping Pong API, a containerized Node.js application deployed to Google Kubernetes Engine (GKE) using GitHub Actions, Docker, and Helm.

## 🌐 Project Overview

- **Cloud Provider**: Google Cloud Platform (GCP)
- **Orchestration**: Google Kubernetes Engine (GKE)
- **CI/CD Pipeline**: GitHub Actions
- **Container Registry**: Artifact Registry (`us-central1-docker.pkg.dev`)
- **Deployment Tool**: Helm
- **Network Security**:
  - **Artifact Registry** access is controlled via IAM permissions.
  - **GKE Cluster** access is authenticated via Workload Identity (Service Account + `gke-gcloud-auth-plugin`).
  - **Cluster** communication secured via private network endpoints.
  - RBAC policies are applied for least privilege access within the cluster.

## 🚀 Deployment Workflow

The deployment is fully automated via GitHub Actions:

1. **On push to `main` branch**:
   - Build Docker image.
   - Push image to Artifact Registry.
   - Deploy the application to GKE using Helm.

2. **Manual deployment**:
   - Triggered via GitHub Actions' `workflow_dispatch`.

## 🔧 GitHub Actions Workflow

Main workflow: `.github/workflows/deploy.yml`

Key steps:
- Authenticate to GCP using Service Account.
- Configure Docker authentication.
- Build and push Docker image.
- Get GKE credentials.
- Deploy to GKE using Helm.
- Verify the deployed image version.

## 🛡️ Security Considerations

- **Principle of Least Privilege**:
  - The GitHub Actions Service Account has only the necessary roles:
    - `roles/artifactregistry.writer`
    - `roles/container.developer`
    - `roles/iam.serviceAccountUser`
- **GKE RBAC**:
  - Access within the cluster is limited using RBAC policies. The Helm release uses a dedicated Service Account.

## 📦 Helm Chart

Helm chart located in the `helm-chart/` directory:
- Configurable values in `values.yaml`.
- Follows best practices for containerized workloads.

Example command (automated in GitHub Actions):

```bash
helm upgrade --install ping-pong-api-sv ./helm-chart \
  --set image.repository=us-central1-docker.pkg.dev/PROJECT_ID/REPO/IMAGE_NAME \
  --set image.tag=latest
```

## Verifying the Deployment
Check the deployed Docker image:

```
kubectl get deployment ping-pong-api-sv -o jsonpath='{.spec.template.spec.containers[0].image}'
```
Or automatically via GitHub Actions (see deploy.yml).

## Local Development
For local development:

```
docker build -t ping-pong-api .
docker run -p 3000:3000 ping-pong-api
```
Access the API at http://localhost:3000.

## **Best Practices Recap **

**CI/CD Security**:
- Use GitHub Actions secrets for sensitive data.
- Service Account with **minimal permissions**:
  - `artifactregistry.writer`
  - `container.developer`
- Avoid hardcoding sensitive data.

**GKE Best Practices**:
- Deploy using Helm for reproducibility.
- Use Docker multi-stage builds to keep images lightweight.
- Use `gke-gcloud-auth-plugin` for authentication (modern approach).

**Network Security**:
- Private Artifact Registry and GKE cluster.
- Service Account permissions limited by roles.
- Access to cluster via service account only.

**Helm Chart Design**:
- Parametrize values (image, tag, resources).
- Use dedicated Kubernetes Service Account for the app.


# Step-by-Step Guide: Setup, Build, and Deploy
1. Clone the Application Repository
```
git clone https://github.com/sfoxdev/ping-pong-api.git
cd ping-pong-api
```

2. Provision the GKE Cluster Using Terraform
Clone the Terraform Infrastructure Repository:
```
git clone https://github.com/sfoxdev/ping-pong-api-tf.git
cd ping-pong-api-tf
```
Authenticate to Google Cloud
Set your project ID:
```
export PROJECT_ID="ping-pong-api-sv"  # Replace with your project ID
gcloud auth login
gcloud config set project $PROJECT_ID
```
Initialize Terraform
```
terraform init
```
Review the Terraform Plan
```
terraform plan
```
Apply the Terraform Configuration
```
terraform apply
```

Terraform will:
- Create the GKE Cluster
- Set up necessary networking (VPC, subnets, firewall)
- Configure GCP resources as defined in the repo

Once the cluster is created, credentials for kubectl access can be fetched:
```
gcloud container clusters get-credentials ping-pong-cluster --zone us-central1-c
```
Verify access:
```
kubectl get nodes
```

3. Configure IAM Roles (Service Account for GitHub Actions)
Create the service account:
```
gcloud iam service-accounts create github-cicd \
  --description="GitHub Actions CI/CD Service Account" \
  --display-name="GitHub Actions CI/CD"
```
Grant necessary roles:
```
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-cicd@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/container.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-cicd@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-cicd@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.admin"
```
Generate a JSON key for GitHub Actions:
```
gcloud iam service-accounts keys create github-cicd-key.json \
  --iam-account=github-cicd@$PROJECT_ID.iam.gserviceaccount.com
```
Upload github-cicd-key.json as a GitHub secret (GCP_CREDENTIALS).

4. Docker Configuration for Artifact Registry
```
gcloud auth configure-docker us-central1-docker.pkg.dev
```

5. Build and Push Docker Image
```
docker build -t us-central1-docker.pkg.dev/$PROJECT_ID/ping-pong-repo/ping-pong-api:latest .
docker push us-central1-docker.pkg.dev/$PROJECT_ID/ping-pong-repo/ping-pong-api:latest
```

6. Deploy to GKE Using Helm
Install or upgrade:
```
helm upgrade --install ping-pong-api helm-chart/
```

7. Verify the Deployment
Check pods:
```
kubectl get pods
```
Check services:
```
kubectl get svc
```
Get the external IP:
```
kubectl get svc ping-pong-api-sv
```
Test the API:
```
curl http://<EXTERNAL-IP>/ping
```

8. Automate Everything with GitHub Actions
CI/CD is fully automated in .github/workflows/deploy.yml. On push to main:
- Builds and pushes Docker image
- Deploys with Helm to GKE

