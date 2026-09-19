output "instance_id" {
  description = "ID of the Jenkins EC2 instance"
  value       = aws_instance.jenkins.id
}

output "public_ip" {
  description = "Public IP address of the Jenkins server"
  value       = aws_instance.jenkins.public_ip
}

output "private_ip" {
  description = "Private IP address of the Jenkins server"
  value       = aws_instance.jenkins.private_ip
}

output "security_group_id" {
  description = "ID of the security group attached to the instance"
  value       = aws_security_group.jenkins.id
}

output "jenkins_url" {
  description = "URL to access the Jenkins web UI"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}
