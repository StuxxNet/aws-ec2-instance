provider "aws" {
  # Configuration options
  region = "eu-central-1"
}

locals {
  instance_type    = "t3.large"
  root_volume_size = 40
  private_ip       = "172.31.0.10"
  security_group_rules = {
    "ssh" = {
      type        = "ingress"
      port        = 22
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "http" = {
      type        = "ingress"
      port        = 80
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
    "outbound" = {
      type        = "egress"
      port        = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

data "aws_vpc" "selected" {
  id = "vpc-0d7ee178466caab08"
}

data "aws_subnet" "selected" {
  id = "subnet-07679ba9b8dee988f"
}

resource "tls_private_key" "access_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

module "aws_ec2" {
  source               = "git::https://github.com/StuxxNet/iac-aws-ec2?ref=v1.1.0"
  vpc_id               = data.aws_vpc.selected.id
  subnet_id            = data.aws_subnet.selected.id
  private_ip           = local.private_ip
  security_group_rules = local.security_group_rules
  public_access_key    = tls_private_key.access_key.public_key_openssh
  instance_type        = local.instance_type
  root_volume_size     = local.root_volume_size
}

output "public_ip" {
  value = module.aws_ec2.public_ip
}

resource "local_file" "private_key" {
  content  = tls_private_key.access_key.private_key_pem
  filename = "private_key.pem"
}