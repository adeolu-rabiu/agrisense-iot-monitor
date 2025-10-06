docker images
docker ps
which git
ls -la
cat get-docker.sh
cd ..
mkdir docs
cd docs
vim runbook-phase0.md
cd ..
tree
df -h
sudo lsblk
echo 1 | sudo tee /sys/class/block/sda/device/rescan
sudo lsblk
sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
df -h
sudo swapon --show
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
free -h
lsblk
df -h
free -h
sudo swapoff /swapfile
sudo rm /swapfile
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
lsblk
df -h
free -h
ls -la
mkdir script
cd script
mkdir phase_1
vim bootstrap-agrisense.sh
chmod +x bootstrap-agrisense.sh
tree
ls -la
cd ..
./script/phase_1/bootstrap-agrisense.sh
sudo apt  install tree
tree
mkdir phase_0 && mv script/bootstrap-agrisense.sh script/phase_0
./script/phase_0/bootstrap-agrisense.sh
tree
cd script
ls
cd phase_0
ls
cd phase_0
cd phase_1
ls
cd ..
ls
rm phase_0
ls
mkdir phase_0 && cd phase_0
ls
vim bootstrap-agrisense.sh
chmod +x bootstrap-agrisense.sh
./bootstrap-agrisense.sh
newgrp docker
clear
ls
tree
vim .gitignore
vim .dockerignore
ls -la
docker-compose version
python3 --version && pip3 --version
vim README.md
tree
ssh-keygen -t ed25519 -C "adeolu.rabiu@gmail.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cat <<'EOF' >> ~/.ssh/config
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
EOF

chmod 600 ~/.ssh/config
cat ~/.ssh/id_ed25519.pub
ssh -T git@github.com
git init -b main
git config user.name  "Adeolu Rabiu"
git config user.email "adeolu.rabiu@gmail.com"
git add .
git commit -m "chore(phase-0): initialize AgriSense IoT Monitor environment with base tooling and configuration

- Added Phase 0 bootstrap script for VM setup (Docker, Python, Node.js, LazyDocker)
- Created robust .gitignore and .dockerignore for multi-stack (Python + Node + Docker)
- Documented Phase 0 implementation in docs/runbook-phase0.md
- Verified environment configuration on Ubuntu 22.04 (amd64)
- Prepared project for Phase 1 Docker baseline setup"
git tag -a phase-0 -m "Phase 0 completed – Environment Bootstrap & Configuration"
git push origin main --tags
git remote -v
git remote add origin git@github.com:adeolu-rabiu/agrisense-iot-monitor.git
git remote -v   # should now show the origin URL
git tag -a phase-0 -m "Phase 0 completed – Environment Bootstrap & Configuration"
git push origin main --tags
# From your repo root
echo -e "\n# Never commit local SSH keys\n.ssh/\n" >> .gitignore
git rm --cached -r .ssh || true
git add .gitignore
git commit -m "security: stop tracking .ssh and ignore it going forward"
# Backup the leaked key so you don't overwrite by mistake
mv ~/.ssh/id_ed25519 ~/.ssh/id_ed25519_leaked_backup || true
# Create a fresh keypair
ssh-keygen -t ed25519 -C "adeolu.rabiu@gmail.com" -f ~/.ssh/id_ed25519
# Load the new key and set config
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cat <<'EOF' >> ~/.ssh/config
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
EOF

chmod 600 ~/.ssh/config
# Add the NEW public key to GitHub: Settings → SSH and GPG keys → New SSH key
cat ~/.ssh/id_ed25519.pub
pip3 install --user git-filter-repo
export PATH="$HOME/.local/bin:$PATH"
git filter-repo --path .ssh --invert-paths
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git remote -v
gitlog --oneline
git log --oneline
origin  git@github.com:adeolu-rabiu/agrisense-iot-monitor.git (fetch)
origin  git@github.com:adeolu-rabiu/agrisense-iot-monitor.git (push)
# Ensure you're on main
git branch -M main
# (Optional) recreate your tag after the rewrite to avoid old-object references
git tag -d phase-0 || true
git tag -a phase-0 -m "Phase 0 completed – Environment Bootstrap & Configuration"
# First test SSH to GitHub
ssh -T git@github.com  # type 'yes' if prompted
# Push the cleaned history
git push -u origin main --force-with-lease
git push origin --tags --force
git log --oneline
ls -la
cat .gitignore
git add . 
git commit -m "chore(phase-0): initialize AgriSense IoT Monitor environment with base tooling and configuration

- Added Phase 0 bootstrap script for VM setup (Docker, Python, Node.js, LazyDocker)
- Created robust .gitignore and .dockerignore for multi-stack (Python + Node + Docker)
- Documented Phase 0 implementation in docs/runbook-phase0.md
- Verified environment configuration on Ubuntu 22.04 (amd64)
- Prepared project for Phase 1 Docker baseline setup"
git push origin main
git fetch
git push origin main
git pull
git push origin main
git pull
# 1) Ensure branch is 'main'
git branch -M main
# 2) Push your branch and set upstream, overwriting remote safely
git push -u origin main --force-with-lease
ls 
cd docs
ls
vim runbook-git-keys.md
ls
cat
