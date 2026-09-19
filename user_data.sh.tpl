#!/bin/bash
set -euxo pipefail

exec > >(tee -a /var/log/user-data-custom.log) 2>&1
echo "=== user_data started at $(date -u) ==="

# --- System update ---
yum update -y

# --- Java (Jenkins requires Java 21) ---
# Pull Corretto 21 straight from Amazon's own repo rather than
# amazon-linux-extras, which does not exist at all on AL2023 and has
# inconsistent topic availability on AL2.
rpm --import https://yum.corretto.aws/corretto.key
curl -fLo /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
yum install -y java-21-amazon-corretto-devel git wget

echo "=== Locating java-21 binary ==="
JAVA21_BIN=""

# 1) It may already be first on PATH (Corretto's RPM postinstall usually
#    registers it with alternatives automatically on a fresh box).
if command -v java >/dev/null 2>&1 && java -version 2>&1 | grep -q '"21\.'; then
  JAVA21_BIN="$(readlink -f "$(command -v java)")"
fi

# 2) Ask rpm what files the installed packages actually own.
if [ -z "$JAVA21_BIN" ]; then
  JAVA21_BIN=$(rpm -ql java-21-amazon-corretto-headless java-21-amazon-corretto-devel 2>/dev/null \
    | grep -E '/bin/java$' | head -n1)
fi

# 3) Last resort: just search the filesystem for it.
if [ -z "$JAVA21_BIN" ]; then
  JAVA21_BIN=$(find /usr/lib/jvm -type f -name java 2>/dev/null | grep '21' | head -n1)
fi

if [ -z "$JAVA21_BIN" ] || [ ! -x "$JAVA21_BIN" ]; then
  echo "FATAL: could not locate a working java-21 binary anywhere" >&2
  echo "--- rpm file list for diagnosis ---" >&2
  rpm -ql java-21-amazon-corretto-headless java-21-amazon-corretto-devel >&2 || true
  echo "--- /usr/lib/jvm contents ---" >&2
  find /usr/lib/jvm >&2 || true
  exit 1
fi

echo "Resolved JAVA21_BIN=$JAVA21_BIN"
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

# Give it a moment, then report status explicitly so failures are obvious in the log
sleep 5
systemctl status jenkins --no-pager || true

# --- Wait for Jenkins to generate its initial admin password, then log it ---
for i in {1..30}; do
  if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    break
  fi
  sleep 5
done

if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
  {
    echo "Jenkins initial admin password:"
    cat /var/lib/jenkins/secrets/initialAdminPassword
  } > /var/log/jenkins-initial-password.log
else
  echo "WARNING: initialAdminPassword file never appeared after 150s" >&2
fi

echo "=== user_data finished at $(date -u) ==="
