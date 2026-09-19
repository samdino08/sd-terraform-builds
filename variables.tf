variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "sd-tf-jenkins-server"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "c7i-flex.large" # Jenkins needs more than t2.micro to run comfortably
}

variable "ami_id" {
  description = "AMI ID to use. Defaults to the latest Amazon Linux 2 AMI if left null."
  type        = string
  default     = ami-0aeec3e3fd048bf12
}

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH access"
  type        = windows
}

variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = vpc-06f412ee7552bbc3a
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = subnet-03fccbf9124959c5a
}

variable "allowed_ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH into the instance"
  type        = list(string)
  default     = ["0.0.0.0/0"] # tighten this to your own IP in production
}

variable "allowed_jenkins_cidr_blocks" {
  description = "CIDR blocks allowed to reach the Jenkins web UI (port 8080)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # tighten this to your own IP/VPN in production
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 30
}

variable "associate_public_ip" {
  description = "Whether to assign a public IP to the instance"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
