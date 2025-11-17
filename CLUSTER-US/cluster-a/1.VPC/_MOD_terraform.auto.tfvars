# !!!! 
cluster-name                = "thoth-production-a"
k8s_cidr_block_associations = "10.10.0.0/16"
cidr_create                 = true
region                      = "us-east-1"
# !!!!
aws_internet_gateway_tag_name = "production-eks"
aws_vpcs_tag_name             = "production-eks"
max_nats                      = "1"
ssh_key_pair_name             = "k8s-thoth-production"
security_group_names          = ["ingress-nginx", "ingress-nginx-shared"]
