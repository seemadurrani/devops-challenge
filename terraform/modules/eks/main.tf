module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # IAM Configuration
  create_iam_role = true
  iam_role_name   = "${var.cluster_name}-eks-role"
  
  iam_role_additional_policies = {
    AmazonEKS_CNI_Policy = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  }

  # COMPLETELY DISABLE aws-auth management in the module
  create_aws_auth_configmap = false
  manage_aws_auth_configmap = false

  # Node Group Configuration
  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["t3.medium"]
  }

  eks_managed_node_groups = {
    primary = {
      name           = "node-group-1"
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      capacity_type  = "ON_DEMAND"
      instance_types = ["t3.medium"]
    }
  }

  tags = var.tags
}

# Create output with the aws-auth configuration
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
    - rolearn: ${module.eks.eks_managed_node_groups["primary"].iam_role_arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
EOT
  sensitive = true
}
