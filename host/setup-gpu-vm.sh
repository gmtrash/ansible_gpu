#!/bin/bash
#
# GPU Passthrough VM Setup Helper
# This script guides you through the GPU passthrough setup process
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}GPU Passthrough VM Setup Helper${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}Error: Don't run this script as root${NC}"
   echo "Run as normal user - it will ask for sudo when needed"
   exit 1
fi

# Function to check command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print step
print_step() {
    echo -e "\n${BLUE}==>${NC} ${GREEN}$1${NC}\n"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

# Function to print error
print_error() {
    echo -e "${RED}Error:${NC} $1"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Phase 1: Check Prerequisites
print_step "Phase 1: Checking Prerequisites"

echo "Checking required commands..."

MISSING_CMDS=()
for cmd in virsh virt-install qemu-img lspci ip ansible; do
    if command_exists $cmd; then
        print_success "$cmd found"
    else
        print_warning "$cmd not found"
        MISSING_CMDS+=($cmd)
    fi
done

if [ ${#MISSING_CMDS[@]} -gt 0 ]; then
    print_warning "Missing required packages"
    echo -e "\nInstall with:"
    echo -e "${YELLOW}sudo apt install -y qemu-kvm libvirt-daemon-system virtinst libvirt-clients virt-manager cloud-image-utils ovmf pciutils iproute2 ansible${NC}\n"

    read -p "Install missing packages now? (y/N): " INSTALL_PKGS
    if [[ $INSTALL_PKGS =~ ^[Yy]$ ]]; then
        sudo apt update
        sudo apt install -y qemu-kvm libvirt-daemon-system virtinst libvirt-clients \
            virt-manager cloud-image-utils ovmf pciutils iproute2 ansible
        print_success "Packages installed"
    else
        print_error "Required packages not installed. Exiting."
        exit 1
    fi
fi

# Check user is in libvirt group
if groups | grep -q libvirt; then
    print_success "User in libvirt group"
else
    print_warning "User not in libvirt group"
    echo "Adding user to libvirt and kvm groups..."
    sudo usermod -aG libvirt,kvm $USER
    print_warning "Group membership updated. Please log out and log back in, then run this script again."
    exit 0
fi

# Phase 2: Check IOMMU
print_step "Phase 2: Checking IOMMU Status"

if dmesg | grep -qi "iommu.*enabled"; then
    print_success "IOMMU is enabled"
else
    print_error "IOMMU not enabled in kernel"
    echo ""
    echo "You need to enable IOMMU in BIOS and kernel parameters."
    echo ""
    echo "Steps:"
    echo "1. Reboot and enter BIOS/UEFI"
    echo "2. Enable Intel VT-d (Intel) or AMD-Vi (AMD)"
    echo "3. Edit /etc/default/grub and add to GRUB_CMDLINE_LINUX:"
    echo "   For Intel: intel_iommu=on iommu=pt"
    echo "   For AMD:   amd_iommu=on iommu=pt"
    echo "4. Run: sudo update-grub"
    echo "5. Reboot"
    echo ""
    echo "See SETUP-GPU-PASSTHROUGH.md for detailed instructions."
    exit 1
fi

# Phase 3: Detect GPUs
print_step "Phase 3: Detecting NVIDIA GPUs"

if ! lspci -nn | grep -qi nvidia; then
    print_error "No NVIDIA GPU detected"
    echo "This script is designed for NVIDIA GPU passthrough."
    echo "If you have an AMD GPU, see SETUP-GPU-PASSTHROUGH.md for manual setup."
    exit 1
fi

echo "Found NVIDIA GPUs:"
lspci -nn | grep -i nvidia | nl -w2 -s'. '

GPU_COUNT=$(lspci -nn | grep -i nvidia | grep -i "VGA\|3D" | wc -l)
echo -e "\nTotal GPUs: $GPU_COUNT"

if [ "$GPU_COUNT" -eq 0 ]; then
    print_error "No NVIDIA VGA/3D controllers found"
    exit 1
fi

# Phase 4: Check VFIO Configuration
print_step "Phase 4: Checking VFIO Configuration"

if lspci -nnk | grep -A3 "NVIDIA" | grep -q "vfio-pci"; then
    print_success "GPU is bound to vfio-pci driver"
    VFIO_CONFIGURED=true
else
    print_warning "GPU not bound to vfio-pci driver"
    VFIO_CONFIGURED=false

    echo ""
    echo "To configure VFIO, you need to:"
    echo "1. Get your GPU device IDs: lspci -nn | grep -i nvidia"
    echo "2. Add them to /etc/modprobe.d/vfio.conf"
    echo "3. Update initramfs and reboot"
    echo ""
    echo "See SETUP-GPU-PASSTHROUGH.md Phase 1 Step 1.4 for detailed instructions."
    echo ""

    read -p "Do you want to configure VFIO now? (y/N): " CONFIGURE_VFIO
    if [[ $CONFIGURE_VFIO =~ ^[Yy]$ ]]; then
        echo ""
        echo "Enter GPU PCI IDs (comma-separated, e.g., 10de:2684,10de:22ba):"
        lspci -nn | grep -i nvidia | grep -E "VGA|Audio"
        echo ""
        read -p "GPU IDs: " GPU_IDS

        if [ -z "$GPU_IDS" ]; then
            print_error "No GPU IDs provided"
            exit 1
        fi

        # Configure VFIO
        echo "options vfio-pci ids=$GPU_IDS" | sudo tee /etc/modprobe.d/vfio.conf

        echo "vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd" | sudo tee /etc/modules-load.d/vfio.conf

        sudo update-initramfs -u

        print_success "VFIO configured"
        print_warning "You must reboot for changes to take effect"

        read -p "Reboot now? (y/N): " REBOOT_NOW
        if [[ $REBOOT_NOW =~ ^[Yy]$ ]]; then
            sudo reboot
        else
            echo "Please reboot manually and run this script again."
            exit 0
        fi
    fi
fi

# Phase 5: Network Configuration
print_step "Phase 5: Checking Network Configuration"

echo "Available network interfaces:"
ip -brief link show | grep -v "^lo"

echo -e "\nFor macvtap networking, you need to specify your physical network interface."
read -p "Enter your physical network interface (e.g., enp7s0, eth0): " PHYS_IFACE

if [ -z "$PHYS_IFACE" ]; then
    print_warning "No interface specified, will use default NAT only"
    USE_MACVTAP=false
else
    if ip link show "$PHYS_IFACE" >/dev/null 2>&1; then
        print_success "Interface $PHYS_IFACE exists"
        USE_MACVTAP=true

        # Update macvtap config
        sed -i "s|<interface dev=\".*\"|<interface dev=\"$PHYS_IFACE\"|" \
            "$SCRIPT_DIR/configs/libvirt-macvtap-network.xml"
        print_success "Updated macvtap configuration"
    else
        print_error "Interface $PHYS_IFACE not found"
        USE_MACVTAP=false
    fi
fi

# Phase 6: Create VM
print_step "Phase 6: Creating VM"

if [ -f "$SCRIPT_DIR/host/vm/create-vm.sh" ]; then
    print_success "Found create-vm.sh script"

    read -p "Do you want to create the VM now? (y/N): " CREATE_VM
    if [[ $CREATE_VM =~ ^[Yy]$ ]]; then
        echo ""
        echo "The script will guide you through VM creation."
        echo "You'll be asked for:"
        echo "  - GPU selection"
        echo "  - VM username/password"
        echo "  - VM hostname"
        echo ""
        read -p "Press Enter to continue..."

        sudo "$SCRIPT_DIR/host/vm/create-vm.sh"

        if [ $? -eq 0 ]; then
            print_success "VM created successfully"
            VM_CREATED=true
        else
            print_error "VM creation failed"
            VM_CREATED=false
        fi
    else
        VM_CREATED=false
    fi
else
    print_error "create-vm.sh not found in $SCRIPT_DIR/host/vm/"
    VM_CREATED=false
fi

# Phase 7: Configure Networking (if VM was created)
if [ "$VM_CREATED" = true ] && [ "$USE_MACVTAP" = true ]; then
    print_step "Phase 7: Configuring Dual Networking"

    VM_NAME="forge-neo-gpu"

    echo "Setting up macvtap network..."
    if virsh net-list --all | grep -q "macvtap-bridge"; then
        print_success "macvtap-bridge network already exists"
    else
        virsh net-define "$SCRIPT_DIR/configs/libvirt-macvtap-network.xml"
        virsh net-start macvtap-bridge
        virsh net-autostart macvtap-bridge
        print_success "macvtap-bridge network created"
    fi

    echo "Adding macvtap interface to VM..."
    virsh shutdown "$VM_NAME" 2>/dev/null || true
    sleep 5

    virsh attach-interface "$VM_NAME" \
        --type network \
        --source macvtap-bridge \
        --model virtio \
        --config 2>/dev/null || print_warning "Interface may already exist"

    virsh start "$VM_NAME"
    print_success "VM started with dual networking"
fi

# Phase 8: Next Steps
print_step "Setup Summary"

echo -e "${GREEN}✓ Prerequisites installed${NC}"
echo -e "${GREEN}✓ IOMMU enabled${NC}"
if [ "$VFIO_CONFIGURED" = true ]; then
    echo -e "${GREEN}✓ VFIO configured${NC}"
else
    echo -e "${YELLOW}⚠ VFIO needs configuration${NC}"
fi
if [ "$VM_CREATED" = true ]; then
    echo -e "${GREEN}✓ VM created${NC}"
else
    echo -e "${YELLOW}⚠ VM not created${NC}"
fi
if [ "$USE_MACVTAP" = true ]; then
    echo -e "${GREEN}✓ Dual networking configured${NC}"
else
    echo -e "${YELLOW}⚠ Using NAT only${NC}"
fi

echo -e "\n${BLUE}Next Steps:${NC}\n"

if [ "$VM_CREATED" = true ]; then
    echo "1. Wait for VM to finish cloud-init (~2 minutes)"
    echo "   Check with: virsh console forge-neo-gpu"
    echo ""
    echo "2. Get VM IP address:"
    echo "   virsh domifaddr forge-neo-gpu"
    echo ""
    echo "3. SSH into VM:"
    echo "   ssh ubuntu@<VM-IP>"
    echo ""
    echo "4. Configure dual networking (if using macvtap):"
    echo "   See configure-dual-networking.md"
    echo ""
    echo "5. Run Ansible playbook to install Forge Neo:"
    echo "   cd ansible"
    echo "   # Edit inventory/hosts.ini with VM IP"
    echo "   ansible-playbook -i inventory/hosts.ini playbooks/site.yml"
    echo ""
    echo "6. Access Forge Neo WebUI:"
    echo "   http://<VM-IP>:7860"
else
    echo "1. Configure VFIO if not done (see SETUP-GPU-PASSTHROUGH.md)"
    echo "2. Reboot if needed"
    echo "3. Run this script again to create VM"
fi

echo -e "\n${BLUE}Documentation:${NC}"
echo "  - Full guide: SETUP-GPU-PASSTHROUGH.md"
echo "  - Networking: configure-dual-networking.md"
echo "  - Quick reference: QUICKREF.md"

echo -e "\n${GREEN}Setup helper completed!${NC}\n"
