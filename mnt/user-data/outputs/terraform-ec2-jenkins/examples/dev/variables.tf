variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Existing EC2 key pair name"
  type        = string
}

variable "vpc_id" {
  description = "VPC to launch the instance in"
  type        = string
}

variable "subnet_id" {
  description = "Subnet to launch the instance in"
  type        = string
}

variable "my_ip_cidr" {
  description = "Your IP in CIDR form, e.g. 203.0.113.5/32, for restricted SSH/Jenkins access"
  type        = string
}
