terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.39.1" # Pinned stable version
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = var.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0" # Pinned stable version

  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # IAM Configuration
  create_iam_role = true
  iam_role_name   = "${var.cluster_name}-eks-role"
  
  iam_role_additional_policies = {
    AmazonEKS_CNI_Policy = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  }

  # Disable problematic aws-auth management
  create_aws_auth_configmap = false
  manage_aws_auth_configmap = false

  # Node Group Configuration (simplified)
  eks_managed_node_groups = {
    default = {
      name            = "default-node-group"
      min_size        = 1
      max_size        = 3
      desired_size    = 2
      instance_types  = ["t3.medium"]
      capacity_type   = "ON_DEMAND"
      
      # Basic launch template
      launch_template = {
        name    = "default-lt"
        version = "$Default"
      }
    }
  }

  # Cluster Addons
  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  tags = var.tags
}

# Output for manual aws-auth configuration
output "aws_auth_config" {
  value = <<EOT
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${module.eks.cluster_iam_role_arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: ${module.eks.eks_managed_node_groups["default"].iam_role_arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
EOT
  sensitive = true
}

output "configure_kubectl" {
  value = <<EOT
Run these commands to configure kubectl:
aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}
kubectl apply -f <(echo "$(terraform output -raw aws_auth_config)")
EOT
}
