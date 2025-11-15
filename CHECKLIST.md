# GPU Passthrough Setup Checklist

Quick checklist for setting up GPU passthrough with Forge Neo.

## Pre-Setup Checklist

- [ ] **Hardware Requirements Met**
  - CPU with IOMMU support (Intel VT-d or AMD-Vi)
  - NVIDIA GPU for passthrough (not your primary display GPU)
  - At least 24GB RAM (16GB for VM + 8GB for host)
  - At least 100GB free disk space

- [ ] **BIOS Configuration**
  - IOMMU/VT-d/AMD-Vi enabled in BIOS
  - Virtualization enabled
  - (Optional) Set integrated GPU as primary display

## Phase 1: Host Preparation ⚙️

- [ ] **Install packages**
  ```bash
  sudo apt install -y qemu-kvm libvirt-daemon-system virtinst \
      virt-manager cloud-image-utils ovmf pciutils iproute2 ansible
  ```

- [ ] **Enable IOMMU in kernel**
  - Edit `/etc/default/grub`
  - Add `intel_iommu=on iommu=pt` (Intel) or `amd_iommu=on iommu=pt` (AMD)
  - Run `sudo update-grub`
  - Reboot

- [ ] **Verify IOMMU enabled**
  ```bash
  dmesg | grep -i iommu
  # Should see "IOMMU enabled"
  ```

- [ ] **Get GPU PCI IDs**
  ```bash
  lspci -nn | grep -i nvidia
  # Note the device IDs (e.g., 10de:2684,10de:22ba)
  ```

- [ ] **Configure VFIO**
  ```bash
  echo "options vfio-pci ids=YOUR_GPU_IDS" | sudo tee /etc/modprobe.d/vfio.conf
  echo -e "vfio\nvfio_iommu_type1\nvfio_pci\nvfio_virqfd" | sudo tee /etc/modules-load.d/vfio.conf
  sudo update-initramfs -u
  sudo reboot
  ```

- [ ] **Verify VFIO bound to GPU**
  ```bash
  lspci -nnk -d 10de: | grep -A3 "Kernel driver"
  # Should show "vfio-pci"
  ```

- [ ] **Add user to groups**
  ```bash
  sudo usermod -aG libvirt,kvm $USER
  newgrp libvirt
  ```

## Phase 2: VM Creation 🖥️

### Option A: Automated (Recommended)

- [ ] **Run setup helper script**
  ```bash
  cd /home/user/ansible_gpu
  ./setup-gpu-vm.sh
  ```

### Option B: Manual

- [ ] **Run VM creation script**
  ```bash
  cd /home/user/ansible_gpu
  sudo ./create-vm.sh
  ```
  - Select your GPU
  - Set username/password
  - Set hostname

- [ ] **Start VM**
  ```bash
  virsh start forge-neo-gpu
  ```

- [ ] **Wait for cloud-init** (~2 minutes)
  ```bash
  virsh console forge-neo-gpu
  # Wait for login prompt
  ```

## Phase 3: Networking 🌐

- [ ] **Get your physical interface name**
  ```bash
  ip link show
  # Note interface name (e.g., enp7s0, eth0)
  ```

- [ ] **Update macvtap config** (for LAN access)
  - Edit `libvirt-macvtap-network.xml`
  - Change `<interface dev="enp7s0"/>` to your interface

- [ ] **Create macvtap network**
  ```bash
  virsh net-define libvirt-macvtap-network.xml
  virsh net-start macvtap-bridge
  virsh net-autostart macvtap-bridge
  ```

- [ ] **Add second interface to VM**
  ```bash
  virsh shutdown forge-neo-gpu
  virsh attach-interface forge-neo-gpu --type network --source macvtap-bridge --model virtio --config
  virsh start forge-neo-gpu
  ```

- [ ] **Configure networking inside VM**
  - SSH into VM (use console to get initial IP)
  - Edit `/etc/netplan/50-cloud-init.yaml`
  - Add configuration for both interfaces
  - Run `sudo netplan apply`

- [ ] **Note VM IPs**
  ```bash
  # In VM:
  ip -4 addr show

  # NAT IP: 192.168.122.X (for host access)
  # Macvtap IP: 192.168.1.X (for LAN access)
  ```

## Phase 4: Forge Neo Installation 🎨

- [ ] **Prepare Ansible inventory**
  ```bash
  cd ansible
  cp inventory/hosts.ini.example inventory/hosts.ini
  nano inventory/hosts.ini
  # Add: forge-vm ansible_host=192.168.122.XX ansible_user=ubuntu
  ```

- [ ] **Test connection**
  ```bash
  ansible -i inventory/hosts.ini forge_servers -m ping
  ```

- [ ] **Set up SSH key** (if needed)
  ```bash
  ssh-copy-id ubuntu@192.168.122.XX
  ```

- [ ] **Run Forge Neo playbook**
  ```bash
  ansible-playbook -i inventory/hosts.ini playbooks/site.yml
  # This takes 30-45 minutes
  ```

- [ ] **Verify installation**
  ```bash
  # SSH into VM
  ssh ubuntu@192.168.122.XX

  # Check GPU
  nvidia-smi

  # Check CUDA
  cd ~/forge-neo/app
  source venv/bin/activate
  python -c "import torch; print(torch.cuda.is_available())"
  ```

## Phase 5: Running Forge Neo 🚀

- [ ] **Start Forge Neo**

  **Option 1: Service**
  ```bash
  sudo systemctl start forge-neo
  sudo systemctl enable forge-neo  # Auto-start on boot
  ```

  **Option 2: Manual**
  ```bash
  cd ~/forge-neo/app
  source venv/bin/activate
  bash webui.sh
  ```

- [ ] **Access WebUI**
  - From host: `http://192.168.122.XX:7860`
  - From LAN: `http://192.168.1.XX:7860`

- [ ] **Verify GPU is being used**
  - Check WebUI console output
  - Run `nvidia-smi` in VM while generating

## Troubleshooting 🔧

If something doesn't work, check:

- [ ] **GPU not visible in VM**
  - Check `lspci | grep -i nvidia` in VM
  - Verify VFIO binding on host
  - Check VM XML has correct PCI addresses

- [ ] **NVIDIA drivers not working**
  - Run `ubuntu-drivers devices` in VM
  - Try manual install: `sudo ubuntu-drivers autoinstall`
  - Reboot VM

- [ ] **Network issues**
  - Check both interfaces have IPs: `ip addr show`
  - Restart networking: `sudo netplan apply`
  - Check firewall: `sudo ufw allow 7860/tcp`

- [ ] **Slow performance**
  - Verify GPU is detected: `nvidia-smi`
  - Check CUDA: `python -c "import torch; print(torch.cuda.is_available())"`
  - Check Forge Neo is using GPU (console output)

## Quick Commands Reference

```bash
# VM Management
virsh list --all                     # List VMs
virsh start forge-neo-gpu            # Start VM
virsh shutdown forge-neo-gpu         # Stop VM
virsh console forge-neo-gpu          # Connect to console (Ctrl+] to exit)

# Get VM IP
virsh domifaddr forge-neo-gpu

# SSH to VM
ssh ubuntu@192.168.122.XX

# Check GPU (in VM)
nvidia-smi
watch -n 1 nvidia-smi                # Monitor GPU usage

# Forge Neo service (in VM)
sudo systemctl status forge-neo      # Check status
sudo systemctl restart forge-neo     # Restart
sudo journalctl -u forge-neo -f      # View logs
```

## Success Criteria ✅

Your setup is complete when:

- [ ] VM starts and runs without errors
- [ ] GPU is visible in VM (`lspci | grep -i nvidia`)
- [ ] NVIDIA drivers installed (`nvidia-smi` works)
- [ ] CUDA available (`torch.cuda.is_available()` returns True)
- [ ] Can access Forge Neo WebUI from host
- [ ] Can generate images using GPU
- [ ] GPU usage visible in `nvidia-smi` during generation

## Time Estimate ⏱️

- BIOS + Host setup: **15-30 minutes**
- VM creation: **5-10 minutes**
- VM boot + cloud-init: **2-5 minutes**
- Networking setup: **5-10 minutes**
- Ansible playbook: **30-45 minutes**
- Total: **~1-2 hours** (mostly waiting for downloads)

## Resources 📚

- **Full Guide**: `SETUP-GPU-PASSTHROUGH.md`
- **Network Config**: `configure-dual-networking.md`
- **Quick Reference**: `QUICKREF.md`
- **Usage Guide**: `USAGE.md`

---

**Tip**: Use the automated setup script for the easiest experience:
```bash
./setup-gpu-vm.sh
```
