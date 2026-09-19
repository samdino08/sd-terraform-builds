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

# Make sure java 21 is what's on PATH (in case an older JDK is also present).
# Resolve the real binary path from the installed package instead of
# guessing the jvm directory name (it varies, e.g. with/without an
# architecture suffix like .x86_64).
JAVA21_BIN=$(rpm -ql java-21-amazon-corretto-devel | grep -E '/bin/java$' | head -n1)
if [ -z "$JAVA21_BIN" ]; then
  echo "ERROR: could not locate the java-21 binary from the installed package" >&2
  rpm -ql java-21-amazon-corretto-devel >&2
  exit 1
fi
alternatives --install /usr/bin/java java "$JAVA21_BIN" 2100
alternatives --set java "$JAVA21_BIN"

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
