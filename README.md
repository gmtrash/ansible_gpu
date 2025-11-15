# Ansible GPU - QEMU/KVM GPU Passthrough Automation

Automated deployment solution for creating Ubuntu VMs with NVIDIA GPU passthrough using QEMU/KVM and Ansible provisioning.

## Overview

This repository provides:

- **Automated VM Creation**: QEMU/KVM VMs with NVIDIA GPU passthrough
- **Interactive GPU Detection**: Automatically detects and configures GPU for passthrough
- **Ansible Automation**: Complete provisioning with NVIDIA drivers and CUDA Toolkit
- **Production Ready**: Systemd services, cloud-init, and proper configuration

## Why Not Multipass?

**Multipass does NOT support GPU passthrough** as of 2025. This solution uses direct QEMU/KVM with libvirt for full GPU passthrough capabilities.

## Features

✅ Interactive VM creation with GPU auto-detection
✅ NVIDIA driver installation (auto-detects recommended version)
✅ CUDA Toolkit 12.8 installation
✅ Ubuntu 22.04/24.04 support
✅ Cloud-init configuration
✅ Ansible roles for modular deployment
✅ Optional systemd service creation

## Quick Start

### Prerequisites

**On Host System:**
- Ubuntu 22.04+ with NVIDIA GPU
- IOMMU enabled in BIOS
- Required packages:
  ```bash
  sudo apt install -y qemu-kvm libvirt-daemon-system virtinst \
      virt-manager cloud-image-utils ansible
  ```

### Enable IOMMU (One-time setup)

1. Edit GRUB:
   ```bash
   sudo nano /etc/default/grub
   ```

2. Add to `GRUB_CMDLINE_LINUX`:
   - **Intel**: `intel_iommu=on iommu=pt`
   - **AMD**: `amd_iommu=on iommu=pt`

3. Update and reboot:
   ```bash
   sudo update-grub
   sudo reboot
   ```

### Create VM with GPU Passthrough

```bash
# Clone this repository
git clone https://github.com/gmtrash/ansible_gpu.git
cd ansible_gpu

# Run VM creation script
sudo ./create-vm.sh
```

The script will:
- Detect available NVIDIA GPUs
- Let you select which GPU to passthrough
- Download Ubuntu 24.04 cloud image
- Create VM with GPU configured
- Set up cloud-init for initial provisioning

### Start VM and Provision

```bash
# Start the VM
sudo virsh start forge-neo-gpu

# Wait ~2 minutes for cloud-init, then get IP
sudo virsh domifaddr forge-neo-gpu

# Configure Ansible inventory
cd ansible
cp inventory/hosts.ini.example inventory/hosts.ini
# Edit hosts.ini and add your VM's IP address

# Run Ansible playbook
ansible-playbook playbooks/site.yml
```

This installs:
- NVIDIA drivers (auto-detected version)
- CUDA Toolkit 12.8
- All required system dependencies

## Repository Structure

```
ansible_gpu/
├── README.md                       # This file
├── create-vm.sh                    # Interactive VM creation script
├── vm-template.xml                 # Libvirt XML template
└── ansible/
    ├── ansible.cfg                 # Ansible configuration
    ├── inventory/
    │   └── hosts.ini.example      # Inventory template
    ├── playbooks/
    │   └── site.yml               # Main playbook
    └── roles/
        ├── nvidia/                # NVIDIA driver installation
        │   └── tasks/
        │       └── main.yml
        └── forge-neo/             # Example: Forge Neo installation
            ├── defaults/
            │   └── main.yml
            ├── tasks/
            │   └── main.yml
            └── templates/
                └── forge-neo.service.j2
```

## Usage Examples

### Basic NVIDIA Setup Only

To install just NVIDIA drivers and CUDA:

```bash
ansible-playbook playbooks/site.yml --tags nvidia
```

### Custom Application Deployment

Create your own Ansible role alongside the NVIDIA role:

```yaml
# playbooks/my-app.yml
---
- name: Deploy My Application with GPU
  hosts: all
  roles:
    - nvidia
    - my-custom-app
```

### Multiple VMs

1. Edit `create-vm.sh` and change `VM_NAME` for each VM
2. Run script multiple times
3. Add all VMs to Ansible inventory
4. Deploy to all with: `ansible-playbook playbooks/site.yml`

## Configuration Options

### VM Configuration

Edit `create-vm.sh`:

```bash
VM_MEMORY="16384"  # RAM in MB
VM_VCPUS="8"       # CPU cores
DISK_SIZE="100G"   # Disk size
```

### Ansible Variables

Edit `ansible/playbooks/site.yml`:

```yaml
vars:
  # Auto-reboot after driver installation
  nvidia_auto_reboot: false

  # Custom installation directory
  forge_install_dir: "/opt/myapp"
```

## VM Management

```bash
# List VMs
sudo virsh list --all

# Start VM
sudo virsh start <vm-name>

# Stop VM
sudo virsh shutdown <vm-name>

# Force stop
sudo virsh destroy <vm-name>

# Get VM IP
sudo virsh domifaddr <vm-name>

# Console access
sudo virsh console <vm-name>

# Delete VM (preserves disk)
sudo virsh undefine <vm-name>
```

## Troubleshooting

### GPU Not Detected in VM

1. Verify GPU passthrough:
   ```bash
   sudo virsh dumpxml <vm-name> | grep hostdev -A 5
   ```

2. Check IOMMU groups:
   ```bash
   for d in /sys/kernel/iommu_groups/*/devices/*; do
       n=${d#*/iommu_groups/*}; n=${n%%/*}
       printf 'IOMMU Group %s ' "$n"
       lspci -nns "${d##*/}"
   done | grep NVIDIA
   ```

3. Verify IOMMU is enabled:
   ```bash
   dmesg | grep -i iommu
   ```

### NVIDIA Driver Issues

1. Check installation:
   ```bash
   ssh user@vm-ip
   nvidia-smi
   ```

2. Manual installation:
   ```bash
   sudo ubuntu-drivers devices
   sudo ubuntu-drivers autoinstall
   sudo reboot
   ```

### Ansible Connection Issues

1. Test SSH:
   ```bash
   ssh user@<VM_IP>
   ```

2. Use password auth (if needed):
   ```bash
   ansible-playbook playbooks/site.yml -k
   ```

3. Copy SSH key:
   ```bash
   ssh-copy-id user@<VM_IP>
   ```

## Advanced Usage

### Custom CUDA Version

Edit `ansible/roles/nvidia/tasks/main.yml` and change the CUDA version:

```yaml
- name: Install CUDA Toolkit
  ansible.builtin.apt:
    name:
      - cuda-toolkit-12-6  # Change version here
```

### Additional Ansible Roles

Create your own roles in `ansible/roles/` for custom applications. The NVIDIA role can be used as a dependency.

### SSH Tunneling

Access services from your local machine:

```bash
ssh -L 8080:localhost:8080 user@<VM_IP>
```

## Use Cases

- **Machine Learning**: GPU-accelerated training environments
- **AI/ML Development**: Stable Diffusion, LLMs, Computer Vision
- **Gaming VMs**: GPU passthrough for Windows gaming VMs
- **Rendering**: 3D rendering, video encoding
- **Development**: Isolated GPU development environments

## Example: Forge Neo Integration

This repository includes an example role for deploying [Stable Diffusion WebUI Forge Neo](https://github.com/Haoming02/sd-webui-forge-classic/tree/neo):

```bash
ansible-playbook playbooks/site.yml
```

The `forge-neo` role demonstrates how to:
- Install Python dependencies with GPU support
- Set up PyTorch with CUDA
- Create systemd services
- Download ML models

Use it as a template for your own GPU-accelerated applications.

## System Requirements

| Component | Requirement |
|-----------|-------------|
| Host OS | Ubuntu 22.04+ |
| GPU | NVIDIA with passthrough support |
| BIOS | IOMMU/VT-d enabled |
| RAM | 16GB+ (depends on workload) |
| Disk | 100GB+ (depends on workload) |
| CPU | VT-x/AMD-V support |

## Contributing

Contributions welcome! Feel free to:
- Add new Ansible roles for different applications
- Improve GPU detection
- Add support for other Linux distributions
- Enhance documentation

## License

MIT License - See LICENSE file for details

## Credits

- QEMU/KVM and libvirt communities
- NVIDIA CUDA documentation
- Ansible project

## Related Projects

- [Forge Neo](https://github.com/Haoming02/sd-webui-forge-classic/tree/neo) - Stable Diffusion WebUI
- [VFIO-Tools](https://github.com/PassthroughPOST/VFIO-Tools) - GPU passthrough utilities
- [Looking Glass](https://looking-glass.io/) - Low-latency KVM frame relay

## Support

For issues or questions:
- Open an issue on GitHub
- Check the troubleshooting section above
- Review [libvirt documentation](https://libvirt.org/docs.html)
- Review [NVIDIA CUDA documentation](https://docs.nvidia.com/cuda/)
