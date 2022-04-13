

# Prerequisites
```
- a AWS account 
- a configured AWS CLI
- AWS IAM Authenticator
- kubectl
```
# config AWS CLI
```
aws configure
AWS Access Key ID [None]: YOUR_AWS_ACCESS_KEY_ID
AWS Secret Access Key [None]: YOUR_AWS_SECRET_ACCESS_KEY
Default region name [None]: YOUR_AWS_REGION
Default output format [None]: json
```
# Set up and initialize your workspace
git clone https://github.com/fredfrazao/eks_Demo
```
make init-terraform
```

# Provision an EKS Cluster
```
make setup-eks-cluster
```

# GET and Configure kubeconfig
```
make get-kubeconfig
```

# Destroy an EKS Cluster
```
make destroy-eks-cluster
```
