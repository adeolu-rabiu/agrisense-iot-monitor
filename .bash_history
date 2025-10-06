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
