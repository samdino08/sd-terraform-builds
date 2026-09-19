terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "jenkins_server" {
  source = "../../modules/ec2-jenkins"

  instance_name        = "jenkins-dev"
  instance_type         = "t3.medium"
  key_name              = var.key_name
  vpc_id                = var.vpc_id
  subnet_id             = var.subnet_id
  allowed_ssh_cidr_blocks     = [var.my_ip_cidr]
  allowed_jenkins_cidr_blocks = [var.my_ip_cidr]

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

output "jenkins_url" {
  value = module.jenkins_server.jenkins_url
}

output "instance_public_ip" {
  value = module.jenkins_server.public_ip
}
