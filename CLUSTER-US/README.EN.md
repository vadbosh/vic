# Terraform Infrastructure Documentation

## 🔹 Important

*   The `terraform_remote_state` mechanism is used to transfer data between components.
    *   The `1.VPC/` component creates states accessible to other components.
    *   The `2.EKS-CORE/` component inherits this state and adds its own state.

```hcl
s3_key_vpc_data             = "ap-southeast-2/cluster_name/vpc-a/terraform.tfstate"
s3_key_eks_data             = "ap-southeast-2/cluster_name/eks-core-a/terraform.tfstate"
```

*   Other components inherit (use) data via the `terraform_remote_state` data source mechanism:

```hcl
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "bucket_name"
    key    = var.s3_key_vpc_data
    region = "us-east-1"
  }
}
```

*   Each component MUST have its own backend (S3) defined via the `_MOD_backend-config.tfvars` file. This file specifies the parameters for remote Terraform state storage and MUST be set BEFORE running `init`.

## 1. General Project Description

This project implements the deployment of cloud infrastructure in AWS using Terraform. It consists of several components that provide configuration for:

*   network infrastructure (VPC);
*   Kubernetes cluster (EKS);
*   additional services within the cluster (CRDs, Helm, ingress, etc.);
*   connections via VPN (Bastion);
*   peering between VPCs (Peering);
*   security parameters and roles.

## 2. Requirements

*   Terraform >= 1.0
*   AWS CLI, configured user profile
*   AWS access permissions to manage resources (EC2, IAM, EKS, VPC, etc.)

## 3. Component Description

### 3.1 VPC (1.VPC)

*   **Purpose**: Creates a VPC network with subnets, routes, and internet gateways.
*   **Features**: Creates subnets for EKS, exports parameters to Outputs.

### 3.2 EKS-CORE (2.EKS-CORE)

*   **Purpose**: Deploys the main Kubernetes cluster with node groups.
*   **Features**: Supports Pod Identity, IAM roles, and various Security Groups (SG), exports parameters to Outputs.

### 3.3 EKS-SERVICES (3.EKS-SERVICES)

*   **Purpose**: Installs services within the EKS cluster (ALB, autoscaler, ingress, etc.).
*   **Modules**: `modules/rbac-*`, `modules/helm-version`

### 3.4 EKS-CRD (4.EKS-CRD)

*   **Purpose**: Installs CRDs and network policies (KEDA, cert-manager, Cilium).
*   **Modules**: `modules/helm-version`

### 3.5 PEERING

*   **Purpose**: Configures VPC Peering between **VPCs in the same or different AWS regions**.
*   **Important**: PEERING does not establish a direct connection between `cluster-a` and `cluster-b` as clusters, but only between the EKS VPC and other VPCs.

### 3.6 BASTION-VPN

*   **Purpose**: Creates a bastion host with the ability to connect into the VPC.

## 4. Deployment

Deployment order (`cluster-b` is the standby cluster):

1.  `cluster-a/1.VPC`
2.  `cluster-b/1.VPC`
3.  `BASTION-VPN` — OpenVPN is deployed on the created instance
4.  `PEERING` — creates a connection between VPCs in the same or different AWS regions
5.  `cluster-a/2.EKS-CORE` — After `EKS-CORE` deployment it is necessary to create `Kube config` to enable connection to the cluster and deployment of other components   
    `aws eks --region us-east-1 update-kubeconfig --name cluster-name`
6.  `cluster-a/3.EKS-SERVICES`
7.  `cluster-a/4.EKS-CRD`

Before applying, ensure that **all files matching** "`_MOD_*`" have been checked and edited as necessary in each section.

### Deployment Commands

```bash
terraform init -backend-config="_MOD_backend-config.tfvars"
terraform validate
terraform plan
terraform apply
```

## 5. Resource Destruction

Only the following components are subject to destruction (**others require separate approval**):

*   `cluster-a/4.EKS-CRD` -> `cluster-a/3.EKS-SERVICES` -> `cluster-a/2.EKS-CORE`

Command for destruction:

```bash
terraform destroy
```

## 6. Notes

*   Separation into `cluster-a` and `cluster-b` clusters is used.
*   Inside EKS, Helm, IAM Roles for Service Accounts (IRSA), and other AWS best practices are used.
