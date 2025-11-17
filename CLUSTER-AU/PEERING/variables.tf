variable "region" {
  description = "The name of the AWS Region"
  type        = string
}

variable "aws_vpc_acceptor" {
  type = string
}

variable "aws_vpc_requestor" {
  type = string
}
