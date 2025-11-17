provider "external" {}

provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "sydney"
  region = var.aws_vpc_acceptor_region
}

