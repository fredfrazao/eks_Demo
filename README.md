

# Prerequisites
```
- a AWS account 
- a configured AWS CLI
- AWS IAM Authenticator
- kubectl
```
# configuration local env
```
aws configure
AWS Access Key ID [None]: YOUR_AWS_ACCESS_KEY_ID
AWS Secret Access Key [None]: YOUR_AWS_SECRET_ACCESS_KEY
Default region name [None]: YOUR_AWS_REGION
Default output format [None]: json
```
# Set up and initialize your Terraform workspace
git clone https://github.com/fredfrazao/eks_Demo
```
- terraform init
- terraform plan
make init-terraform
```

# Provision an EKS Cluster
```
- terraform apply 
make setup-eks-cluster
```

# GET and Configure kubectl
```
aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)
```

# Destroy an EKS Cluster
```
- terraform destroy
make destroy-eks-cluster
```
