# NVIDIA GPU Automation Suite

Production-ready automation for NVIDIA GPU passthrough, virtual machines, and AI/ML workloads. Supports both VM-based deployments and standalone Ubuntu installations.

## Overview

This repository provides battle-tested automation for:

### 🎯 GPU Passthrough (Production-Tested)
- **Softdep method** - Industry standard (Arch Wiki recommended)
- **Toggle functionality** - Switch GPU between VMs and host without reinstalling
- **Auto-detection** - Automatic GPU PCI address and device ID detection
- **Safe fallback** - NVIDIA drivers can still load if VFIO fails
- **Comprehensive diagnostics** - Verify setup at every stage

### 🖥️ VM Deployment
- **KVM/QEMU VM creation** with GPU passthrough
- **Dual networking** (host access + LAN access)
- **Automated Ubuntu installation** with GPU support
- **Forge Neo/CUDA setup** via Ansible

### 🚀 Standalone Deployment
- **Direct Ubuntu installation** automation
- **Complete NVIDIA/CUDA stack** setup
- **Conda environment** management
- **Stable Diffusion Forge** with CUDA support
- **Desktop preferences** and bash aliases

## Execution Contexts

This repository supports three distinct execution contexts. **Understanding where each script runs is critical:**

### 🖥️ Host Scripts (`host/`)
**Run on your hypervisor/host machine** to configure GPU passthrough and manage VMs.

- **GPU Passthrough**: `diagnostic.sh`, `system-config.sh`, `toggle-passthrough.sh`, `rollback.sh`
- **VM Management**: `setup-gpu-vm.sh`, `vm/create-vm.sh`, `vm/add-gpu-to-vm.sh`, `vm/hide-vm-detection.sh`
- **Troubleshooting**: `fixes/fix-vfio-permissions.sh`, `fixes/fix-memlock-limits.sh`, `fixes/fix-dns.sh`, `fixes/fix-socat-service.sh`

### 💻 Guest Scripts (`guest/`)
**Run inside the VM** after it's created (via SSH or console).

- **Network Configuration**: `configure-ubuntu-nat.sh` - Configure second network interface

### 🚀 Standalone Scripts (`standalone/`)
**Run on bare Ubuntu** (no VM, direct installation on physical/bare metal Ubuntu).

- **Deployment**: `quick-start.sh` - Main deployment entry point
- **Validation**: `validate-config.sh` - Pre-flight configuration checks
- **Export**: `export-current-config.sh` - Export current system config

### 📦 Ansible Playbooks
**Execution context specified in each playbook:**

- `ansible/playbooks/site.yml` → **GUEST** (targets remote VM via SSH)
- `ansible/playbooks/main-standalone.yml` → **STANDALONE** (targets localhost)
- `ansible/backup.yml` → **STANDALONE** (targets localhost)
- `ansible/install-systemd-service.yml` → **STANDALONE** (targets localhost)

---

## Quick Start

Choose your deployment path:

### Option A: GPU Passthrough Setup (Host Machine)

Configure your host for GPU passthrough using the industry-standard softdep method:

```bash
# 1. Run diagnostics to verify prerequisites (HOST)
./host/diagnostic.sh

# 2. Configure GPU passthrough - one-time setup (HOST)
sudo ./host/system-config.sh

# 3. Reboot
sudo reboot

# 4. Verify it worked (HOST)
./host/diagnostic.sh
lspci -k | grep -A 2 VGA  # Should show "vfio-pci" for passthrough GPU
```

**Toggle GPU between VMs and host:**
```bash
# Disable passthrough (use GPU on host for gaming/desktop) (HOST)
sudo ./host/toggle-passthrough.sh disable
sudo reboot

# Re-enable passthrough (use GPU for VMs) (HOST)
sudo ./host/toggle-passthrough.sh enable
sudo reboot
```

See [docs/PASSTHROUGH-QUICKSTART.md](docs/PASSTHROUGH-QUICKSTART.md) for details.

### Option B: VM Deployment with GPU Passthrough

Create a VM with GPU passthrough and install Forge Neo:

```bash
# 1. Run the interactive VM setup script (HOST)
./host/setup-gpu-vm.sh

# 2. After VM is created, install Forge Neo (HOST → GUEST via Ansible)
cd ansible
# Edit inventory/hosts.ini with your VM IP
ansible-playbook -i inventory/hosts.ini playbooks/site.yml

# 3. Access WebUI
# From host: http://192.168.122.XX:7860
# From LAN: http://192.168.1.XX:7860
```

See [SETUP-GPU-PASSTHROUGH.md](SETUP-GPU-PASSTHROUGH.md) for details.

### Option C: Standalone Ubuntu Installation

Install complete NVIDIA/CUDA stack on bare Ubuntu (no VM):

```bash
# 1. Validate configuration (STANDALONE)
./standalone/validate-config.sh

# 2. Run interactive deployment (STANDALONE)
./standalone/quick-start.sh

# 3. After reboot, verify and launch (STANDALONE)
nvidia-smi
conda activate forge-cuda
forge-launch  # Access at http://localhost:7860
```

See ansible roles documentation for customization.

## Repository Structure

```
.
├── README.md                           # This file - overview and quick start
├── SETUP-GPU-PASSTHROUGH.md            # Complete VM setup guide
├── QUICKREF.md                         # Command reference
├── GPU-PASSTHROUGH-STANDALONE.md       # Alternative passthrough guide
├── configure-dual-networking.md        # Network setup details
│
├── host/                               # 🖥️  HOST scripts (run on hypervisor)
│   ├── diagnostic.sh                  # GPU passthrough diagnostics
│   ├── system-config.sh               # Configure GPU passthrough (softdep)
│   ├── toggle-passthrough.sh          # Toggle GPU between VMs/host
│   ├── rollback.sh                    # Remove passthrough config
│   ├── setup-gpu-vm.sh                # Interactive VM setup wizard
│   │
│   ├── vm/                            # VM creation & management
│   │   ├── create-vm.sh              # Create VM with GPU passthrough
│   │   ├── add-gpu-to-vm.sh          # Add GPU to existing VM
│   │   └── hide-vm-detection.sh      # Hide hypervisor from Windows
│   │
│   └── fixes/                         # Host-side troubleshooting
│       ├── fix-vfio-permissions.sh   # Fix GPU device permissions
│       ├── fix-memlock-limits.sh     # Increase memory lock limits
│       ├── fix-dns.sh                # Fix DNS for VMs
│       └── fix-socat-service.sh      # Configure port forwarding
│
├── guest/                              # 💻 GUEST scripts (run inside VM)
│   └── configure-ubuntu-nat.sh        # Configure second NIC in VM
│
├── standalone/                         # 🚀 STANDALONE scripts (bare Ubuntu)
│   ├── quick-start.sh                 # Interactive deployment wizard
│   ├── validate-config.sh             # Pre-deployment validation
│   └── export-current-config.sh       # Export system config
│
├── configs/                            # VM XML configurations
│   ├── vm-template.xml                # VM definition template
│   ├── ubuntu-ml.xml                  # Example Ubuntu ML VM
│   ├── ubuntu-nat-interface.xml       # NAT network config
│   └── libvirt-macvtap-network.xml    # Macvtap network config
│
├── docs/                               # Additional documentation
│   ├── PASSTHROUGH-QUICKSTART.md      # GPU passthrough quick reference
│   ├── PASSTHROUGH-IMPROVEMENTS.md    # Softdep method technical details
│   └── PASSTHROUGH-DETAILED.md        # Complete architecture guide
│
└── ansible/                            # 📦 Ansible automation
    ├── ansible.cfg                     # Ansible configuration
    ├── backup.yml                      # Backup playbook (STANDALONE)
    ├── install-systemd-service.yml     # Service installer (STANDALONE)
    │
    ├── inventory/                      # Host inventory files
    │   └── hosts.ini.example           # Inventory template
    │
    ├── group_vars/                     # Configuration variables
    │   └── localhost.yml.example       # Config template
    │
    ├── playbooks/
    │   ├── site.yml                    # GUEST deployment (Forge Neo)
    │   └── main-standalone.yml         # STANDALONE deployment
    │
    └── roles/
        ├── base-system/                # Foundation packages
        ├── conda/                      # Conda/Miniforge setup
        ├── desktop-preferences/        # User environment
        ├── nvidia/                     # NVIDIA drivers (GUEST)
        ├── nvidia-cuda/                # NVIDIA + CUDA (STANDALONE)
        ├── forge-neo/                  # Forge Neo (GUEST)
        └── forge-cuda/                 # Forge + CUDA (STANDALONE)
```

## What Gets Installed

### GPU Passthrough Setup (Host)
- **VFIO configuration** using softdep method
- **Kernel parameters** for IOMMU
- **GPU isolation** from host drivers
- **Toggle capability** to switch GPU between modes
- **Diagnostic tools** for verification

### VM Deployment
**On the Host:**
- QEMU/KVM virtualization
- libvirt for VM management
- VFIO drivers for GPU isolation

**In the VM:**
- **Ubuntu 24.04 Server**
- **NVIDIA GPU drivers** (auto-detected version)
- **CUDA 12.8 Toolkit**
- **PyTorch 2.7.0** with CUDA support
- **Forge Neo WebUI** (Stable Diffusion)
- **Python 3.10** virtual environment
- **ML packages**: xformers, bitsandbytes, attention optimizations
- **Default model**: FLUX1-dev-nf4-v2
- **Systemd service** for auto-start

### Standalone Deployment
**On Ubuntu Desktop/Server:**
- **Base system packages** (build tools, git, curl, etc.)
- **NVIDIA drivers** (550+ from graphics-drivers PPA)
- **CUDA Toolkit** (12.6+)
- **cuDNN** for deep learning
- **Conda/Miniforge** for environment management
- **Stable Diffusion Forge** repository
- **PyTorch with CUDA support** (cu121)
- **ML dependencies** (gradio, transformers, accelerate, etc.)
- **Conda environment** `forge-cuda` with Python 3.11
- **Desktop shortcuts and aliases** (gpu, forge-launch, etc.)
- **Launch scripts** for easy startup

## Prerequisites

### Hardware
- CPU with IOMMU support (Intel VT-d or AMD-Vi)
- NVIDIA GPU for passthrough (not your primary display GPU)
- 24GB+ RAM (16GB for VM + 8GB for host)
- 100GB+ free disk space

### Software
- Ubuntu 22.04 or 24.04 (host)
- Sudo privileges
- Internet connection

## Setup Process

### Phase 1: Host Preparation (~15-30 minutes)
1. Enable IOMMU in BIOS
2. Configure kernel parameters
3. Set up VFIO for GPU isolation
4. Reboot

### Phase 2: VM Creation (~10 minutes)
1. Run `scripts/setup-gpu-vm.sh` or `scripts/vm/create-vm.sh`
2. Select GPU for passthrough
3. Configure VM settings
4. Start VM

### Phase 3: Networking (~10 minutes)
1. Configure dual networking:
   - **NAT** (192.168.122.x) - host access
   - **Macvtap** (192.168.1.x) - LAN access
2. Update VM network config

### Phase 4: Forge Neo Installation (~40 minutes)
1. Set up Ansible inventory
2. Run playbook
3. Wait for installation (includes model download)

See [SETUP-GPU-PASSTHROUGH.md](SETUP-GPU-PASSTHROUGH.md) for detailed instructions.

## Usage

### VM Management

```bash
# Start/stop VM
virsh start forge-neo-gpu
virsh shutdown forge-neo-gpu

# Get VM IP addresses
virsh domifaddr forge-neo-gpu

# Connect to console
virsh console forge-neo-gpu  # Ctrl+] to exit

# SSH to VM
ssh ubuntu@192.168.122.XX
```

### Forge Neo Management (in VM)

```bash
# Start/stop service
sudo systemctl start forge-neo
sudo systemctl stop forge-neo
sudo systemctl restart forge-neo

# View logs
sudo journalctl -u forge-neo -f

# Monitor GPU usage
watch -n 1 nvidia-smi

# Manual start
cd ~/forge-neo/app
source venv/bin/activate
bash webui.sh
```

## Networking

The VM has two network interfaces:

| Interface | Type | IP Range | Purpose |
|-----------|------|----------|---------|
| enp1s0 | NAT | 192.168.122.x | Host access |
| enp7s0 | Macvtap | 192.168.1.x | LAN access |

**Access WebUI:**
- From host: `http://192.168.122.XX:7860`
- From LAN: `http://192.168.1.XX:7860`

See [configure-dual-networking.md](configure-dual-networking.md) for details.

## Troubleshooting

### GPU not visible in VM

```bash
# Check on host
lspci -nnk -d 10de: | grep -A3 "Kernel driver"
# Should show: vfio-pci

# Check in VM
lspci | grep -i nvidia
nvidia-smi
```

### NVIDIA drivers not working

```bash
# In VM
ubuntu-drivers devices
sudo ubuntu-drivers autoinstall
sudo reboot
```

### Network issues

```bash
# In VM
ip addr show
sudo netplan apply
sudo ufw allow 7860/tcp
```

### VFIO/IOMMU issues

```bash
# Use fix scripts
./scripts/fixes/fix-vfio-permissions.sh
./scripts/fixes/fix-memlock-limits.sh
```

See [SETUP-GPU-PASSTHROUGH.md](SETUP-GPU-PASSTHROUGH.md) for complete troubleshooting guide.

## Performance

With proper GPU passthrough:
- **95-100% of bare metal GPU performance**
- Full VRAM access
- CUDA acceleration
- Fast inference times

## Documentation

### Main Documentation
| File | Description |
|------|-------------|
| [README.md](README.md) | This file - overview and quick start |
| [QUICKREF.md](QUICKREF.md) | Quick command reference |

### GPU Passthrough
| File | Description |
|------|-------------|
| [docs/PASSTHROUGH-QUICKSTART.md](docs/PASSTHROUGH-QUICKSTART.md) | Daily use quick reference |
| [docs/PASSTHROUGH-IMPROVEMENTS.md](docs/PASSTHROUGH-IMPROVEMENTS.md) | Softdep method vs blacklisting |
| [docs/PASSTHROUGH-DETAILED.md](docs/PASSTHROUGH-DETAILED.md) | Complete architecture and troubleshooting |

### VM Deployment
| File | Description |
|------|-------------|
| [SETUP-GPU-PASSTHROUGH.md](SETUP-GPU-PASSTHROUGH.md) | Complete VM setup guide |
| [GPU-PASSTHROUGH-STANDALONE.md](GPU-PASSTHROUGH-STANDALONE.md) | Alternative passthrough guide |
| [configure-dual-networking.md](configure-dual-networking.md) | Network setup details |

## Key Features

### GPU Passthrough
- ✅ **Production-tested** softdep method (industry standard)
- ✅ **Toggle functionality** - Switch GPU between VMs and host
- ✅ **Auto-detection** of GPU PCI addresses and device IDs
- ✅ **Safe fallback** if VFIO fails to bind
- ✅ **One-command setup** with comprehensive diagnostics
- ✅ **Complete rollback** capability

### Automation & Deployment
- ✅ **Multiple deployment modes** (VM-based, standalone)
- ✅ **Ansible automation** for reproducible setups
- ✅ **Interactive scripts** with validation and error checking
- ✅ **Idempotent operations** - safe to run multiple times
- ✅ **Pre-flight validation** - catch issues before deployment

### VM Features
- ✅ **95-100% bare metal GPU performance**
- ✅ **Dual networking** (host + LAN access)
- ✅ **Systemd service** for auto-start
- ✅ **VM detection hiding** for better compatibility

### ML/AI Stack
- ✅ **Latest NVIDIA drivers** and CUDA toolkit
- ✅ **PyTorch with CUDA support**
- ✅ **Stable Diffusion Forge** pre-configured
- ✅ **Conda environment management**
- ✅ **Desktop shortcuts and aliases**

### Documentation
- ✅ **Comprehensive guides** for all scenarios
- ✅ **Quick reference cards** for daily use
- ✅ **Troubleshooting guides** with solutions
- ✅ **Architecture documentation** for deep understanding

## Tested Configuration

**Production System:**
- **CPU**: AMD Ryzen 9 9950X (16-Core, with AMD-Vi IOMMU)
- **Host GPU**: AMD Radeon Graphics (Granite Ridge) - Used for host display
- **Passthrough GPU**: NVIDIA GeForce RTX 5060 Ti (10de:2d04)
- **OS**: Ubuntu 24.04 LTS
- **Kernel**: 6.17.0-6-generic
- **VM Guest**: Windows 11 and Ubuntu 24.04

This configuration demonstrates:
- ✅ AMD CPU with integrated graphics (iGPU provides host display)
- ✅ NVIDIA discrete GPU passed through to VMs
- ✅ Seamless switching between passthrough and host use
- ✅ No display issues during mode changes
- ✅ 95-100% bare metal GPU performance in VMs

## Time Estimates

### GPU Passthrough Setup
- Initial diagnostics: 5 minutes
- Passthrough configuration: 10 minutes
- Reboot and verification: 5 minutes
- **Total: ~20 minutes**

### VM Deployment
- Host preparation: 15-30 minutes
- VM creation: 5-10 minutes
- Networking setup: 5-10 minutes
- Ansible playbook: 30-45 minutes
- **Total: ~1-2 hours** (mostly automated)

### Standalone Deployment
- Configuration review: 5-10 minutes
- Interactive deployment: 30-45 minutes
- Reboot and verification: 5 minutes
- **Total: ~45-60 minutes**

## Support & Troubleshooting

### GPU Passthrough Issues (HOST)
1. Run diagnostics: `./host/diagnostic.sh`
2. Check configuration: `cat /etc/modprobe.d/vfio.conf`
3. Verify IOMMU: `dmesg | grep -i iommu`
4. See [docs/PASSTHROUGH-DETAILED.md](docs/PASSTHROUGH-DETAILED.md)

### VM Issues (HOST)
1. Check [SETUP-GPU-PASSTHROUGH.md](SETUP-GPU-PASSTHROUGH.md) troubleshooting section
2. Run fix scripts in `host/fixes/` directory
3. Check VM logs: `sudo journalctl -u libvirtd`
4. Check Forge Neo logs (in GUEST): `sudo journalctl -u forge-neo`

### Standalone Deployment Issues (STANDALONE)
1. Run validation: `./standalone/validate-config.sh`
2. Check Ansible logs from deployment
3. Verify NVIDIA drivers: `nvidia-smi`
4. Verify CUDA: `nvcc --version`
5. Test PyTorch: `python -c "import torch; print(torch.cuda.is_available())"`

### Common Issues
- **GPU not binding to VFIO** (HOST): Run `./host/diagnostic.sh` and check IOMMU is enabled
- **NVIDIA drivers not loading in VM** (GUEST): Check `ubuntu-drivers devices` and reinstall if needed
- **Conda environment not found** (STANDALONE/GUEST): Restart shell or run `source ~/.bashrc`
- **Forge launch fails** (STANDALONE/GUEST): Activate conda env first: `conda activate forge-cuda`

## Additional Resources

### Official Documentation
- [Arch Wiki - GPU Passthrough](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF)
- [NVIDIA CUDA Documentation](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/)
- [PyTorch Installation Guide](https://pytorch.org/get-started/locally/)
- [Ansible Documentation](https://docs.ansible.com/)

### Related Projects
- [Stable Diffusion WebUI Forge](https://github.com/lllyasviel/stable-diffusion-webui-forge)
- [Forge Neo](https://github.com/Haoming02/sd-webui-forge-classic/tree/neo)
- [KVM/QEMU Documentation](https://www.linux-kvm.org/)
- [Libvirt Networking](https://wiki.libvirt.org/page/Networking)

### Inspiration & Credits
- [k-amin07's VFIO Guide](https://gist.github.com/k-amin07/47cb06e4598e0c81f2b42904c6909329)
- [k-amin07's VFIO Switcher](https://github.com/k-amin07/VFIO-Switcher)

## Contributing

Contributions welcome! This setup has been tested on AMD systems with NVIDIA GPUs. If you test on:
- Intel systems with NVIDIA GPUs
- Different GPU models (RTX 20xx, 30xx, 40xx series)
- Different Linux distributions

Please share your experience via issues or pull requests.

## License

MIT License - See individual component licenses for details.

This repository contains automation scripts and configurations. Individual components (QEMU, libvirt, NVIDIA drivers, Stable Diffusion Forge, etc.) maintain their respective licenses.

## Disclaimer

GPU passthrough involves modifying system configuration. While this setup includes safety features, backups, and rollback capabilities:
- Always have a backup plan for system access (SSH, serial console, recovery mode)
- Test in a non-production environment first if possible
- Understand the changes being made to your system
- Use at your own risk
