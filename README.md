# NVIDIA GPU Passthrough + Stable Diffusion Forge Neo

Automated end-to-end setup for NVIDIA GPU passthrough to Ubuntu VMs with Stable Diffusion Forge Neo deployment.

## What This Does

This repository automates the complete workflow for creating a GPU-accelerated Stable Diffusion workstation using KVM/QEMU virtualization:

1. **Host Configuration** - Validates IOMMU support and sets up SSH keys
2. **VM Creation** - Creates Ubuntu 24.04 VM with GPU passthrough and dual networking
3. **Software Deployment** - Installs NVIDIA drivers, CUDA 12.8, PyTorch, and Stable Diffusion Forge Neo
4. **Service Setup** - Configures systemd service for automatic startup

**End Result:** A fully functional Stable Diffusion web UI accessible from your browser at `http://<vm-ip>:7860`

---

## Prerequisites

### Hardware Requirements
- **CPU:** Intel with VT-d OR AMD with AMD-Vi (IOMMU support required)
- **GPU:** NVIDIA GPU (discrete card, not integrated graphics)
- **RAM:** 16GB minimum, 32GB recommended
- **Storage:** 100GB+ free disk space

### Software Requirements
- **Host OS:** Ubuntu 22.04 or 24.04
- **Privileges:** User must be in `libvirt` group (script will prompt if not)
- **Network:** Internet connection for downloading packages and cloud images

### Verify IOMMU Support
```bash
# Check BIOS settings first - Enable VT-d (Intel) or AMD-Vi (AMD)

# Then verify kernel support
./host/diagnostic.sh
```

If IOMMU is not enabled, the diagnostic script will tell you what kernel parameters to add.

---

## Quick Start (Complete Workflow)

### Step 1: Initial Host Setup

This validates your system and optionally sets up SSH key authentication:

```bash
cd host
./setup-gpu-vm.sh
```

**What it checks:**
- IOMMU enabled and working
- Required tools installed (virsh, virt-install, qemu-img, cloud-localds)
- User in libvirt group
- Virtualization enabled

**Optional:** Sets up SSH key for passwordless authentication to VMs

**Time:** 2-5 minutes

---

### Step 2: Create VM with GPU Passthrough

This creates an Ubuntu 24.04 VM with your GPU passed through:

```bash
cd host/vm
sudo ./create-vm.sh
```

**Interactive prompts:**
1. **Select GPU** - Choose which NVIDIA GPU to pass through
2. **Select Network Interface** (optional) - Choose physical NIC for LAN access via Macvtap, or skip for NAT-only
3. **VM Credentials** - Set username/password (password input is hidden)
4. **VM Hostname** - Set hostname for the VM

**Networking Options:**
- **NAT only** (default): VM gets `192.168.122.x` IP, accessible from host
- **NAT + Macvtap**: VM gets two IPs:
  - `192.168.122.x` - for host access
  - LAN DHCP IP - for access from other devices on your network

**What it does:**
- Downloads Ubuntu 24.04 cloud image (if not cached)
- Creates 100GB qcow2 disk
- Configures cloud-init for automated provisioning
- Generates VM XML with GPU passthrough configuration
- Creates and defines VM (does not start it)

**Time:** 5-10 minutes (longer on first run due to image download)

**Output:** VM definition ready, username/password configured

---

### Step 3: Deploy Forge Neo to VM

This starts the VM, waits for it to boot, and deploys Stable Diffusion:

```bash
cd host
./deploy-forge-to-vm.sh
```

**What it does:**
1. Starts the VM if not running
2. Waits for VM to get IP address
3. Waits for SSH to become available
4. Runs Ansible playbook that:
   - Installs NVIDIA drivers (version 565)
   - Installs CUDA 12.8
   - Clones Stable Diffusion WebUI Forge Neo
   - Creates Python virtual environment
   - Installs PyTorch 2.7 with CUDA 12.8 support
   - Installs xformers, bitsandbytes, and dependencies
   - Creates and starts systemd service

**Authentication:**
- Tries SSH key first (if configured in Step 1)
- Falls back to password authentication

**Time:** 15-25 minutes (NVIDIA driver installation is the longest step)

**Output:** Forge Neo web UI running at `http://<vm-ip>:7860`

---

## After Deployment

### Access the Web UI

```bash
# Get VM IP address
virsh domifaddr forge-neo-gpu

# Open in browser
http://<vm-ip>:7860
```

**If you configured Macvtap:** The VM will have two IPs. Use either one - both work.

### Manage the VM

```bash
# Start VM
virsh start forge-neo-gpu

# Stop VM
virsh shutdown forge-neo-gpu

# Force stop
virsh destroy forge-neo-gpu

# View console
virsh console forge-neo-gpu

# SSH to VM
ssh <username>@<vm-ip>
```

### Manage Forge Neo Service

```bash
# SSH to VM first
ssh <username>@<vm-ip>

# Check service status
sudo systemctl status forge-neo

# View logs
sudo journalctl -u forge-neo -f

# Restart service
sudo systemctl restart forge-neo

# Stop service
sudo systemctl stop forge-neo
```

### Add Models

Forge Neo starts with no models. You can download them:

1. **Via Web UI:** Navigate to `http://<vm-ip>:7860` and use the built-in model downloader
2. **Manual Download:** Place models in `/home/<username>/forge-neo/app/models/`
   - Stable Diffusion checkpoints: `models/Stable-diffusion/`
   - LoRA models: `models/Lora/`
   - VAE: `models/VAE/`

**Recommended sources:**
- [Civitai](https://civitai.com/) - Community models and LoRAs
- [Hugging Face](https://huggingface.co/) - Official model repository

---

## Repository Structure

```
ansible_gpu/
├── README.md                          # This file
├── host/                              # Scripts run on host machine
│   ├── setup-gpu-vm.sh               # Step 1: Validate system & setup SSH
│   ├── deploy-forge-to-vm.sh         # Step 3: Deploy Forge Neo via Ansible
│   ├── diagnostic.sh                 # Diagnose IOMMU/GPU passthrough issues
│   └── vm/
│       └── create-vm.sh              # Step 2: Create VM with GPU passthrough
├── configs/
│   └── vm-template.xml               # Libvirt VM template
└── ansible/                           # Ansible automation
    ├── ansible.cfg
    ├── playbooks/
    │   └── site.yml                  # Main playbook
    └── roles/
        ├── nvidia/                   # NVIDIA driver + CUDA installation
        └── forge-neo/                # Forge Neo installation
```

---

## Troubleshooting

### IOMMU Not Enabled

**Symptoms:** `./host/diagnostic.sh` shows "IOMMU not enabled"

**Fix:**
1. Enable VT-d (Intel) or AMD-Vi (AMD) in BIOS
2. Add kernel parameters to `/etc/default/grub`:
   ```bash
   # For Intel
   GRUB_CMDLINE_LINUX="intel_iommu=on iommu=pt"

   # For AMD
   GRUB_CMDLINE_LINUX="amd_iommu=on iommu=pt"
   ```
3. Update GRUB and reboot:
   ```bash
   sudo update-grub
   sudo reboot
   ```

### VM Won't Start

**Symptoms:** `virsh start forge-neo-gpu` fails

**Common causes:**
- **PCI device in use:** GPU still bound to host driver
  - Check: `lspci -k | grep -A 2 VGA`
  - Fix: Reboot host (GPU should bind to vfio-pci)
- **Insufficient memory:** Close applications or increase host RAM
- **Image files missing:** Re-run `./host/vm/create-vm.sh`

### Can't Access Web UI

**Symptoms:** `http://<vm-ip>:7860` doesn't load

**Debugging:**
```bash
# 1. Check if VM is running
virsh list --all

# 2. Get VM IP
virsh domifaddr forge-neo-gpu

# 3. Test connectivity
ping <vm-ip>

# 4. SSH to VM and check service
ssh <username>@<vm-ip>
sudo systemctl status forge-neo
sudo journalctl -u forge-neo -n 50
```

**Common causes:**
- Service failed to start: Check logs with `journalctl -u forge-neo`
- First launch installing dependencies: Wait 5-10 minutes for initial setup
- Firewall blocking port 7860: Check VM firewall with `sudo ufw status`

### NVIDIA Driver Installation Fails

**Symptoms:** Ansible playbook fails at "Install NVIDIA drivers" task

**Fix:**
```bash
# SSH to VM
ssh <username>@<vm-ip>

# Clean up and retry
sudo apt remove --purge 'nvidia-*' 'libnvidia-*'
sudo apt autoremove
sudo apt update
sudo ubuntu-drivers install

# Verify installation
nvidia-smi
```

### Network Interface Not Available

**Symptoms:** Macvtap interface doesn't appear in VM

**Causes:**
- Physical interface was down during VM creation
- Interface name changed after VM creation

**Fix:**
Edit VM XML and update interface device:
```bash
virsh edit forge-neo-gpu
# Update <source dev='eth0'/> to correct interface name
```

---

## Advanced Configuration

### Customize VM Resources

Edit `host/vm/create-vm.sh` before running:

```bash
VM_MEMORY="16384"  # 16GB in MB (change to desired amount)
VM_VCPUS="8"       # Number of CPU cores
DISK_SIZE="100G"   # Disk size
```

### Change Forge Neo Installation Directory

Edit `ansible/playbooks/site.yml`:

```yaml
vars:
  forge_install_dir: "/home/{{ ansible_user }}/forge-neo"  # Change this path
```

### Prevent Service Auto-Start

Edit `ansible/playbooks/site.yml`:

```yaml
vars:
  forge_enable_service: false  # Don't enable on boot
  forge_start_service: false   # Don't start after install
```

Then manually start when needed:
```bash
sudo systemctl start forge-neo
```

### Re-deploy After Changes

If you modify Ansible roles or playbooks:

```bash
cd host
./deploy-forge-to-vm.sh  # Re-runs Ansible playbook
```

Ansible is idempotent - it only changes what needs changing.

---

## Technical Details

### GPU Passthrough Method

Uses VFIO-PCI for GPU assignment. The VM gets exclusive access to:
- GPU video controller (PCI function 0)
- GPU audio controller (PCI function 1, if present)

### Networking Architecture

**NAT Interface:**
- Managed by libvirt `default` network
- Provides internet access and host connectivity
- DHCP range: 192.168.122.0/24

**Macvtap Interface (optional):**
- Direct connection to physical NIC
- Bridge mode for transparent LAN access
- Gets IP from LAN DHCP server

### Software Versions

- **OS:** Ubuntu 24.04 LTS (cloud image)
- **NVIDIA Driver:** Version 565 (latest from ubuntu-drivers)
- **CUDA:** 12.8
- **PyTorch:** 2.7.0 with CUDA 12.8
- **Python:** 3.12 (Ubuntu 24.04 default)
- **Forge Neo:** Latest from `neo` branch

### Systemd Service

Location: `/etc/systemd/system/forge-neo.service`

```ini
[Unit]
Description=Stable Diffusion WebUI Forge Neo
After=network.target

[Service]
Type=simple
User=<username>
WorkingDirectory=/home/<username>/forge-neo/app
Environment="PATH=/usr/local/cuda-12.8/bin:..."
Environment="LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64"
ExecStart=/home/<username>/forge-neo/app/venv/bin/python3 launch.py --listen --port 7860
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

---

## Security Considerations

### Password Handling
- VM passwords are hashed with SHA-512 before storage in cloud-init
- Password input is hidden during `create-vm.sh` execution
- Passwords are cleared from memory after VM creation

### SSH Configuration
- `setup-gpu-vm.sh` can set up SSH key authentication (recommended)
- Password authentication is enabled by default for Ansible
- Consider disabling password auth after setup:
  ```bash
  # In VM: /etc/ssh/sshd_config
  PasswordAuthentication no
  ```

### Network Isolation
- NAT network isolates VM from LAN by default
- Macvtap exposes VM to LAN (use firewall if needed)
- Forge Neo listens on `0.0.0.0:7860` by default (accessible from network)

---

## FAQ

**Q: Can I pass through multiple GPUs?**
A: Yes. Run `create-vm.sh` multiple times with different VM names, or create multiple VMs and assign different GPUs to each.

**Q: Will this work with AMD GPUs?**
A: No, this is NVIDIA-specific. The Ansible roles install NVIDIA drivers and CUDA toolkit.

**Q: Can I use this on bare metal (no VM)?**
A: The automation is designed for VMs. For bare metal, manually run the Ansible playbook on localhost.

**Q: Why cloud-init instead of manual installation?**
A: Cloud-init provides reproducible, automated provisioning. You can recreate identical VMs in minutes.

**Q: How do I update Forge Neo?**
A: SSH to VM, pull updates:
```bash
cd ~/forge-neo/app
git pull origin neo
sudo systemctl restart forge-neo
```

**Q: Can I use a different Stable Diffusion fork?**
A: Yes. Modify `ansible/roles/forge-neo/tasks/main.yml` to clone a different repository.

**Q: Does this support Windows VMs?**
A: No, the Ansible automation targets Ubuntu. GPU passthrough works with Windows, but you'd need different provisioning.

---

## Contributing

Found a bug or have an improvement? Please open an issue or pull request.

**Before contributing:**
1. Test changes on a fresh Ubuntu installation
2. Ensure Ansible playbooks remain idempotent
3. Update documentation for any workflow changes

---

## License

MIT License - See repository for details

---

## Acknowledgments

- **Forge Neo:** [Haoming02/sd-webui-forge-classic](https://github.com/Haoming02/sd-webui-forge-classic)
- **VFIO Guide:** [Arch Wiki - PCI Passthrough](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF)
- **Ubuntu Cloud Images:** [Ubuntu Cloud Images](https://cloud-images.ubuntu.com/)
