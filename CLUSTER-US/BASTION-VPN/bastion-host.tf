
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.openvpn-infra.id
  allocation_id = aws_eip.openvpn-infra.id
  depends_on    = [aws_instance.openvpn-infra]
}

resource "aws_instance" "openvpn-infra" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3a.nano"
  key_name      = data.terraform_remote_state.network.outputs.key_name
  subnet_id     = data.terraform_remote_state.network.outputs.public_subnet_ids[0]
  #  vpc_security_group_ids = [aws_security_group.openvpn-infra.id]
  vpc_security_group_ids = [data.aws_security_group.selected.id]
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
  }
  volume_tags = {
    Name = format("%s-%s", var.vpn_hostname, random_string.suffix.result)
  }
  tags = {
    Name      = format("%s-%s", var.vpn_hostname, random_string.suffix.result)
    Terraform = true
  }
  #  depends_on = [
  #  aws_security_group.openvpn-infra,
  # ]
  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_eip" "openvpn-infra" {
  domain = "vpc"
  tags = {
    Name = format("%s-%s-%s", var.vpn_hostname, "eip", random_string.suffix.result)
  }
}
/*
resource "aws_security_group" "openvpn-infra" {
  name   = format("%s-%s", var.vpn_hostname, "Security-Group")
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  dynamic "ingress" {
    for_each = ["22"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["130.162.217.144/32", "130.162.34.41/32", "172.31.0.0/16"]
    }
  }
  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = format("%s-%s", var.vpn_hostname, "Security-Group")
  }
}
*/
output "eip_ip" {
  value = aws_eip.openvpn-infra.public_ip
}

output "vpn_aws_security_group_id" {
  value = data.aws_security_group.selected.id
}

