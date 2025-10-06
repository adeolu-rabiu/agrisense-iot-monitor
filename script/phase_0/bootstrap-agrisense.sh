#!/usr/bin/env bash
# ==========================================================
# AgriSense IoT Monitor - Phase 0 Bootstrap Script
# Prepares Ubuntu VM with base tooling for project deployment
# ==========================================================

set -e  # Exit immediately if a command fails
LOGFILE="$HOME/agrisense-bootstrap.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "=== Phase 0: Bootstrap starting at $(date) ==="

# ---- System Update & Essentials ----
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y \
  curl wget git tree vim htop net-tools unzip ca-certificates \
  gnupg lsb-release build-essential apt-transport-https software-properties-common

# ---- Docker & Docker Compose ----
if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
fi

# Allow current user to run docker
sudo usermod -aG docker "$USER"

# Docker Compose (standalone v2 binary)
if ! command -v docker-compose >/dev/null 2>&1; then
  echo "Installing Docker Compose..."
  sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
fi

# ---- Node.js (LTS) & npm ----
if ! command -v node >/dev/null 2>&1; then
  echo "Installing Node.js LTS..."
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt install -y nodejs
fi

# ---- Python 3 & Pip ----
sudo apt install -y python3 python3-pip python3-venv

# ---- LazyDocker (Docker TUI) ----
if ! command -v lazydocker >/dev/null 2>&1; then
  echo "Installing LazyDocker..."
  LAZY_VER=$(curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | grep tag_name | cut -d '"' -f4)
  curl -L "https://github.com/jesseduffield/lazydocker/releases/download/${LAZY_VER}/lazydocker_${LAZY_VER#v}_Linux_x86_64.tar.gz" -o lazydocker.tar.gz
  sudo tar -C /usr/local/bin -xzf lazydocker.tar.gz lazydocker
  rm lazydocker.tar.gz
fi

# ---- Verify Versions ----
echo "=== Installed Versions ==="
git --version
docker --version
docker-compose --version
node -v
npm -v
python3 --version
pip3 --version
lazydocker --version

# ---- System Optimization ----
sudo tee /etc/security/limits.conf >/dev/null <<EOF
* soft nofile 65536
* hard nofile 65536
EOF

sudo tee /etc/sysctl.d/99-agrisense.conf >/dev/null <<EOF
fs.file-max = 2097152
vm.swappiness = 10
EOF
sudo sysctl -p /etc/sysctl.d/99-agrisense.conf

echo "=== Phase 0 completed successfully ==="
echo "Log file saved to: $LOGFILE"
echo "👉 Run 'newgrp docker' or log out/in to apply Docker permissions."
echo "👉 Test LazyDocker by running: lazydocker"

