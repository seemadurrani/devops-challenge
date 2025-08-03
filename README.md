# AWS EKS Cluster with ALB and Nginx Deployment

## 📌 Overview
Terraform-managed EKS cluster with secure networking, IAM roles, and Helm-deployed Nginx.

![Architecture Diagram](./devops-challenge.drawio)

## 🏗️ Architecture Components

### Core Infrastructure
| Component               | Purpose                                                                 |
|-------------------------|-------------------------------------------------------------------------|
| **VPC**                 | Isolated network with public/private subnets across 2 AZs               |
| **Internet Gateway**    | Public internet access for ALB                                         |
| **NAT Gateway**         | Secure outbound internet for worker nodes                              |
| **EKS Control Plane**   | Managed Kubernetes API server                                          |

### Application Layer
| Component               | Description                                                             |
|-------------------------|-------------------------------------------------------------------------|
| **Worker Node Group**   | EC2 instances in private subnets (t3.medium)                           |
| **Application ALB**     | Distributes traffic across worker nodes                                |
| **Nginx Deployment**    | Helm-managed pods with 2 replicas                                      |

## 🔄 Data Flow

```mermaid
flowchart LR
    A[Internet] --> B[ALB]
    B --> C[Public Subnet]
    C --> D[Private Subnet Worker Nodes]
    D --> E[Nginx Pods]
    E -->|Logs| F[CloudWatch]
    D -->|Outbound| G[NAT Gateway]

