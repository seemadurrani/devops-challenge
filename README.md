# AWS EKS Cluster with ALB and Nginx Deployment

## Overview

This project provisions a secure, production-ready EKS cluster using Terraform, deploys a sample Nginx application using Helm, and manages it via Argo CD for GitOps.

![Architecture Diagram](./devops-challenge.drawio)

## Architecture Components

### Core Infrastructure

| Component             | Purpose                                                  |
|-----------------------|----------------------------------------------------------|
| VPC                   | Isolated network with public and private subnets         |
| Internet Gateway      | Enables public internet access (for ALB)                 |
| NAT Gateway           | Secure outbound access for private subnets               |
| EKS Control Plane     | Managed Kubernetes API server (highly available)         |

### Application Layer

| Component             | Description                                              |
|-----------------------|----------------------------------------------------------|
| Worker Node Group     | EC2 instances in private subnets (e.g., t3.medium)       |
| Application ALB       | Load balancer to route external traffic to the cluster   |
| Nginx Deployment      | Helm-based deployment with 2 replicas                    |

## Data Flow

```mermaid
flowchart LR
    A[Internet] --> B[ALB]
    B --> C[Public Subnet]
    C --> D[Private Subnet Worker Nodes]
    D --> E[Nginx Pods]
    E -->|Logs| F[CloudWatch]
    D -->|Outbound| G[NAT Gateway]
Security Implementation
Least Privilege: Nodes only get necessary permissions

IRSA: IAM Roles for Service Accounts for pods

EKS-Cluster-Role: Cluster management

EKS-Node-Role: Worker node operations

ALB: Only ports 80/443 open

Worker Nodes: Only allow traffic from ALB SG (port 30000–32768)

Control Plane: Private endpoint with restricted CIDR

Steps to Reproduce the Setup
Prerequisites
AWS CLI configured with access and secret keys

Terraform installed

kubectl installed

Helm installed

jq and base64 CLI tools

Clone the repository:
git clone https://github.com/seemadurrani/devops-challenge.git
cd devops-challenge

Provision the EKS cluster with Terraform:
cd terraform
export AWS_ACCESS_KEY_ID=<your-access-key>
export AWS_SECRET_ACCESS_KEY=<your-secret-key>
terraform init
terraform apply

Configure kubeconfig:
aws eks --region <your-region> update-kubeconfig --name <cluster-name>

Deploy the sample application using Helm:
cd ../helm
helm install nginx-app .
kubectl get svc
(Note the EXTERNAL-IP from the LoadBalancer service)

Install Argo CD:
cd ../argocd
chmod +x install-argocd-on-k8s.sh
./install-argocd-on-k8s.sh

Get the Argo CD admin password:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

Access Argo CD UI:
kubectl port-forward svc/argocd-server -n argocd 8080:443
Open https://localhost:8080
Login with username: admin and password from previous step

Deploy via Argo CD:
kubectl apply -f argocd/argocd-manifest.yaml

Result
EKS cluster provisioned by Terraform

Helm-deployed application

GitOps workflow with Argo CD

