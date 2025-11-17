
module "eks" {
  source                                   = "terraform-aws-modules/eks/aws"
  version                                  = "21.3.2"
  name                                     = var.cluster-name
  kubernetes_version                       = var.k8s-version
  endpoint_public_access                   = false # !!
  enable_irsa                              = true  # !!
  enable_cluster_creator_admin_permissions = true
  create_cloudwatch_log_group              = false
  cloudwatch_log_group_retention_in_days   = 7
  encryption_config                        = {} # !!
  vpc_id                                   = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids                               = data.terraform_remote_state.network.outputs.private_subnet_ids
  control_plane_subnet_ids                 = data.terraform_remote_state.network.outputs.public_subnet_ids
  depends_on                               = [module.sg_main_internal, module.sg_main_efs]
  force_update_version                     = true
  upgrade_policy                           = { support_type = "STANDARD" }
  timeouts = {
    create = "90m"
    delete = "90m"
    update = "90m"
  }

  compute_config = null
  #  cluster_compute_config = {
  #  enabled = false
  #}

  addons = {
    eks-pod-identity-agent = { most_recent = true }
    aws-ebs-csi-driver     = { most_recent = true }
    aws-efs-csi-driver     = { most_recent = true }
    coredns                = { most_recent = true }
    kube-proxy             = { most_recent = true }
    vpc-cni = { # !! https://github.com/aws/amazon-vpc-cni-k8s
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        enableNetworkPolicy = "true"
        env = {
          ENABLE_PREFIX_DELEGATION           = "true"
          WARM_PREFIX_TARGET                 = "1"
          ANNOTATE_POD_IP                    = "true"
          AWS_VPC_K8S_CNI_EXCLUDE_SNAT_CIDRS = "172.30.0.0/16,172.31.0.0/16"
          AWS_VPC_K8S_CNI_EXTERNALSNAT       = "false"
        }
      })
    }
  }

  security_group_additional_rules = {
    api_443 = {
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      description = "API-${var.cluster-name}-VPC"
      cidr_blocks = [data.terraform_remote_state.network.outputs.cluster_top_cidr]
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

  eks_managed_node_groups = {
    for group_name, config in local.node_group_configs : group_name => merge(
      {
        ami_type                       = "AL2023_x86_64_STANDARD"
        cluster_version                = var.k8s-version
        use_latest_ami_release_version = true
        disk_size                      = 30
        min_size                       = 1
        max_size                       = 1
        desired_size                   = 1
        capacity_type                  = "ON_DEMAND"
        vpc_security_group_ids         = [module.sg_main_internal.security_group_id]
        force_update_version           = true
        key_name                       = data.terraform_remote_state.network.outputs.key_name
        name                           = format("%s-%s", substr(var.cluster-name, 0, 10), group_name)
        use_name_prefix                = true

        timeouts = {
          create = "90m"
          update = "90m"
          delete = "90m"
        }

        update_config = {
          max_unavailable_percentage = 10 # 1 node per time
        }

        tags = {
          Environment     = var.cluster-name
          Terraform       = true
          "k8s/node-role" = group_name
        }

        iam_role_additional_policies = {
          AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
          ThothECSMonitoring       = "arn:aws:iam::${var.aws_account_id}:policy/ThothECSMonitoring"
        }

        # !!! https://awslabs.github.io/amazon-eks-ami/nodeadm/
        # !!! kubectl get --raw "/api/v1/nodes/<node_name>/proxy/configz" | jq
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
                  shutdownGracePeriod: 60s 
          EOT
          },
          {
            content_type = "text/x-shellscript"
            content      = base64decode(filebase64("${path.module}/cloud_init_script.sh"))
          }
        ]

        labels = {
          "eks-cluster/nodegroup" = format("%s-%s", var.nodegroup_prefix, group_name)
          "k8s/node-role"         = group_name # !!! for Node Roles !!!
        }

        launch_template_tags = {
          node-pool = format("%s-%s", var.cluster-name, group_name)
        }
      },
      config
    )
  }
}

locals {
  node_group_configs = {
    "ingress" = {
      instance_types = ["c5a.large", "c5.large"]
      max_size       = local.node_max_size.ingress
    },
    "metrics" = {
      instance_types = ["c5a.large", "c5.large"]
      max_size       = local.node_max_size.metrics
    },
    "large" = {
      instance_types = ["m5a.large", "m5.large"]
      max_size       = local.node_max_size.large
    },
    "xlarge" = {
      instance_types = ["m5a.xlarge", "m6a.xlarge", "m5.xlarge"]
      max_size       = local.node_max_size.xlarge
    },
    "debug" = {
      instance_types         = ["m5a.xlarge", "m5.xlarge"]
      max_size               = local.node_max_size.debug
      vpc_security_group_ids = [module.sg_main_internal.security_group_id, module.sg_main_efs.security_group_id]
    }
  }
}

