# NVIDIA GPU Passthrough Guide

This guide explains how to set up NVIDIA GPU passthrough for KVM/QEMU virtual machines, enabling VMs to have direct access to your NVIDIA GPU.

## Overview

GPU passthrough allows a virtual machine to directly access a physical GPU, providing near-native graphics performance. This is useful for:

- Running GPU-accelerated workloads in VMs
- Testing NVIDIA setups in isolated environments
- Running Windows VMs with full GPU acceleration
- Dedicating a GPU to a specific VM

## Prerequisites

### Hardware Requirements

1. **CPU with virtualization support**:
   - Intel: VT-x and VT-d (IOMMU)
   - AMD: AMD-V and AMD-Vi (IOMMU)

2. **Motherboard with IOMMU support**:
   - Enable VT-d (Intel) or AMD-Vi (AMD) in BIOS/UEFI
   - Some motherboards require "Above 4G Decoding" enabled

3. **NVIDIA GPU**:
   - Any NVIDIA GPU should work
   - Ideally a dedicated GPU (not your primary display GPU)
   - For best results, use a second GPU for passthrough

### Software Requirements

- Ubuntu 22.04 LTS or newer
- KVM/QEMU installed
- Libvirt installed
- Root/sudo access

Install required packages:

```bash
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager ovmf
```

## Quick Start

We provide two helper scripts for easy setup:

### 1. Configure VFIO for NVIDIA GPU

```bash
sudo ./setup-nvidia-passthrough.sh
```

This script will:
- Detect your NVIDIA GPU(s)
- Configure VFIO to bind to the GPU
- Blacklist NVIDIA drivers on the host
- Update initramfs
- Prompt for reboot

**After running, you MUST reboot for changes to take effect.**

### 2. Fix VFIO Permissions

After rebooting, run:

```bash
sudo ./fix-vfio-permissions.sh
```

This script will:
- Add your user to `kvm` and `libvirt` groups
- Create udev rules for VFIO device permissions
- Apply permissions to existing VFIO devices

**After running, log out and back in for group changes to take effect.**

## Manual Setup (Advanced)

If you prefer manual configuration or need to troubleshoot:

### Step 1: Enable IOMMU

Edit `/etc/default/grub`:

```bash
sudo vim /etc/default/grub
```

Add to `GRUB_CMDLINE_LINUX_DEFAULT`:

**For Intel CPUs:**
```
intel_iommu=on iommu=pt
```

**For AMD CPUs:**
```
amd_iommu=on iommu=pt
```

Example:
```
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash intel_iommu=on iommu=pt"
```

Update GRUB and reboot:

```bash
sudo update-grub
sudo reboot
```

### Step 2: Identify GPU Device IDs

After reboot, find your NVIDIA GPU's device IDs:

```bash
lspci -nn | grep -i nvidia
```

Example output:
```
01:00.0 VGA compatible controller [0300]: NVIDIA Corporation Device [10de:2684] (rev a1)
01:00.1 Audio device [0403]: NVIDIA Corporation Device [10de:22ba] (rev a1)
```

Note the device IDs in brackets: `10de:2684` and `10de:22ba`

### Step 3: Configure VFIO

Create `/etc/modprobe.d/vfio.conf`:

```bash
sudo vim /etc/modprobe.d/vfio.conf
```

Add (replace with your device IDs):

```
options vfio-pci ids=10de:2684,10de:22ba
softdep nvidia pre: vfio-pci
```

### Step 4: Load VFIO Modules

Create `/etc/modules-load.d/vfio.conf`:

```bash
sudo vim /etc/modules-load.d/vfio.conf
```

Add:

```
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd
```

### Step 5: Blacklist NVIDIA Drivers

Create `/etc/modprobe.d/blacklist-nvidia.conf`:

```bash
sudo vim /etc/modprobe.d/blacklist-nvidia.conf
```

Add:

```
blacklist nvidia
blacklist nvidia_drm
blacklist nvidia_modeset
blacklist nouveau
```

### Step 6: Update Initramfs and Reboot

```bash
sudo update-initramfs -u -k all
sudo reboot
```

### Step 7: Verify VFIO Binding

After reboot, verify the GPU is bound to vfio-pci:

```bash
lspci -k | grep -A 3 -i nvidia
```

You should see:
```
Kernel driver in use: vfio-pci
```

## Creating a VM with GPU Passthrough

### Using virt-manager (GUI)

1. Open virt-manager
2. Create a new VM or edit existing
3. Add Hardware → PCI Host Device
4. Select your NVIDIA GPU (both VGA and Audio devices)
5. Start the VM

### Using virsh (CLI)

Find your GPU's PCI address:

```bash
lspci | grep -i nvidia
```

Example output:
```
01:00.0 VGA compatible controller: NVIDIA Corporation ...
01:00.1 Audio device: NVIDIA Corporation ...
```

Create a device XML file (`gpu.xml`):

```xml
<hostdev mode='subsystem' type='pci' managed='yes'>
  <source>
    <address domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
  </source>
</hostdev>
```

Attach to VM:

```bash
virsh attach-device <vm-name> gpu.xml --config
```

## Deploying Forge on a GPU Passthrough VM

Once your VM has GPU passthrough configured:

### 1. Clone this repository in the VM

```bash
git clone https://github.com/gmtrash/forge-neo-nvidia.git
cd forge-neo-nvidia
```

### 2. Run the Ansible playbook

```bash
sudo apt update
sudo apt install -y ansible git
./quick-start.sh
```

### 3. Reboot the VM

```bash
sudo reboot
```

### 4. Verify GPU access

```bash
nvidia-smi
```

You should see your NVIDIA GPU listed!

## Troubleshooting

### IOMMU not detected

**Symptom**: `dmesg | grep -i iommu` shows nothing

**Solution**:
1. Enable VT-d/AMD-Vi in BIOS
2. Verify kernel parameters in `/etc/default/grub`
3. Run `sudo update-grub && sudo reboot`

### GPU not binding to vfio-pci

**Symptom**: `lspci -k` shows nvidia or nouveau driver

**Solution**:
1. Verify device IDs in `/etc/modprobe.d/vfio.conf`
2. Check blacklist in `/etc/modprobe.d/blacklist-nvidia.conf`
3. Rebuild initramfs: `sudo update-initramfs -u -k all`
4. Reboot

### "Error 43" in Windows VM

**Symptom**: NVIDIA driver shows Code 43 in Windows Device Manager

**Solution**:
1. Add to VM XML (edit with `virsh edit <vm-name>`):

```xml
<features>
  <hyperv>
    <vendor_id state='on' value='1234567890ab'/>
  </hyperv>
  <kvm>
    <hidden state='on'/>
  </kvm>
</features>
```

2. Use OVMF (UEFI) firmware instead of BIOS
3. Install latest NVIDIA drivers in the VM

### Permission denied accessing /dev/vfio

**Symptom**: Cannot start VM, permission errors

**Solution**:
```bash
sudo ./fix-vfio-permissions.sh
# Log out and back in
groups  # Verify you're in kvm and libvirt groups
```

### VM freezes or black screen

**Symptom**: VM starts but displays nothing

**Solutions**:
1. Use UEFI (OVMF) firmware instead of BIOS
2. Add a virtual display (QXL or virtio-vga) alongside GPU passthrough
3. Enable "Above 4G Decoding" in BIOS if available
4. Try adding `video=efifb:off` to VM kernel parameters

## Performance Tips

1. **Use hugepages** for better memory performance:
   ```bash
   # Add to /etc/default/grub
   GRUB_CMDLINE_LINUX_DEFAULT="... hugepages=8192"
   ```

2. **CPU pinning** for dedicated cores:
   Edit VM XML to pin vCPUs to physical cores

3. **Use virtio drivers** for disk and network:
   Significantly improves I/O performance

4. **Enable host-passthrough CPU**:
   Edit VM XML: `<cpu mode='host-passthrough'>`

## References

- [VFIO PCI Passthrough Guide](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF)
- [Libvirt Domain XML Format](https://libvirt.org/formatdomain.html)
- [QEMU Documentation](https://www.qemu.org/documentation/)
- [KVM on Ubuntu](https://ubuntu.com/server/docs/virtualization-libvirt)

## Need Help?

- Check `/var/log/libvirt/qemu/<vm-name>.log` for VM logs
- Run `dmesg | tail -100` after failures
- Verify IOMMU groups: `find /sys/kernel/iommu_groups/ -type l`
- Test VFIO binding manually: `echo <device-id> > /sys/bus/pci/drivers/vfio-pci/new_id`
