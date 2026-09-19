#!/bin/bash
set -euxo pipefail

# --- System update ---
yum update -y

# --- Java (Jenkins now requires Java 21) ---
# Pull Corretto 21 from Amazon's own repo rather than amazon-linux-extras,
# since extras topic availability varies across AL2 AMI releases.
rpm --import https://yum.corretto.aws/corretto.key
curl -Lo /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
yum install -y java-21-amazon-corretto-devel git wget

# Make sure java 21 is what's on PATH (in case an older JDK is also present)
alternatives --install /usr/bin/java java /usr/lib/jvm/java-21-amazon-corretto/bin/java 2100 || true
alternatives --set java /usr/lib/jvm/java-21-amazon-corretto/bin/java || true

java -version

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
