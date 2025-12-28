# AWS SSM Parameter Store to Kubernetes Secret Terraform Module

This Terraform module fetches parameters from AWS Systems Manager (SSM) Parameter Store and creates a Kubernetes secret with the retrieved values.

## Purpose

This module simplifies the process of securely managing secrets in Kubernetes. Instead of hardcoding sensitive data in your Terraform configurations, you can store them in AWS SSM Parameter Store and use this module to inject them into your Kubernetes cluster as secrets.

## Usage

Here's an example of how to use this module:

```hcl
module "my_app_secrets" {
  source = "./modules/ssm-k8s-secret"

  secret_name      = "my-app-secrets"
  secret_namespace = "my-app-namespace"

  ssm_parameters = {
    DB_USERNAME = "/my-app/db/username"
    DB_PASSWORD = "/my-app/db/password"
  }
}
```

## Inputs

| Name               | Description                                                                    | Type         | Default  | Required |
| ------------------ | ------------------------------------------------------------------------------ | ------------ | -------- | :------: |
| `secret_name`      | The name of the Kubernetes secret to create.                                   | `string`     | -        |   yes    |
| `secret_namespace` | The namespace in which to create the Kubernetes secret.                        | `string`     | -        |   yes    |
| `ssm_parameters`   | A map where keys are the secret keys and values are the SSM parameter paths.     | `map(string)`| -        |   yes    |
| `secret_type`      | The type of the Kubernetes secret.                                             | `string`     | `"Opaque"` |    no    |

## Outputs

| Name                | Description                   |
| ------------------- | ----------------------------- |
| `kubernetes_secret` | The created Kubernetes secret resource. |
