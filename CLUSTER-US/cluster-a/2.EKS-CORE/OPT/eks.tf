
module "eks" {
  source                                   = "terraform-aws-modules/eks/aws"
  version                                  = "~> 20.0"
  cluster_name                             = var.cluster-name
  cluster_version                          = var.k8s-version
  cluster_endpoint_public_access           = false # !!
  enable_irsa                              = true  # !!
  enable_cluster_creator_admin_permissions = true
  create_cloudwatch_log_group              = false
  cloudwatch_log_group_retention_in_days   = 7
  cluster_encryption_config                = {} # !!
  vpc_id                                   = join("", data.aws_vpcs.net_workspace.ids)
  subnet_ids                               = data.aws_subnets.private.ids
  control_plane_subnet_ids                 = data.aws_subnets.public.ids

  depends_on = [module.sg_main_internal]

  cluster_upgrade_policy = { support_type = "STANDARD" }

  cluster_addons = {
    eks-pod-identity-agent = { most_recent = true }
    aws-ebs-csi-driver     = { most_recent = true }
    aws-efs-csi-driver     = { most_recent = true }
    coredns                = { most_recent = true }
    kube-proxy             = { most_recent = true }
    vpc-cni = {
      # !! https://github.com/aws/amazon-vpc-cni-k8s
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        enableNetworkPolicy = "true"
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
          ANNOTATE_POD_IP          = "true"
        }
      })
    }
  }

  cluster_security_group_additional_rules = {
    api_443 = {
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      description = "API-${var.cluster-name}-VPC"
      cidr_blocks = [var.k8s_cidr_block_associations]
    }
    compile2API_443 = {
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      description = "compile2API-${var.cluster-name}-VPC"
      cidr_blocks = [var.compile_cidr_block_associations]
    }
  }

  eks_managed_node_group_defaults = {
    ami_type                       = "AL2023_x86_64_STANDARD"
    use_latest_ami_release_version = true
    disk_size                      = 30
    min_size                       = 1
    max_size                       = 1
    desired_size                   = 1
    capacity_type                  = "ON_DEMAND"
    #capacity_type          = "SPOT"
    key_name = data.aws_key_pair.thoth_sandbox.key_name
    tags = {
      Environment = var.cluster-name
      Terraform   = true
    }
    iam_role_additional_policies = {
      AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      ThothECSMonitoring       = "arn:aws:iam::${var.aws_account_id}:policy/ThothECSMonitoring"
    }
    vpc_security_group_ids = [module.sg_main_internal.security_group_id]
    cloudinit_pre_nodeadm = [
      {
        content_type = "application/node.eks.aws"
        content      = <<-EOT
            ---
            apiVersion: node.eks.aws/v1alpha1
            kind: NodeConfig
            spec:
              kubelet:
                config:
                  shutdownGracePeriod: 30s
                  featureGates:
                    DisableKubeletCloudCredentialProviders: true
          EOT
      }
    ]
  }

  eks_managed_node_groups = {
    ingress-pool = {
      name            = format("%s-%s", var.cluster-name, "ingress")
      use_name_prefix = true
      instance_types  = ["c5a.large", "c5.large"]
      max_size        = 5
      capacity_type   = "ON_DEMAND"
      labels = {
        "eks-cluster/nodegroup" = format("%s-%s", var.cluster-name, "ingress")
      }
      launch_template_tags = {
        node-pool = format("%s-%s", var.cluster-name, "ingress")
      }
    },
    metrics-pool = {
      name            = format("%s-%s", var.cluster-name, "metrics")
      use_name_prefix = true
      instance_types  = ["c5a.large", "c5.large"]
      max_size        = 3
      labels = {
        "eks-cluster/nodegroup" = format("%s-%s", var.cluster-name, "metrics")
      }
      launch_template_tags = {
        node-pool = format("%s-%s", var.cluster-name, "metrics")
      }
    },
    large-pool = {
      name = format("%s-%s", var.cluster-name, "large")
      #vpc_security_group_ids = [module.sg_main_internal.security_group_id, module.sg_main_efs.security_group_id]
      instance_types  = ["m5a.large", "m5.large"]
      use_name_prefix = true
      max_size        = 10
      #capacity_type          = "SPOT"
      labels = {
        "eks-cluster/nodegroup" = format("%s-%s", var.cluster-name, "large")
      }
      launch_template_tags = {
        node-pool = format("%s-%s", var.cluster-name, "large")
      }
    },
    xlarge-pool = {
      name = format("%s-%s", var.cluster-name, "xlarge")
      #vpc_security_group_ids = [module.sg_main_internal.security_group_id, module.sg_main_efs.security_group_id]
      instance_types  = ["m5a.xlarge", "m6a.xlarge", "m5.xlarge"]
      use_name_prefix = true
      max_size        = 10
      labels = {
        "eks-cluster/nodegroup" = format("%s-%s", var.cluster-name, "xlarge")
      }
      launch_template_tags = {
        node-pool = format("%s-%s", var.cluster-name, "xlarge")
      }
    }
  }
}


