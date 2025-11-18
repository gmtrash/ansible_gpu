# NVIDIA GPU Automation Suite

Production-ready automation for NVIDIA GPU passthrough, KVM/QEMU virtual machines, and Stable Diffusion deployments on Ubuntu.

## What This Does

Turn a fresh Ubuntu system into a GPU-accelerated AI/ML workstation in under an hour. Choose your deployment model:
- **GPU Passthrough** - Configure VFIO for passing NVIDIA GPUs to VMs (toggle between host/VM use)
- **VM Deployment** - Automated Ubuntu VMs with GPU passthrough + Stable Diffusion Forge Neo
- **Standalone** - Direct installation on bare metal with full NVIDIA/CUDA stack

All paths use Ansible for reproducible, idempotent deployments.

---

## Prerequisites

**Required:**
- Ubuntu 22.04 or 24.04 (host)
- CPU with IOMMU support (Intel VT-d or AMD-Vi)
- NVIDIA GPU (discrete, not your display GPU for passthrough scenarios)
- 16GB+ RAM (32GB recommended for VMs)
- 100GB+ free disk space

**Skills:**
- Basic command line familiarity
- Understanding of VMs (for VM deployment path)
- Sudo access

---

## Which Path Should I Take?

```
┌─ Do you want to use VMs for isolation? ─────────────────────┐
│                                                              │
│  YES ──┐                                       NO ──────┐    │
│        │                                                │    │
│        ▼                                                ▼    │
│  Is GPU passthrough                              STANDALONE  │
│  already configured?                             Path C      │
│        │                                         (page down) │
│        │                                                     │
│   YES ─┼─ NO                                                │
│        │   │                                                 │
│        ▼   ▼                                                 │
│    Path B  Path A                                            │
│    VM      GPU                                               │
│    Deploy  Passthrough                                       │
│    (below) Setup (below)                                     │
└──────────────────────────────────────────────────────────────┘
```

**Still not sure?**
- **Path A (GPU Passthrough)** - You have a host with an NVIDIA GPU you want to pass to VMs. This configures VFIO and gives you toggle capability.
- **Path B (VM Deployment)** - You want a complete Ubuntu VM running Stable Diffusion with GPU acceleration. Includes everything.
- **Path C (Standalone)** - You want Stable Diffusion directly on your Ubuntu desktop/server. No VMs, just CUDA + Forge.

---

## Quick Start

### Path A: GPU Passthrough Configuration (Host Only)

**What this does:** Configures your NVIDIA GPU for VM passthrough using the industry-standard softdep method. Afterwards, you can toggle the GPU between host and VM use.

**Time:** ~20 minutes + reboot

```bash
# 1. Run diagnostics
./host/diagnostic.sh

# 2. Configure GPU passthrough
sudo ./host/system-config.sh

# 3. Reboot to apply changes
sudo reboot

# 4. Verify it worked
./host/diagnostic.sh
lspci -k | grep -A 2 VGA  # Should show "vfio-pci" for your passthrough GPU
```

**Toggle GPU later:**
```bash
# Use GPU on host (disable passthrough)
sudo ./host/toggle-passthrough.sh disable && sudo reboot

# Use GPU in VMs (enable passthrough)
sudo ./host/toggle-passthrough.sh enable && sudo reboot
```

**Next:** Use `./host/vm/create-vm.sh` to create VMs with GPU passthrough, or proceed to Path B.

📖 **Full guide:** [docs/PASSTHROUGH-QUICKSTART.md](docs/PASSTHROUGH-QUICKSTART.md)

---

### Path B: VM with GPU Passthrough + Forge Neo

**What this does:** Creates an Ubuntu 24.04 VM with your NVIDIA GPU passed through, then installs Stable Diffusion WebUI Forge Neo with full CUDA support.

**Prerequisites:** GPU passthrough configured (Path A above)

**Time:** ~1-2 hours (mostly automated downloads)

```bash
# 1. Create VM with GPU passthrough
./host/setup-gpu-vm.sh
# Follow prompts: select GPU, set username/password, configure networking

# 2. Wait for VM to boot (~2 minutes)
# The script will show you the VM's IP address

# 3. Install Forge Neo in the VM (run from host)
cd ansible
cp inventory/hosts.ini.example inventory/hosts.ini
# Edit hosts.ini: set ansible_host=<VM-IP>

ansible-playbook -i inventory/hosts.ini playbooks/site.yml
# This installs: NVIDIA drivers, CUDA 12.8, PyTorch 2.7, Forge Neo, default model

# 4. Access the WebUI
# From host: http://192.168.122.XX:7860
# From LAN: http://192.168.1.XX:7860
```

**What you get:**
- Ubuntu 24.04 VM with GPU passthrough
- NVIDIA drivers + CUDA 12.8 + PyTorch 2.7
- Stable Diffusion WebUI Forge Neo
- FLUX1-dev-nf4-v2 model (~8GB)
- Dual networking (host access + LAN access)
- Systemd service (auto-start on boot)

📖 **Full guide:** [SETUP-GPU-PASSTHROUGH.md](SETUP-GPU-PASSTHROUGH.md)

---

### Path C: Standalone Installation (Bare Metal)

**What this does:** Installs complete NVIDIA/CUDA stack + Stable Diffusion Forge directly on your Ubuntu system. No VMs.

**Time:** ~45-60 minutes

```bash
# 1. Configure your preferences
cd ansible
cp group_vars/localhost.yml.example group_vars/localhost.yml
# Edit localhost.yml: set your username, git config, paths

# 2. Validate configuration
./standalone/validate-config.sh

# 3. Run deployment
./standalone/quick-start.sh
# Installs: NVIDIA drivers, CUDA 12.6, Python 3.12, Forge Neo setup

# 4. Reboot
sudo reboot

# 5. Launch Forge
forge-launch  # Access at http://localhost:7860
```

**What you get:**
- NVIDIA drivers (550+) + CUDA Toolkit
- Python 3.12 venv with PyTorch + CUDA
- Stable Diffusion Forge Neo repository
- Desktop shortcuts and bash aliases
- Optional systemd service

📖 **Full guide:** See `ansible/playbooks/main-standalone.yml` for all roles

---

## Documentation

### For New Users
| Guide | Purpose |
|-------|---------|
| [README.md](README.md) | This file - overview and quick start |
| [QUICKREF.md](QUICKREF.md) | Command cheat sheet for daily use |

### GPU Passthrough
| Guide | Purpose |
|-------|---------|
| [docs/PASSTHROUGH-QUICKSTART.md](docs/PASSTHROUGH-QUICKSTART.md) | Daily operations (toggle GPU, troubleshoot) |
| [docs/PASSTHROUGH-IMPROVEMENTS.md](docs/PASSTHROUGH-IMPROVEMENTS.md) | Why softdep method (technical) |
| [docs/PASSTHROUGH-DETAILED.md](docs/PASSTHROUGH-DETAILED.md) | Complete architecture and troubleshooting |

### VM Deployment
| Guide | Purpose |
|-------|---------|
| [SETUP-GPU-PASSTHROUGH.md](SETUP-GPU-PASSTHROUGH.md) | Complete VM setup guide with networking |
| [configure-dual-networking.md](configure-dual-networking.md) | Macvtap + NAT network setup details |

---

## Troubleshooting

### GPU not binding to VFIO
```bash
./host/diagnostic.sh  # Shows what's wrong
dmesg | grep -i iommu  # Check IOMMU is enabled
lspci -nnk -d 10de:  # Check current driver binding
```

**Common fixes:**
- Enable IOMMU in BIOS (Intel VT-d or AMD-Vi)
- Add kernel parameters: `intel_iommu=on iommu=pt` (or `amd_iommu=on`)
- Run `sudo ./host/system-config.sh` to configure VFIO

### VM won't start
```bash
sudo journalctl -u libvirtd -n 50  # Check libvirt logs
virsh list --all  # Check VM state
```

**Common fixes:**
- GPU must be bound to vfio-pci on host
- Check IOMMU groups: Run `./host/diagnostic.sh`
- Try `./host/fixes/fix-vfio-permissions.sh`

### NVIDIA drivers not working in VM/Standalone
```bash
# In VM or standalone system
nvidia-smi  # Should show GPU
ubuntu-drivers devices  # Shows available drivers
```

**Common fixes:**
```bash
sudo ubuntu-drivers autoinstall
sudo reboot
```

### Forge WebUI issues
```bash
# Check service status
sudo systemctl status forge-neo  # VM
sudo systemctl status forge-cuda  # Standalone

# Check CUDA is available
python -c "import torch; print(torch.cuda.is_available())"

# Manual start
cd ~/forge-neo/app  # or ~/llm/sd-webui-forge-cuda
source venv/bin/activate
bash webui.sh
```

📖 **More help:** See [docs/PASSTHROUGH-DETAILED.md](docs/PASSTHROUGH-DETAILED.md) for comprehensive troubleshooting

---

## Understanding This Repository

### Execution Contexts

**This repository has scripts that run in three different places.** Understanding where each script executes is critical:

#### 🖥️ Host Scripts (`host/`)
**Run on your hypervisor/host machine** to configure GPU passthrough and manage VMs.

- **GPU Passthrough:** `diagnostic.sh`, `system-config.sh`, `toggle-passthrough.sh`, `rollback.sh`
- **VM Management:** `setup-gpu-vm.sh`, `vm/create-vm.sh`, `vm/add-gpu-to-vm.sh`, `vm/hide-vm-detection.sh`
- **Troubleshooting:** `fixes/fix-vfio-permissions.sh`, `fixes/fix-memlock-limits.sh`, `fixes/fix-dns.sh`, `fixes/fix-socat-service.sh`

#### 💻 Guest Scripts (`guest/`)
**Run inside the VM** after it's created (via SSH or console).

- `configure-ubuntu-nat.sh` - Configure second network interface in VM

#### 🚀 Standalone Scripts (`standalone/`)
**Run on bare Ubuntu** (no VM, direct installation on physical/bare metal).

- `quick-start.sh` - Interactive deployment wizard
- `validate-config.sh` - Pre-flight configuration checks
- `export-current-config.sh` - Export current system configuration

#### 📦 Ansible Playbooks
**Execution context specified in each playbook:**

- `ansible/playbooks/site.yml` → **GUEST** (deploys to VM via SSH)
- `ansible/playbooks/main-standalone.yml` → **STANDALONE** (deploys to localhost)
- `ansible/backup.yml` → **STANDALONE**
- `ansible/install-systemd-service.yml` → **STANDALONE**

### Repository Structure

```
.
├── host/                    # 🖥️  Scripts for hypervisor/host
│   ├── diagnostic.sh       # GPU passthrough diagnostics
│   ├── system-config.sh    # Configure VFIO passthrough
│   ├── toggle-passthrough.sh  # Switch GPU between host/VMs
│   ├── rollback.sh         # Remove passthrough config
│   ├── setup-gpu-vm.sh     # Interactive VM setup wizard
│   ├── vm/                 # VM creation and management
│   └── fixes/              # Host-side troubleshooting
│
├── guest/                   # 💻 Scripts for inside VMs
│   └── configure-ubuntu-nat.sh  # VM network configuration
│
├── standalone/              # 🚀 Scripts for bare Ubuntu
│   ├── quick-start.sh      # Deployment wizard
│   ├── validate-config.sh  # Pre-flight checks
│   └── export-current-config.sh  # Export config
│
├── ansible/                 # 📦 Ansible automation
│   ├── playbooks/
│   │   ├── site.yml        # VM deployment (GUEST)
│   │   └── main-standalone.yml  # Bare metal deployment
│   ├── roles/              # Modular installation tasks
│   │   ├── nvidia/         # NVIDIA drivers (for VMs)
│   │   ├── nvidia-cuda/    # NVIDIA + CUDA (standalone)
│   │   ├── forge-neo/      # Forge Neo (VMs)
│   │   └── forge-cuda/     # Forge + CUDA (standalone)
│   └── group_vars/         # Configuration variables
│
├── configs/                 # VM XML configurations
├── docs/                    # Additional documentation
└── README.md               # This file
```

### What Gets Installed

<details>
<summary><b>Path A: GPU Passthrough Setup (Host)</b></summary>

- VFIO kernel modules configuration
- GRUB kernel parameters (IOMMU)
- GPU isolation from host drivers
- Toggle scripts for switching GPU modes
- Diagnostic tools
</details>

<details>
<summary><b>Path B: VM Deployment</b></summary>

**On Host:**
- QEMU/KVM virtualization
- libvirt for VM management
- VFIO drivers for GPU passthrough

**In VM:**
- Ubuntu 24.04 Server (cloud-init automated)
- NVIDIA drivers (auto-detected version)
- CUDA 12.8 Toolkit
- PyTorch 2.7.0 with CUDA support
- Stable Diffusion WebUI Forge Neo
- Python 3.10 virtual environment
- ML packages: xformers, bitsandbytes, attention optimizations
- FLUX1-dev-nf4-v2 model (~8GB)
- Systemd service for auto-start
- Dual networking (NAT + Macvtap)
</details>

<details>
<summary><b>Path C: Standalone Deployment</b></summary>

- Base system packages (build tools, git, etc.)
- NVIDIA drivers (550+ from graphics-drivers PPA)
- CUDA Toolkit (12.6+)
- cuDNN for deep learning
- Python 3.12 with venv support
- Stable Diffusion Forge Neo repository
- PyTorch with CUDA support (automatically installed by Forge)
- ML dependencies (automatically managed by Forge launch script)
- Python venv at `~/llm/sd-webui-forge/venv`
- Desktop shortcuts and bash aliases
- Launch scripts (`forge-launch`, `webui.sh`)
- Optional systemd service
</details>

---

## Key Features

### GPU Passthrough
- ✅ **Production-tested** softdep method (Arch Wiki standard)
- ✅ **Toggle functionality** - Switch GPU between VMs and host without reinstalling
- ✅ **Auto-detection** of GPU PCI addresses and device IDs
- ✅ **Safe fallback** - NVIDIA drivers can still load if VFIO fails
- ✅ **One-command diagnostics** - Verify setup at every stage
- ✅ **Complete rollback** capability

### Automation & Deployment
- ✅ **Three deployment paths** - VM, standalone, or just passthrough
- ✅ **Ansible automation** - Reproducible, idempotent setups
- ✅ **Interactive scripts** - Validation and error checking
- ✅ **Pre-flight validation** - Catch issues before deployment

### VM Features
- ✅ **95-100% bare metal GPU performance**
- ✅ **Dual networking** (host + LAN access)
- ✅ **Systemd service** - Auto-start on boot
- ✅ **VM detection hiding** - Better compatibility

### ML/AI Stack
- ✅ **Latest NVIDIA drivers** and CUDA toolkit
- ✅ **PyTorch with CUDA** support (auto-installed)
- ✅ **Stable Diffusion Forge Neo** pre-configured
- ✅ **Python venv** with automatic dependency management

---

## Production-Tested Configuration

This automation has been tested and runs in production on:

**Hardware:**
- **CPU:** AMD Ryzen 9 9950X (16-Core, AMD-Vi IOMMU)
- **Host GPU:** AMD Radeon Graphics (integrated, used for host display)
- **Passthrough GPU:** NVIDIA GeForce RTX 5060 Ti (discrete, passed to VMs)
- **RAM:** 64GB DDR5
- **OS:** Ubuntu 24.04 LTS
- **Kernel:** 6.17.0-6-generic

**VMs:**
- Windows 11 (gaming, GPU passthrough)
- Ubuntu 24.04 (Forge Neo, GPU passthrough)

**Performance:**
- 95-100% bare metal GPU performance in VMs
- Seamless GPU switching between host and VMs
- No display issues during mode changes
- Full VRAM access in passthrough mode

---

## Additional Resources

### Official Documentation
- [Arch Wiki - GPU Passthrough](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF) (industry standard reference)
- [NVIDIA CUDA Documentation](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/)
- [PyTorch Installation Guide](https://pytorch.org/get-started/locally/)
- [KVM/QEMU Documentation](https://www.linux-kvm.org/)

### Related Projects
- [Stable Diffusion WebUI Forge](https://github.com/lllyasviel/stable-diffusion-webui-forge)
- [Forge Neo](https://github.com/Haoming02/sd-webui-forge-classic/tree/neo)
- [Libvirt Networking](https://wiki.libvirt.org/page/Networking)

### Inspiration & Credits
- [k-amin07's VFIO Guide](https://gist.github.com/k-amin07/47cb06e4598e0c81f2b42904c6909329)
- [k-amin07's VFIO Switcher](https://github.com/k-amin07/VFIO-Switcher)

---

## Contributing

Contributions welcome! This setup has been tested on AMD systems with NVIDIA GPUs.

**Seeking testers for:**
- Intel systems with NVIDIA GPUs
- Different GPU models (RTX 20xx, 30xx, 40xx series)
- Different Linux distributions

Please share your experience via issues or pull requests.

---

## License

MIT License - See individual component licenses for details.

This repository contains automation scripts and configurations. Individual components (QEMU, libvirt, NVIDIA drivers, Stable Diffusion Forge, etc.) maintain their respective licenses.

---

## Disclaimer

GPU passthrough involves modifying system configuration. While this setup includes safety features, backups, and rollback capabilities:

- ⚠️ Always have a backup plan for system access (SSH, serial console, recovery mode)
- ⚠️ Test in a non-production environment first if possible
- ⚠️ Understand the changes being made to your system
- ⚠️ Use at your own risk

**Support:** For issues, see troubleshooting section above or consult the detailed guides in `docs/`.
