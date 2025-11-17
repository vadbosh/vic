# !!!! 
cluster-name                = "thoth-production-b"
k8s_cidr_block_associations = "10.21.0.0/16"
cidr_create                 = false
region                      = "ap-southeast-2"
# !!!!
aws_internet_gateway_tag_name = "production-eks"
aws_vpcs_tag_name             = "production-eks"
max_nats                      = "1"
ssh_key_pair_name             = "k8s-thoth-production"
