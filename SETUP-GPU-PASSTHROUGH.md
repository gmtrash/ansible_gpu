# GPU Passthrough Setup Guide for Forge Neo

This guide will help you set up a Ubuntu VM with GPU passthrough for running Stable Diffusion WebUI Forge Neo. The VM will be accessible from your Ubuntu host via dual networking.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Phase 1: Host System Preparation](#phase-1-host-system-preparation)
3. [Phase 2: Create VM with GPU Passthrough](#phase-2-create-vm-with-gpu-passthrough)
4. [Phase 3: Configure Dual Networking](#phase-3-configure-dual-networking)
5. [Phase 4: Install Forge Neo with Ansible](#phase-4-install-forge-neo-with-ansible)
6. [Phase 5: Access and Use](#phase-5-access-and-use)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- **Host**: Ubuntu 22.04 or 24.04
- **CPU**: Intel VT-x or AMD-V with IOMMU support
- **GPU**: NVIDIA GPU for passthrough (dedicated GPU, not your display GPU)
- **RAM**: At least 24GB total (16GB for VM + 8GB for host)
- **Storage**: At least 100GB free space

---

## Phase 1: Host System Preparation

### Step 1.1: Install Required Packages

```bash
sudo apt update
sudo apt install -y \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    virtinst \
    virt-manager \
    cloud-image-utils \
    ovmf \
    pciutils \
    iproute2 \
    bridge-utils \
    ansible
```

### Step 1.2: Enable IOMMU in BIOS and Kernel

**BIOS Settings:**
1. Reboot and enter BIOS/UEFI
2. Enable **Intel VT-d** (Intel) or **AMD-Vi** (AMD)
3. Enable **IOMMU**
4. Save and exit

**Kernel Parameters:**

```bash
# Detect your CPU vendor
grep -E "vendor_id" /proc/cpuinfo | head -1

# For Intel CPUs:
sudo nano /etc/default/grub
# Add to GRUB_CMDLINE_LINUX: intel_iommu=on iommu=pt vfio-pci.ids=YOUR_GPU_ID

# For AMD CPUs:
sudo nano /etc/default/grub
# Add to GRUB_CMDLINE_LINUX: amd_iommu=on iommu=pt vfio-pci.ids=YOUR_GPU_ID

# Update GRUB
sudo update-grub

# Reboot
sudo reboot
```

### Step 1.3: Identify Your GPU

```bash
# List all NVIDIA GPUs
lspci -nn | grep -iE 'nvidia|vga'

# Example output:
# 01:00.0 VGA compatible controller [0300]: NVIDIA Corporation ... [10de:2684]
# 01:00.1 Audio device [0403]: NVIDIA Corporation ... [10de:22ba]

# The important parts:
# - PCI address: 01:00.0 (VGA) and 01:00.1 (Audio)
# - Device IDs: 10de:2684 (VGA) and 10de:22ba (Audio)
```

**Note down:**
- PCI address (e.g., `01:00.0`)
- Device IDs (e.g., `10de:2684,10de:22ba`)

### Step 1.4: Configure VFIO (GPU Isolation)

```bash
# Create VFIO config (replace with YOUR device IDs)
echo "options vfio-pci ids=10de:2684,10de:22ba" | sudo tee /etc/modprobe.d/vfio.conf

# Load VFIO modules early
echo "vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd" | sudo tee /etc/modules-load.d/vfio.conf

# Update initramfs
sudo update-initramfs -u

# Reboot to apply changes
sudo reboot
```

### Step 1.5: Verify IOMMU and VFIO

After reboot:

```bash
# Check IOMMU is enabled
dmesg | grep -i iommu

# Should see: "IOMMU enabled" or "AMD-Vi: Initialized" or "Intel VT-d: enabled"

# Check VFIO captured the GPU
dmesg | grep -i vfio

# Should see: "vfio-pci 0000:01:00.0: enabling device"

# Verify GPU is bound to vfio-pci
lspci -nnk -d 10de: | grep -A3 "VGA"

# Should show: "Kernel driver in use: vfio-pci"
```

### Step 1.6: Add User to Libvirt Groups

```bash
sudo usermod -aG libvirt,kvm $USER
newgrp libvirt
```

---

## Phase 2: Create VM with GPU Passthrough

### Option A: Use the Automated Script (Recommended)

```bash
cd /home/user/ansible_gpu

# Run the VM creation script
sudo ./create-vm.sh

# The script will:
# 1. Detect your NVIDIA GPUs
# 2. Let you select which GPU to passthrough
# 3. Download Ubuntu 24.04 cloud image
# 4. Create VM disk and cloud-init config
# 5. Set up GPU passthrough automatically
```

**Follow the prompts:**
- Select your GPU (the one you configured for VFIO)
- Username: `ubuntu` (default) or your preferred username
- Password: Choose a secure password
- Hostname: `forge-neo` (or your preference)

### Option B: Manual VM Creation

If you prefer manual control:

```bash
# 1. Download Ubuntu cloud image
cd /var/lib/libvirt/images
sudo wget https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img

# 2. Create VM disk (100GB)
sudo qemu-img create -f qcow2 -F qcow2 -b ubuntu-24.04-server-cloudimg-amd64.img forge-neo-gpu.qcow2 100G

# 3. Create cloud-init config
mkdir -p ~/cloud-init-temp
cd ~/cloud-init-temp

cat > meta-data <<EOF
instance-id: forge-neo-gpu
local-hostname: forge-neo
EOF

cat > user-data <<'EOF'
#cloud-config
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin, sudo
    home: /home/ubuntu
    shell: /bin/bash
    lock_passwd: false
    passwd: $6$rounds=4096$SALTSALTHERE$<hash>  # Generate with: openssl passwd -6

package_update: true
package_upgrade: true

packages:
  - qemu-guest-agent
  - python3
  - python3-pip
  - git
  - curl
  - wget
  - openssh-server

runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent

power_state:
  mode: reboot
  timeout: 300
  condition: true
EOF

# Generate cloud-init ISO
sudo cloud-localds /var/lib/libvirt/images/forge-neo-cloud-init.iso user-data meta-data

# 4. Customize and define VM
cd /home/user/ansible_gpu
cp vm-template.xml forge-neo-custom.xml

# Edit the XML to add your GPU PCI addresses
# Replace the commented-out GPU passthrough sections with your actual addresses

# Define the VM
virsh define forge-neo-custom.xml
```

### Step 2.2: Start the VM

```bash
# Start VM
virsh start forge-neo-gpu

# Watch console (Ctrl+] to exit)
virsh console forge-neo-gpu

# Wait for cloud-init to complete (~2 minutes)
# You'll see the login prompt when ready
```

---

## Phase 3: Configure Dual Networking

This setup gives you:
- **Macvtap interface**: Direct LAN access (192.168.1.x)
- **NAT interface**: Host-to-VM access (192.168.122.x)

### Step 3.1: Determine Your Physical Network Interface

On the **host**:

```bash
# Find your primary network interface
ip link show

# Look for your main ethernet/wifi interface (e.g., enp7s0, eth0, wlp3s0)
# Note this down - you'll need it for macvtap
```

### Step 3.2: Create Macvtap Network

```bash
# Edit the macvtap config
nano /home/user/ansible_gpu/libvirt-macvtap-network.xml

# Update the interface name to match YOUR interface
# Change <interface dev="enp7s0"/> to your actual interface

# Define the network
virsh net-define /home/user/ansible_gpu/libvirt-macvtap-network.xml
virsh net-start macvtap-bridge
virsh net-autostart macvtap-bridge
```

### Step 3.3: Add Second Network Interface to VM

```bash
# Shutdown VM if running
virsh shutdown forge-neo-gpu

# Wait for shutdown
virsh domstate forge-neo-gpu

# Add NAT interface (already exists from template)
# Add Macvtap interface
virsh attach-interface forge-neo-gpu \
    --type network \
    --source macvtap-bridge \
    --model virtio \
    --config

# Start VM
virsh start forge-neo-gpu
```

### Step 3.4: Configure Networking Inside VM

SSH into the VM (use console first to get IP):

```bash
# From VM console, check interfaces
ip link show

# You should see two interfaces: enp1s0 and enp7s0 (or similar)
ip addr show

# Configure netplan for both interfaces
sudo nano /etc/netplan/50-cloud-init.yaml
```

Add this configuration:

```yaml
network:
  version: 2
  ethernets:
    enp1s0:  # NAT interface (adjust name if different)
      dhcp4: true
    enp7s0:  # Macvtap interface (adjust name if different)
      dhcp4: true
```

Apply the configuration:

```bash
sudo netplan apply

# Check both interfaces got IPs
ip addr show

# Test connectivity
ping -c 2 192.168.122.1  # NAT gateway (host)
ping -c 2 8.8.8.8        # Internet
```

### Step 3.5: Note Down VM IP Addresses

```bash
# From VM
ip -4 addr show | grep inet

# Note down both IPs:
# - NAT IP: 192.168.122.x (for host access)
# - Macvtap IP: 192.168.1.x (for LAN access)
```

---

## Phase 4: Install Forge Neo with Ansible

### Step 4.1: Prepare Ansible Inventory

On the **host**:

```bash
cd /home/user/ansible_gpu/ansible

# Copy example inventory
cp inventory/hosts.ini.example inventory/hosts.ini

# Edit inventory
nano inventory/hosts.ini
```

Update with your VM's IP (use NAT IP 192.168.122.x):

```ini
[forge_servers]
forge-vm ansible_host=192.168.122.XX ansible_user=ubuntu ansible_python_interpreter=/usr/bin/python3
```

### Step 4.2: Test Ansible Connection

```bash
# Test connection
ansible -i inventory/hosts.ini forge_servers -m ping

# If it asks for password, set up SSH key:
ssh-copy-id ubuntu@192.168.122.XX
```

### Step 4.3: Run Forge Neo Playbook

```bash
cd /home/user/ansible_gpu/ansible

# Run the playbook
ansible-playbook -i inventory/hosts.ini playbooks/site.yml

# This will:
# 1. Install NVIDIA drivers (takes ~5 minutes)
# 2. Install CUDA 12.8 toolkit
# 3. Set up Python virtual environment
# 4. Install PyTorch with CUDA support
# 5. Clone and configure Forge Neo
# 6. Download default Flux model (~30 minutes)
# 7. Create systemd service

# Total time: ~30-45 minutes depending on internet speed
```

### Step 4.4: Verify Installation

SSH into the VM:

```bash
ssh ubuntu@192.168.122.XX

# Check NVIDIA drivers
nvidia-smi

# Should show your GPU with CUDA 12.8

# Check Forge Neo installation
cd ~/forge-neo/app
source venv/bin/activate
python -c "import torch; print(torch.cuda.is_available())"

# Should print: True
```

---

## Phase 5: Access and Use

### Starting Forge Neo

**Option 1: Manual Start**

```bash
# SSH into VM
ssh ubuntu@192.168.122.XX

# Start Forge Neo
cd ~/forge-neo/app
source venv/bin/activate
bash webui.sh
```

**Option 2: Systemd Service**

```bash
# Start service
sudo systemctl start forge-neo

# Enable on boot
sudo systemctl enable forge-neo

# Check status
sudo systemctl status forge-neo

# View logs
sudo journalctl -u forge-neo -f
```

### Accessing the WebUI

**From Host (Ubuntu desktop):**

```bash
# Option 1: Use NAT IP directly
firefox http://192.168.122.XX:7860

# Option 2: Set up port forwarding (optional)
# Run on host to forward localhost:7860 to VM
ssh -L 7860:localhost:7860 ubuntu@192.168.122.XX -N -f

# Then access:
firefox http://localhost:7860
```

**From LAN (other devices):**

```bash
# Use the Macvtap IP
http://192.168.1.XX:7860
```

### Using the GPU

The Forge Neo WebUI should automatically detect and use the passed-through NVIDIA GPU. You can verify in the WebUI console output:

```
Loading weights [1/4] ...
Using device: cuda
GPU: NVIDIA GeForce RTX 4090
VRAM: 24GB
```

---

## Troubleshooting

### GPU Not Detected in VM

```bash
# Check if GPU is visible
lspci | grep -i nvidia

# If not visible, check host:
virsh dumpxml forge-neo-gpu | grep hostdev

# Verify VFIO on host
lspci -nnk -d 10de: | grep -A3 "Kernel driver"
# Should show: vfio-pci
```

### NVIDIA Driver Installation Failed

```bash
# SSH into VM
ssh ubuntu@192.168.122.XX

# Check driver status
ubuntu-drivers devices

# Manual driver installation
sudo ubuntu-drivers autoinstall
sudo reboot
```

### Cannot Access VM from Host

```bash
# On host, check VM is running
virsh list --all

# Check VM has NAT IP
virsh domifaddr forge-neo-gpu

# Check firewall on VM
sudo ufw status
sudo ufw allow 7860/tcp
```

### Slow Performance / GPU Not Used

```bash
# In VM, check CUDA is working
nvidia-smi

# Check PyTorch CUDA
cd ~/forge-neo/app
source venv/bin/activate
python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}, GPU: {torch.cuda.get_device_name(0)}')"

# If False, reinstall PyTorch
pip install --force-reinstall torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
```

### VM Won't Start After GPU Passthrough

```bash
# Check libvirt logs
sudo journalctl -u libvirtd -f

# Common issues:
# 1. GPU not bound to VFIO: redo Phase 1 Step 1.4
# 2. IOMMU groups: some GPUs need entire group passed through
# 3. ROM loading: add <rom bar='on'/> to hostdev in XML

# Check IOMMU groups
for d in /sys/kernel/iommu_groups/*/devices/*; do
    n=${d#*/iommu_groups/*}; n=${n%%/*}
    printf 'IOMMU Group %s ' "$n"
    lspci -nns "${d##*/}"
done | grep -i nvidia
```

### Network Issues

```bash
# On VM, check both interfaces
ip addr show

# Restart networking
sudo netplan apply

# Check routes
ip route show

# Check DNS
cat /etc/resolv.conf
ping -c 2 8.8.8.8
```

---

## Performance Optimization

### Increase VM Memory (if you have RAM to spare)

```bash
# Shutdown VM
virsh shutdown forge-neo-gpu

# Edit VM config
virsh edit forge-neo-gpu

# Change memory to 24GB or 32GB:
# <memory unit='GiB'>24</memory>
# <currentMemory unit='GiB'>24</currentMemory>

# Start VM
virsh start forge-neo-gpu
```

### Enable Huge Pages

```bash
# On host
echo 8192 | sudo tee /proc/sys/vm/nr_hugepages

# Make persistent
echo "vm.nr_hugepages = 8192" | sudo tee -a /etc/sysctl.conf

# Edit VM XML
virsh edit forge-neo-gpu

# Add to <memoryBacking>:
# <hugepages/>
```

### CPU Pinning (Advanced)

For best performance, pin VM vCPUs to specific host CPU cores:

```bash
# Check your CPU topology
lscpu -e

# Edit VM XML
virsh edit forge-neo-gpu

# Replace <vcpu> section with pinning config
# See: https://libvirt.org/formatdomain.html#cpu-tuning
```

---

## Additional Resources

- **Forge Neo Documentation**: https://github.com/Haoming02/sd-webui-forge-classic/tree/neo
- **GPU Passthrough Guide**: https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF
- **KVM/QEMU Tuning**: https://www.linux-kvm.org/page/Tuning_KVM
- **Libvirt Networking**: https://wiki.libvirt.org/page/Networking

---

## Quick Reference Commands

```bash
# VM Management
virsh list --all                    # List all VMs
virsh start forge-neo-gpu           # Start VM
virsh shutdown forge-neo-gpu        # Graceful shutdown
virsh destroy forge-neo-gpu         # Force stop
virsh console forge-neo-gpu         # Connect to console (Ctrl+] to exit)

# Networking
virsh domifaddr forge-neo-gpu       # Get VM IP addresses
virsh net-list --all                # List networks
virsh net-dhcp-leases default       # Show DHCP leases

# GPU Check (on host)
lspci -nnk -d 10de: | grep -A3 "Kernel driver"   # Check GPU driver
nvidia-smi                                        # If GPU not passed through

# GPU Check (in VM)
nvidia-smi                          # Check GPU status
watch -n 1 nvidia-smi               # Monitor GPU usage

# Forge Neo (in VM)
sudo systemctl status forge-neo     # Check service status
sudo systemctl restart forge-neo    # Restart service
sudo journalctl -u forge-neo -f     # View logs
```

---

## Summary

You now have:
- ✅ Ubuntu VM with GPU passthrough
- ✅ Dual networking (host access + LAN access)
- ✅ NVIDIA drivers and CUDA 12.8
- ✅ Stable Diffusion WebUI Forge Neo installed
- ✅ PyTorch with GPU acceleration
- ✅ Systemd service for easy management

Access Forge Neo at:
- **From host**: `http://192.168.122.XX:7860`
- **From LAN**: `http://192.168.1.XX:7860`

Enjoy your GPU-accelerated Stable Diffusion setup! 🚀
