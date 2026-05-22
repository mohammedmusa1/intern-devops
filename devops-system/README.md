# ONE-CLICK ENTERPRISE DEVOPS DEPLOYMENT SYSTEM

This repository contains a fully automated, production-style DevOps deployment system utilizing Terraform, AWS, K3s, Jenkins, ArgoCD, Prometheus, Grafana, Docker, Helm, and GitHub Webhooks.

## Architecture & Flow

1. **Terraform** provisions the underlying AWS EC2 (`t3.large` or `m7i-flex.large`), VPC, Security Groups, and SSH Keys.
2. **Cloud-init (userdata)** runs on boot to install Docker and a lightweight **K3s Kubernetes cluster**.
3. It installs **Helm** and automatically deploys the entire stack:
   - **Ingress NGINX**: Exposing services.
   - **Jenkins**: Configured via JCasC (Configuration as Code). Automatically sets up the pipeline from this repository.
   - **ArgoCD**: Auto-sync and Self-heal enabled. Pre-configured with the application manifests.
   - **Prometheus & Grafana**: Pre-configured monitoring stack.
4. **Jenkins Pipeline** builds the Docker image and updates the Kubernetes manifests in Git.
5. **ArgoCD** detects the change in the Git repository and deploys the new image to the K3s cluster.

## Deployment Instructions

### Prerequisites
- Install [Terraform](https://developer.hashicorp.com/terraform/downloads)
- Configure AWS credentials (`aws configure`)

### 1. Configuration
Navigate to the terraform directory:
```bash
cd devops-system/terraform
```

Rename the tfvars template:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Update `terraform.tfvars` with your secrets (GitHub PAT, DockerHub credentials, etc).

### 2. Deploy
Run the standard Terraform commands:
```bash
terraform init
terraform apply -auto-approve
```

> **Note**: Terraform will finish in a few minutes, but the EC2 instance needs ~10-15 minutes to finish installing Docker, K3s, Helm, Jenkins, ArgoCD, Prometheus, and Grafana in the background.

### 3. Access the Services
After completion, Terraform will output the URLs:
- **Jenkins**: `http://<Public-IP>:30080` (Username: `admin`, Password: `admin`)
- **ArgoCD**: `http://<Public-IP>:30081` (Username: `admin`, Password: `admin`)
- **Grafana**: `http://<Public-IP>:30082` (Username: `admin`, Password: `admin`)
- **Prometheus**: `http://<Public-IP>:30090`
- **Application**: `http://<Public-IP>:30000`

### 4. Teardown
To completely remove the entire infrastructure cleanly:
```bash
terraform destroy -auto-approve
```

## Security Group Ports
- **22**: SSH
- **80 / 443**: HTTP / HTTPS
- **6443**: Kubernetes API
- **30080**: Jenkins
- **30081**: ArgoCD
- **30082**: Grafana
- **30090**: Prometheus
- **30000**: Application (via Ingress)
