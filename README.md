# Fluent Bit Terraform Module

This Terraform module deploys and configures Fluent Bit on a Kubernetes cluster.

## Project Overview

This project uses Terraform to deploy Fluent Bit, a lightweight log processor and forwarder, to a Kubernetes cluster. It uses the official Fluent Bit Helm chart and is configured to ship logs to a PostgreSQL database.

The key features of this project are:
- Deployment of Fluent Bit as a DaemonSet.
- Configuration of Fluent Bit to collect logs from various sources, including Kubernetes events, container logs, and systemd.
- Filtering and enrichment of logs using Lua scripts and other Fluent Bit filters.
- Secure storage of database credentials using AWS SSM Parameter Store and Kubernetes Secrets.
- Output of logs to a PostgreSQL database.

## Prerequisites

Before you can apply this Terraform configuration, you need to have the following installed and configured:

- Terraform >= 0.14
- An AWS account with the necessary permissions.
- AWS CLI configured with credentials.
- `kubectl` configured to connect to your Kubernetes cluster.
- Access to the S3 bucket used for the Terraform backend.

## Configuration

1.  **Backend Configuration:**

    Create a `backend-config.tfvars` file with the following content to configure the S3 backend for Terraform:

    ```hcl
    bucket         = "your-terraform-state-bucket"
    key            = "path/to/your/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "your-terraform-lock-table"
    ```

2.  **Terraform Variables:**

    Create a `terraform.auto.tfvars` file to provide values for the required variables:

    ```hcl
    s3_key_eks_data = "path/to/eks/data.json"
    s3_key_vpc_data = "path/to/vpc/data.json"
    ```

## Deployment

1.  **Initialize Terraform:**

    Run the following command to initialize the Terraform backend and download the required providers:

    ```bash
    terraform init -backend-config="backend-config.tfvars"
    ```

2.  **Plan the Deployment:**

    Run the following command to see the changes that Terraform will apply:

    ```bash
    terraform plan
    ```

3.  **Apply the Configuration:**

    Run the following command to deploy Fluent Bit to your Kubernetes cluster:

    ```bash
    terraform apply
    ```

## Project Structure

-   `terraform.tf`: Defines the required Terraform version and providers.
-   `provider.tf`: Configures the AWS, Helm, and Kubernetes providers.
-   `variables.tf`: Defines the variables used in the Terraform configuration.
-   `fluent_bit.tf`: Deploys the Fluent Bit Helm chart.
-   `fluent-bit-values.yaml`: Contains the configuration values for the Fluent Bit Helm chart.
-   `parameter_store.tf`: Retrieves database credentials from AWS SSM Parameter Store and creates a Kubernetes secret.
-   `fluent_bit_lua_script.tf`: Creates a Kubernetes ConfigMap for the Lua script.
-   `ext.data.tf`: Defines external data sources.
-   `scripts/`: Contains helper scripts.
    -   `fluent-bit-lua.lua`: Lua script for filtering and enriching logs.
-   `_MOD_backend-config.tfvars`: Example backend configuration file.
-   `_MOD_terraform.auto.tfvars`: Example variables file.
