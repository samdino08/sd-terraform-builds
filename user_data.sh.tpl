#!/bin/bash
set -euxo pipefail

# --- System update ---
yum update -y

# --- Java (Jenkins requires Java 17 on modern versions) ---
amazon-linux-extras enable corretto17 || true
yum install -y java-17-amazon-corretto-devel git wget

# --- Jenkins repo + install ---
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
yum install -y jenkins

# --- Enable and start Jenkins ---
systemctl daemon-reload
systemctl enable jenkins
systemctl start jenkins

# --- Wait for Jenkins to generate its initial admin password, then log it ---
for i in {1..30}; do
  if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    break
  fi
  sleep 5
done

echo "Jenkins initial admin password:" > /var/log/jenkins-initial-password.log
cat /var/lib/jenkins/secrets/initialAdminPassword >> /var/log/jenkins-initial-password.log 2>/dev/null || true
