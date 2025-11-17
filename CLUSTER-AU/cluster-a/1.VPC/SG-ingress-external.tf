resource "aws_security_group" "externally_managed_rules_sg" {
  for_each = toset(var.security_group_names)
  #name        =  join("-", each.key, var.cluster-name)
  name        = "${each.key}-${var.cluster-name}"
  description = "The rules for SG ${each.key} are managed externally"
  vpc_id      = join("", data.aws_vpcs.net_workspace.ids)

  dynamic "ingress" {
    for_each = var.ingress_ports
    content {
      description = "Allow TCP on port ${ingress.value} from within VPC"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes = [
      ingress,
      egress,
    ]
  }

  tags = {
    Name      = each.key
    ManagedBy = "Terraform (Initial Create Only)"
  }
}



