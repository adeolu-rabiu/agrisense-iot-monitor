# AgriSense IoT Monitor — Phase 0 Runbook  
**Title:** VM Bootstrap and Environment Setup  
**Date Completed:** October 5, 2025  
**Author:** Adeolu Rabiu  

---

## 🎯 Objective
Prepare the base **Ubuntu VM** environment for the AgriSense IoT Monitor project.  
This includes creating the VM, installing core dependencies, optimizing the OS for observability workloads, and verifying all tools.

---

## 🖥️ VM Creation Details

| Parameter | Configuration |
|------------|---------------|
| **Host Platform** | VMware ESXi |
| **VM Name** | `agri-sense-monitor` |
| **Guest OS** | Ubuntu Server 22.04 LTS (64-bit) |
| **Architecture** | amd64 |
| **vCPUs** | 4 |
| **Memory (RAM)** | 16 GB |
| **Disk Space** | 100 GB (Thin Provisioned) |
| **Disk Type** | SSD preferred |
| **Network Adapter** | VMXNET3 (1 Gbps) |
| **Hostname** | `agri-sense-monitor` |
| **Username** | `agzo` |
| **Access Method** | SSH via ESXi management network |
| **Purpose** | Base VM for AgriSense IoT Monitor deployment |

---

## ⚙️ Bootstrap Script Location

**Path:**  
`~/script/phase_0/bootstrap-agrisense.sh`

**Purpose:**  
Automates installation of Git, Docker, Docker Compose, Node.js, Python, and LazyDocker, plus applies kernel and file descriptor optimizations.

---

## 🧩 Steps Executed

1. **System Update & Base Packages**
   - `apt update && apt upgrade`
   - Installed: `curl`, `git`, `tree`, `vim`, `htop`, `net-tools`, etc.

2. **Docker Installation**
   - Installed latest stable Docker using the official script.
   - Added user `agzo` to the `docker` group.
   - Verified with `docker run hello-world`.

3. **Docker Compose Setup**
   - Installed standalone binary (v2.24.0).
   - Verified with `docker-compose --version`.

4. **Node.js & npm (LTS)**
   - Installed via NodeSource.
   - Verified with `node -v && npm -v`.

5. **Python 3 & Pip**
   - Installed Python 3.11 with Pip & venv.
   - Verified with `python3 --version && pip3 --version`.

6. **LazyDocker Installation**
   - Installed latest release from GitHub.
   - Verified with `lazydocker --version`.
   - Confirmed TUI opens with `lazydocker`.

7. **System Optimization**
   - Updated kernel and user limits for monitoring workloads:
     ```
     fs.file-max = 2097152
     vm.swappiness = 10
     ```
   - Applied persistent configurations via `/etc/sysctl.d/99-agrisense.conf`.

---

## 🧾 Validation & Results

| Check | Command | Result | Status |
|-------|----------|---------|--------|
| OS Type | `lsb_release -a` | Ubuntu 22.04 (amd64) | ✅ |
| Git | `git --version` | 2.x | ✅ |
| Docker | `docker --version` | 25.x | ✅ |
| Docker Compose | `docker-compose --version` | 2.24.0 | ✅ |
| Node.js | `node -v` | 20.x LTS | ✅ |
| npm | `npm -v` | 10.x | ✅ |
| Python | `python3 --version` | 3.11.x | ✅ |
| Pip | `pip3 --version` | 24.x | ✅ |
| LazyDocker | `lazydocker --version` | Verified | ✅ |
| Docker Test | `docker run hello-world` | Successful | ✅ |
| Docker UI | `lazydocker` | TUI loaded | ✅ |

---

## 📂 Directory Structure (Phase 0)


