#!/bin/bash
set -e

# Configuration
VM_NAME="forge-neo-gpu"
VM_MEMORY="16384"  # 16GB in MB
VM_VCPUS="8"
DISK_SIZE="100G"
UBUNTU_VERSION="24.04"
IMAGE_DIR="/var/lib/libvirt/images"
VM_DISK="${IMAGE_DIR}/${VM_NAME}.qcow2"
CLOUD_INIT_ISO="${IMAGE_DIR}/${VM_NAME}-cloud-init.iso"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Forge Neo GPU VM Creation Script ===${NC}\n"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root${NC}"
   exit 1
fi

# Check for required tools
for cmd in virsh virt-install qemu-img wget cloud-localds; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}Error: Required command '$cmd' not found${NC}"
        echo "Install with: apt install qemu-kvm libvirt-daemon-system virtinst cloud-image-utils"
        exit 1
    fi
done

# Detect NVIDIA GPUs
echo -e "${YELLOW}Detecting NVIDIA GPUs...${NC}"
GPU_COUNT=$(lspci -nn | grep -i nvidia | grep -i vga | wc -l)

if [ "$GPU_COUNT" -eq 0 ]; then
    echo -e "${RED}Error: No NVIDIA GPU detected!${NC}"
    echo "Make sure your GPU is properly installed and IOMMU is enabled in BIOS."
    exit 1
fi

echo -e "${GREEN}Found $GPU_COUNT NVIDIA GPU(s):${NC}"
lspci -nn | grep -i nvidia

echo -e "\n${YELLOW}GPU PCI Addresses:${NC}"
lspci -nn | grep -i nvidia | nl -w2 -s'. '

# Prompt for GPU selection
read -p "Enter the line number of the GPU to passthrough (1-$GPU_COUNT): " GPU_SELECTION

# Get GPU PCI address
GPU_LINE=$(lspci -nn | grep -i nvidia | sed -n "${GPU_SELECTION}p")
GPU_PCI=$(echo "$GPU_LINE" | awk '{print $1}')

if [ -z "$GPU_PCI" ]; then
    echo -e "${RED}Error: Invalid selection${NC}"
    exit 1
fi

echo -e "${GREEN}Selected GPU: $GPU_LINE${NC}"
echo -e "${GREEN}PCI Address: $GPU_PCI${NC}"

# Parse PCI address (format: 01:00.0 -> domain=0, bus=01, slot=00, function=0)
IFS=':.' read -r BUS SLOT FUNC <<< "$GPU_PCI"
DOMAIN="0000"

echo -e "\n${YELLOW}Parsed PCI address:${NC}"
echo "  Domain: 0x$DOMAIN"
echo "  Bus: 0x$BUS"
echo "  Slot: 0x$SLOT"
echo "  Function: 0x$FUNC"

# Check for GPU audio device (usually function 1)
AUDIO_PCI="${BUS}:${SLOT}.1"
if lspci -s "$AUDIO_PCI" 2>/dev/null | grep -qi audio; then
    echo -e "${GREEN}Found GPU audio device at $AUDIO_PCI${NC}"
    HAS_AUDIO=true
    AUDIO_FUNC="1"
else
    echo -e "${YELLOW}No audio device found on GPU${NC}"
    HAS_AUDIO=false
fi

# Download Ubuntu cloud image
UBUNTU_IMAGE="${IMAGE_DIR}/ubuntu-${UBUNTU_VERSION}-server-cloudimg-amd64.img"
if [ ! -f "$UBUNTU_IMAGE" ]; then
    echo -e "\n${YELLOW}Downloading Ubuntu ${UBUNTU_VERSION} cloud image...${NC}"
    wget -O "$UBUNTU_IMAGE" \
        "https://cloud-images.ubuntu.com/releases/${UBUNTU_VERSION}/release/ubuntu-${UBUNTU_VERSION}-server-cloudimg-amd64.img"
else
    echo -e "${GREEN}Ubuntu image already exists${NC}"
fi

# Create VM disk
echo -e "\n${YELLOW}Creating VM disk (${DISK_SIZE})...${NC}"
if [ -f "$VM_DISK" ]; then
    read -p "VM disk already exists. Overwrite? (y/N): " OVERWRITE
    if [[ ! $OVERWRITE =~ ^[Yy]$ ]]; then
        echo "Using existing disk"
    else
        rm "$VM_DISK"
        qemu-img create -f qcow2 -F qcow2 -b "$UBUNTU_IMAGE" "$VM_DISK" "$DISK_SIZE"
    fi
else
    qemu-img create -f qcow2 -F qcow2 -b "$UBUNTU_IMAGE" "$VM_DISK" "$DISK_SIZE"
fi

# Get user details for VM
read -p "Enter username for VM [ubuntu]: " VM_USER
VM_USER=${VM_USER:-ubuntu}

read -p "Enter password for VM [ubuntu]: " VM_PASSWORD
VM_PASSWORD=${VM_PASSWORD:-ubuntu}

read -p "Enter VM hostname [forge-neo]: " VM_HOSTNAME
VM_HOSTNAME=${VM_HOSTNAME:-forge-neo}

# Create cloud-init configuration
echo -e "\n${YELLOW}Creating cloud-init configuration...${NC}"

CLOUD_INIT_DIR=$(mktemp -d)
cat > "${CLOUD_INIT_DIR}/meta-data" <<EOF
instance-id: ${VM_NAME}
local-hostname: ${VM_HOSTNAME}
EOF

cat > "${CLOUD_INIT_DIR}/user-data" <<EOF
#cloud-config
users:
  - name: ${VM_USER}
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin, sudo
    home: /home/${VM_USER}
    shell: /bin/bash
    lock_passwd: false
    passwd: $(echo "$VM_PASSWORD" | openssl passwd -6 -stdin)

package_update: true
package_upgrade: true

packages:
  - qemu-guest-agent
  - python3
  - python3-pip
  - git
  - curl
  - wget

runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent

power_state:
  mode: reboot
  timeout: 300
  condition: true
EOF

# Create cloud-init ISO
cloud-localds "$CLOUD_INIT_ISO" "${CLOUD_INIT_DIR}/user-data" "${CLOUD_INIT_DIR}/meta-data"
rm -rf "$CLOUD_INIT_DIR"

echo -e "${GREEN}Cloud-init ISO created${NC}"

# Customize VM XML template
echo -e "\n${YELLOW}Creating VM definition...${NC}"

VM_XML=$(mktemp)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cp "$SCRIPT_DIR/configs/vm-template.xml" "$VM_XML"

# Update VM name, memory, vcpus
sed -i "s|<name>.*</name>|<name>${VM_NAME}</name>|" "$VM_XML"
sed -i "s|<memory unit='GiB'>.*</memory>|<memory unit='MiB'>${VM_MEMORY}</memory>|" "$VM_XML"
sed -i "s|<currentMemory unit='GiB'>.*</currentMemory>|<currentMemory unit='MiB'>${VM_MEMORY}</currentMemory>|" "$VM_XML"
sed -i "s|<vcpu placement='static'>.*</vcpu>|<vcpu placement='static'>${VM_VCPUS}</vcpu>|" "$VM_XML"

# Update disk paths
sed -i "s|/var/lib/libvirt/images/forge-neo-gpu.qcow2|${VM_DISK}|" "$VM_XML"
sed -i "s|/var/lib/libvirt/images/forge-neo-cloud-init.iso|${CLOUD_INIT_ISO}|" "$VM_XML"

# Add GPU passthrough configuration
GPU_HOSTDEV="    <hostdev mode='subsystem' type='pci' managed='yes'>
      <source>
        <address domain='0x${DOMAIN}' bus='0x${BUS}' slot='0x${SLOT}' function='0x${FUNC}'/>
      </source>
      <address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x0'/>
    </hostdev>"

if [ "$HAS_AUDIO" = true ]; then
    AUDIO_HOSTDEV="    <hostdev mode='subsystem' type='pci' managed='yes'>
      <source>
        <address domain='0x${DOMAIN}' bus='0x${BUS}' slot='0x${SLOT}' function='0x${AUDIO_FUNC}'/>
      </source>
      <address type='pci' domain='0x0000' bus='0x06' slot='0x00' function='0x0'/>
    </hostdev>"
fi

# Replace placeholder GPU section
# Using sed with proper escaping for multiline XML
sed -i '/<!-- GPU Passthrough - REPLACE WITH YOUR GPU PCI ADDRESS -->/,/-->$/{
  /<!-- GPU Passthrough/c\
'"$GPU_HOSTDEV"'
  /-->$/d
}' "$VM_XML"

if [ "$HAS_AUDIO" = true ]; then
    sed -i '/<!-- GPU Audio device/,/-->$/{
      /<!-- GPU Audio device/c\
'"$AUDIO_HOSTDEV"'
      /-->$/d
    }' "$VM_XML"
fi

# Enable IOMMU if needed
if ! grep -q "iommu=pt" /proc/cmdline 2>/dev/null; then
    echo -e "\n${YELLOW}Warning: IOMMU may not be enabled in kernel parameters${NC}"
    echo "Add 'intel_iommu=on iommu=pt' (Intel) or 'amd_iommu=on iommu=pt' (AMD) to GRUB_CMDLINE_LINUX"
    echo "in /etc/default/grub and run 'update-grub', then reboot"
fi

# Create VM
echo -e "\n${YELLOW}Creating VM...${NC}"
virsh define "$VM_XML"

rm "$VM_XML"

echo -e "\n${GREEN}=== VM Created Successfully! ===${NC}"
echo -e "VM Name: ${VM_NAME}"
echo -e "Username: ${VM_USER}"
echo -e "Password: ${VM_PASSWORD}"
echo -e ""
echo -e "Start the VM with: ${YELLOW}virsh start ${VM_NAME}${NC}"
echo -e "Connect to console: ${YELLOW}virsh console ${VM_NAME}${NC}"
echo -e "Get IP address: ${YELLOW}virsh domifaddr ${VM_NAME}${NC}"
echo -e ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Start the VM: virsh start ${VM_NAME}"
echo -e "2. Wait for cloud-init to complete (~2 minutes)"
echo -e "3. Get VM IP: virsh domifaddr ${VM_NAME}"
echo -e "4. Run Ansible playbook: cd deployment/ansible && ansible-playbook -i <VM_IP>, playbooks/site.yml"
