# GPU Passthrough VM for Stable Diffusion Forge Neo

Automated setup for running Stable Diffusion WebUI Forge Neo in a Ubuntu VM with NVIDIA GPU passthrough.

## Overview

This repository provides complete automation for:
- **KVM/QEMU VM creation** with GPU passthrough
- **Dual networking** (host access + LAN access)
- **NVIDIA driver installation** (CUDA 12.8)
- **Forge Neo setup** with PyTorch 2.7
- **Systemd service** for auto-start

## Quick Start

### 1. Run the Setup Script

```bash
./scripts/setup-gpu-vm.sh
```

This interactive script will:
- Check prerequisites
- Verify IOMMU is enabled
- Detect your NVIDIA GPU
- Guide you through VFIO configuration
- Create the VM with GPU passthrough
- Configure dual networking

### 2. Install Forge Neo

After the VM is created:

```bash
cd ansible
# Edit inventory/hosts.ini with your VM IP
ansible-playbook -i inventory/hosts.ini playbooks/site.yml
```

### 3. Access the WebUI

- From host: `http://192.168.122.XX:7860`
- From LAN: `http://192.168.1.XX:7860`

## Repository Structure

```
.
├── README.md                           # This file
├── SETUP-GPU-PASSTHROUGH.md            # Complete setup guide
├── QUICKREF.md                         # Command reference
├── configure-dual-networking.md        # Network setup details
│
├── scripts/                            # Helper scripts
│   ├── setup-gpu-vm.sh                # Main setup script
│   ├── vm/                            # VM management
│   │   ├── create-vm.sh              # Create VM with GPU
│   │   ├── add-gpu-to-vm.sh          # Add GPU to existing VM
│   │   ├── hide-vm-detection.sh      # Hide hypervisor from VM
│   │   └── configure-ubuntu-nat.sh   # Configure NAT network
│   └── fixes/                         # Troubleshooting scripts
│       ├── fix-vfio-permissions.sh   # Fix GPU permissions
│       ├── fix-memlock-limits.sh     # Increase memory limits
│       ├── fix-dns.sh                # Fix DNS issues
│       └── fix-socat-service.sh      # Configure port forwarding
│
├── configs/                            # VM configurations
│   ├── vm-template.xml               # VM definition template
│   ├── ubuntu-ml.xml                 # Example VM config
│   ├── ubuntu-nat-interface.xml      # NAT network config
│   └── libvirt-macvtap-network.xml   # Macvtap network config
│
└── ansible/                            # Ansible automation
    ├── ansible.cfg                    # Ansible configuration
    ├── inventory/                     # Host inventory
    │   └── hosts.ini.example         # Inventory template
    ├── playbooks/
    │   └── site.yml                  # Main playbook
    └── roles/
        ├── nvidia/                    # NVIDIA driver installation
        └── forge-neo/                 # Forge Neo setup
```

## What Gets Installed

### On the Host
- QEMU/KVM virtualization
- libvirt for VM management
- VFIO drivers for GPU isolation

### In the VM
- **Ubuntu 24.04 Server**
- **NVIDIA GPU drivers** (auto-detected version)
- **CUDA 12.8 Toolkit**
- **PyTorch 2.7.0** with CUDA support
- **Forge Neo WebUI** (Stable Diffusion)
- **Python 3.10** virtual environment
- **ML packages**: xformers, bitsandbytes, attention optimizations
- **Default model**: FLUX1-dev-nf4-v2
- **Systemd service** for auto-start

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

| File | Description |
|------|-------------|
| [README.md](README.md) | This file - overview and quick start |
| [SETUP-GPU-PASSTHROUGH.md](SETUP-GPU-PASSTHROUGH.md) | Complete step-by-step guide |
| [QUICKREF.md](QUICKREF.md) | Quick command reference |
| [configure-dual-networking.md](configure-dual-networking.md) | Networking setup details |

## Key Features

- ✅ Full GPU passthrough with near-native performance
- ✅ Dual networking for flexible access
- ✅ Automated installation via Ansible
- ✅ Systemd service for auto-start
- ✅ Latest CUDA 12.8 and PyTorch 2.7
- ✅ Pre-configured for Stable Diffusion
- ✅ Comprehensive documentation

## Time Estimate

- Host preparation: 15-30 minutes
- VM creation: 5-10 minutes
- Networking setup: 5-10 minutes
- Ansible playbook: 30-45 minutes
- **Total: ~1-2 hours** (mostly automated)

## Support

For issues:
1. Check [SETUP-GPU-PASSTHROUGH.md](SETUP-GPU-PASSTHROUGH.md) troubleshooting section
2. Run troubleshooting scripts in `scripts/fixes/`
3. Check VM logs: `sudo journalctl -u libvirtd`
4. Check Forge Neo logs: `sudo journalctl -u forge-neo`

## Additional Resources

- [Forge Neo Repository](https://github.com/Haoming02/sd-webui-forge-classic/tree/neo)
- [GPU Passthrough Wiki](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF)
- [KVM Documentation](https://www.linux-kvm.org/)
- [Libvirt Networking](https://wiki.libvirt.org/page/Networking)

## License

This repository contains automation scripts and configurations. Individual components (QEMU, libvirt, Forge Neo, etc.) maintain their respective licenses.
