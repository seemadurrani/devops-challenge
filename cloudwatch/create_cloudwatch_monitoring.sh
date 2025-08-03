#!/bin/bash

# --------- CONFIG ---------
CLUSTER_NAME="your-cluster-name"
REGION="your-region"
ACCOUNT_ID="your-account-id"
POLICY_NAME="eks-fluentbit-cloudwatch-policy"
NAMESPACE="amazon-cloudwatch"
SERVICE_ACCOUNT_NAME="fluent-bit"
# --------------------------

set -e

echo "Creating IAM policy for Fluent Bit..."

aws iam create-policy \
  --policy-name $POLICY_NAME \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        "Resource": "*"
      }
    ]
  }' || echo "Policy already exists, skipping."

echo "Creating Kubernetes namespace for CloudWatch logging..."
kubectl create namespace $NAMESPACE || echo "Namespace already exists."

echo "Creating IAM role for service account (IRSA)..."

eksctl create iamserviceaccount \
  --name $SERVICE_ACCOUNT_NAME \
  --namespace $NAMESPACE \
  --cluster $CLUSTER_NAME \
  --attach-policy-arn arn:aws:iam::$ACCOUNT_ID:policy/$POLICY_NAME \
  --approve \
  --override-existing-serviceaccounts

echo "Downloading and applying Fluent Bit config..."

curl -O https://raw.githubusercontent.com/aws/containers-roadmap/main/preview-programs/fluent-bit/aws-observability/fluent-bit.yaml

echo "Patching service account name in Fluent Bit config..."
sed -i '' "s/serviceAccountName: fluent-bit/serviceAccountName: $SERVICE_ACCOUNT_NAME/" fluent-bit.yaml

echo "Deploying Fluent Bit to EKS..."
kubectl apply -f fluent-bit.yaml

echo "✅ Fluent Bit deployed. Logs from all pods (including nginx) should now stream to CloudWatch."
