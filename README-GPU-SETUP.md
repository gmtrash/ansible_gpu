# GPU Passthrough for Forge Neo - Quick Start

This repository now includes everything you need to set up GPU passthrough for running Stable Diffusion WebUI Forge Neo in a Ubuntu VM.

## 📋 What You Have

Your repository contains:

1. **Complete Setup Guide** (`SETUP-GPU-PASSTHROUGH.md`)
   - Detailed step-by-step instructions
   - Troubleshooting section
   - Performance optimization tips

2. **Interactive Setup Script** (`setup-gpu-vm.sh`)
   - Automated prerequisite checking
   - Guided VM creation process
   - Network configuration helper

3. **Quick Checklist** (`CHECKLIST.md`)
   - Simple checkbox list of all steps
   - Quick command reference
   - Time estimates for each phase

4. **VM Creation Tools**
   - `create-vm.sh` - Automated VM creation with GPU passthrough
   - `vm-template.xml` - VM configuration template
   - Network configuration files

5. **Ansible Playbooks**
   - `ansible/playbooks/site.yml` - Installs Forge Neo with NVIDIA GPU support
   - `ansible/roles/nvidia/` - NVIDIA driver installation
   - `ansible/roles/forge-neo/` - Forge Neo setup

6. **Helper Scripts**
   - `add-gpu-to-vm.sh` - Add GPU to existing VM
   - `fix-vfio-permissions.sh` - Fix GPU permissions
   - `fix-memlock-limits.sh` - Increase memory limits
   - And more...

## 🚀 Quick Start (3 Steps)

### Option 1: Automated Setup (Easiest)

```bash
# Run the interactive setup helper
./setup-gpu-vm.sh
```

The script will guide you through:
- Installing prerequisites
- Checking IOMMU status
- Configuring VFIO for your GPU
- Creating the VM with GPU passthrough
- Setting up dual networking

### Option 2: Manual Setup

```bash
# 1. Read the setup guide
cat SETUP-GPU-PASSTHROUGH.md

# 2. Enable IOMMU and configure VFIO (requires reboot)
# Follow Phase 1 in SETUP-GPU-PASSTHROUGH.md

# 3. Create VM with GPU
sudo ./create-vm.sh

# 4. Configure networking
# Follow Phase 3 in SETUP-GPU-PASSTHROUGH.md

# 5. Install Forge Neo
cd ansible
# Edit inventory/hosts.ini with VM IP
ansible-playbook -i inventory/hosts.ini playbooks/site.yml
```

### Option 3: Checklist-Based

```bash
# Follow the checklist step by step
cat CHECKLIST.md
```

## 📖 Documentation Structure

| Document | Purpose | Best For |
|----------|---------|----------|
| **README-GPU-SETUP.md** | This file - overview and quick start | First-time users |
| **SETUP-GPU-PASSTHROUGH.md** | Complete detailed guide with all steps | Full reference |
| **CHECKLIST.md** | Simple checkbox list of tasks | Following along |
| **configure-dual-networking.md** | Network configuration details | Network setup |
| **QUICKREF.md** | Command cheat sheet | Daily use |

## 🎯 What Gets Installed

### In the VM:
- **Ubuntu 24.04 Server** (via cloud-init)
- **NVIDIA GPU drivers** (auto-detected version)
- **CUDA 12.8 Toolkit**
- **PyTorch 2.7.0** with CUDA 12.8
- **Stable Diffusion WebUI Forge Neo**
- **Python 3.10** with virtual environment
- **ML packages**: xformers, bitsandbytes, attention optimizations
- **Default model**: FLUX1-dev-nf4-v2 (~8GB download)
- **Systemd service** for auto-start

### Network Configuration:
- **NAT interface** (192.168.122.x) - For host access
- **Macvtap interface** (192.168.1.x) - For LAN access

## 🔧 Requirements

### Hardware:
- CPU with IOMMU (Intel VT-d or AMD-Vi)
- NVIDIA GPU for passthrough
- 24GB+ RAM (16GB for VM, 8GB for host)
- 100GB+ free disk space

### Software:
- Ubuntu 22.04 or 24.04 (host)
- Internet connection
- Sudo privileges

## 📊 Architecture

```
┌─────────────────────────────────────────────┐
│           Ubuntu Host System                │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │      Ubuntu VM (forge-neo-gpu)        │ │
│  │                                       │ │
│  │  ┌─────────────────────────────────┐ │ │
│  │  │   Forge Neo WebUI               │ │ │
│  │  │   http://:7860                  │ │ │
│  │  └─────────────────────────────────┘ │ │
│  │                                       │ │
│  │  ┌─────────────────────────────────┐ │ │
│  │  │   NVIDIA GPU (Passthrough)      │ │ │
│  │  │   CUDA 12.8 + PyTorch 2.7       │ │ │
│  │  └─────────────────────────────────┘ │ │
│  │                                       │ │
│  │  Network:                             │ │
│  │  • NAT: 192.168.122.x → Host access  │ │
│  │  • Macvtap: 192.168.1.x → LAN access │ │
│  └───────────────────────────────────────┘ │
│                                             │
│  GPU passed through via VFIO-PCI            │
└─────────────────────────────────────────────┘
```

## ⚡ Performance

Expected performance with GPU passthrough:
- **Near-native GPU performance** (95-100% of bare metal)
- **Full VRAM access** (entire GPU memory available)
- **CUDA acceleration** for image generation
- **Fast inference times** comparable to native installation

## 🎨 Accessing Forge Neo

Once setup is complete:

**From host:**
```bash
firefox http://192.168.122.XX:7860
```

**From LAN:**
```bash
firefox http://192.168.1.XX:7860
```

**Via SSH tunnel:**
```bash
ssh -L 7860:localhost:7860 ubuntu@192.168.122.XX
firefox http://localhost:7860
```

## 🔍 Verification

Check everything is working:

```bash
# SSH into VM
ssh ubuntu@192.168.122.XX

# Check GPU
nvidia-smi

# Should show your NVIDIA GPU with CUDA 12.8

# Check CUDA in PyTorch
cd ~/forge-neo/app
source venv/bin/activate
python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')"

# Should print: CUDA: True

# Check Forge Neo service
sudo systemctl status forge-neo

# Should show: active (running)
```

## 🛠️ Common Commands

```bash
# Start/stop VM
virsh start forge-neo-gpu
virsh shutdown forge-neo-gpu

# Get VM IP
virsh domifaddr forge-neo-gpu

# Connect to VM console
virsh console forge-neo-gpu  # Ctrl+] to exit

# SSH to VM
ssh ubuntu@192.168.122.XX

# Start/stop Forge Neo (in VM)
sudo systemctl start forge-neo
sudo systemctl stop forge-neo

# View logs (in VM)
sudo journalctl -u forge-neo -f

# Monitor GPU (in VM)
watch -n 1 nvidia-smi
```

## 🆘 Troubleshooting

**GPU not visible in VM:**
```bash
# Check on host
lspci -nnk -d 10de: | grep -A3 "Kernel driver"
# Should show: vfio-pci

# Check in VM
lspci | grep -i nvidia
# Should list your GPU
```

**NVIDIA drivers not working:**
```bash
# In VM
ubuntu-drivers devices
sudo ubuntu-drivers autoinstall
sudo reboot
```

**Can't access WebUI:**
```bash
# In VM, allow firewall
sudo ufw allow 7860/tcp

# Check service is running
sudo systemctl status forge-neo
```

See `SETUP-GPU-PASSTHROUGH.md` for complete troubleshooting guide.

## 📚 Additional Resources

- **Forge Neo Repo**: https://github.com/Haoming02/sd-webui-forge-classic/tree/neo
- **Original Forge**: https://github.com/lllyasviel/stable-diffusion-webui-forge
- **GPU Passthrough Wiki**: https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF
- **KVM Documentation**: https://www.linux-kvm.org/

## 🎓 Learning Path

1. **Start here**: Read this README
2. **Quick setup**: Run `./setup-gpu-vm.sh`
3. **Understanding**: Read `SETUP-GPU-PASSTHROUGH.md`
4. **Reference**: Bookmark `CHECKLIST.md` and `QUICKREF.md`
5. **Advanced**: Explore performance tuning in setup guide

## 💡 Tips

- **Use the automated script** for easiest setup
- **Enable systemd service** for auto-start on boot
- **Monitor GPU usage** with `nvidia-smi` to verify GPU is being used
- **Snapshot your VM** after successful setup (use virt-manager)
- **Share models** between VMs by using shared directories

## 🔐 Security Notes

- VM uses cloud-init with password authentication (default)
- Consider setting up SSH keys for better security
- Firewall is configured via UFW in VM
- GPU isolation prevents host access during passthrough

## ⏱️ Time Estimates

- **Host preparation**: 15-30 minutes (including reboots)
- **VM creation**: 5-10 minutes
- **Cloud-init**: 2-5 minutes
- **Network setup**: 5-10 minutes
- **Ansible playbook**: 30-45 minutes (model download)
- **Total**: 1-2 hours (mostly automated)

## 🎉 Success!

Once complete, you'll have:
- ✅ GPU-accelerated Ubuntu VM
- ✅ Forge Neo WebUI running
- ✅ Full CUDA support
- ✅ Accessible from host and LAN
- ✅ Auto-start service configured

Start generating images with GPU acceleration! 🚀

---

**Need help?** Check the troubleshooting section in `SETUP-GPU-PASSTHROUGH.md`

**Ready to start?** Run `./setup-gpu-vm.sh`
