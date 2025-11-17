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
for cmd in virsh virt-install qemu-img cloud-localds lspci ip ansible; do
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

# Check if IOMMU groups exist (non-root method)
if [ -d /sys/kernel/iommu_groups ] && [ -n "$(ls -A /sys/kernel/iommu_groups 2>/dev/null)" ]; then
    IOMMU_GROUP_COUNT=$(ls /sys/kernel/iommu_groups/ | wc -l)
    print_success "IOMMU is enabled ($IOMMU_GROUP_COUNT IOMMU groups found)"
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

# Phase 5: Create VM
print_step "Phase 5: Creating VM"

if [ -f "$SCRIPT_DIR/vm/create-vm.sh" ]; then
    print_success "Found create-vm.sh script"

    read -p "Do you want to create the VM now? (y/N): " CREATE_VM
    if [[ $CREATE_VM =~ ^[Yy]$ ]]; then
        echo ""
        echo "The script will guide you through VM creation."
        echo "You'll be asked for:"
        echo "  - GPU selection"
        echo "  - Network interface (optional - for Macvtap LAN access)"
        echo "  - VM username/password"
        echo "  - VM hostname"
        echo ""
        read -p "Press Enter to continue..."

        sudo "$SCRIPT_DIR/vm/create-vm.sh"

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
    print_error "create-vm.sh not found in $SCRIPT_DIR/vm/"
    VM_CREATED=false
fi

# Phase 6: SSH Key Setup (optional)
if [ "$VM_CREATED" = true ]; then
    print_step "Phase 6: SSH Key Setup (Optional)"

    echo "Would you like to set up SSH key authentication for the VM?"
    echo "This will:"
    echo "  - Start the VM if not running"
    echo "  - Wait for it to get an IP address"
    echo "  - Add an entry to ~/.ssh/config"
    echo "  - Copy your SSH public key to the VM (ssh-copy-id)"
    echo ""
    read -p "Set up SSH keys now? (y/N): " SETUP_SSH

    if [[ $SETUP_SSH =~ ^[Yy]$ ]]; then
        VM_NAME="forge-neo-gpu"

        # Check if VM is running
        if ! virsh list --state-running | grep -q "$VM_NAME"; then
            echo "Starting VM..."
            virsh start "$VM_NAME"
            sleep 5
        fi

        # Wait for VM to get an IP address
        echo "Waiting for VM to get an IP address..."
        VM_IP=""
        MAX_WAIT=60
        WAIT_COUNT=0

        while [ -z "$VM_IP" ] && [ $WAIT_COUNT -lt $MAX_WAIT ]; do
            VM_IP=$(virsh domifaddr "$VM_NAME" | grep -oP '192\.168\.\d+\.\d+' | head -1)
            if [ -z "$VM_IP" ]; then
                echo -n "."
                sleep 2
                WAIT_COUNT=$((WAIT_COUNT + 1))
            fi
        done
        echo ""

        if [ -z "$VM_IP" ]; then
            print_error "Could not get VM IP address after $((MAX_WAIT * 2)) seconds"
            echo "You can set up SSH keys manually later"
        else
            print_success "VM IP address: $VM_IP"

            # Wait for SSH to be available
            echo "Waiting for SSH to be available..."
            MAX_SSH_WAIT=60
            SSH_WAIT_COUNT=0

            while [ $SSH_WAIT_COUNT -lt $MAX_SSH_WAIT ]; do
                if nc -z -w 2 "$VM_IP" 22 2>/dev/null; then
                    print_success "SSH is available"
                    break
                fi
                echo -n "."
                sleep 2
                SSH_WAIT_COUNT=$((SSH_WAIT_COUNT + 1))
            done
            echo ""

            if [ $SSH_WAIT_COUNT -ge $MAX_SSH_WAIT ]; then
                print_error "SSH not available after $((MAX_SSH_WAIT * 2)) seconds"
                echo "You can set up SSH keys manually later"
            else
                # Add to ~/.ssh/config if not already there
                SSH_CONFIG="$HOME/.ssh/config"
                SSH_CONFIG_ENTRY="Host $VM_NAME
    HostName $VM_IP
    User ubuntu
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null"

                if [ -f "$SSH_CONFIG" ] && grep -q "Host $VM_NAME" "$SSH_CONFIG"; then
                    print_warning "SSH config entry for $VM_NAME already exists, skipping"
                else
                    echo "$SSH_CONFIG_ENTRY" >> "$SSH_CONFIG"
                    print_success "Added $VM_NAME to ~/.ssh/config"
                fi

                # Run ssh-copy-id
                echo ""
                echo "Copying SSH public key to VM..."
                echo "You will be prompted for the VM password"

                if [ -f "$HOME/.ssh/id_rsa.pub" ]; then
                    ssh-copy-id -i "$HOME/.ssh/id_rsa.pub" "ubuntu@$VM_IP"
                elif [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
                    ssh-copy-id -i "$HOME/.ssh/id_ed25519.pub" "ubuntu@$VM_IP"
                else
                    ssh-copy-id "ubuntu@$VM_IP"
                fi

                if [ $? -eq 0 ]; then
                    print_success "SSH key copied successfully!"
                    echo ""
                    echo "You can now SSH without password:"
                    echo "  ssh $VM_NAME"
                    echo "  (or: ssh ubuntu@$VM_IP)"
                fi
            fi
        fi
    fi
fi

# Phase 9: Next Steps
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

echo -e "\n${BLUE}Next Steps:${NC}\n"

if [ "$VM_CREATED" = true ]; then
    echo "1. Deploy Forge Neo to the VM:"
    echo "   cd $SCRIPT_DIR"
    echo "   ./deploy-forge-to-vm.sh"
    echo ""
    echo "2. Access Forge Neo WebUI (after deployment completes):"
    echo "   http://<VM-IP>:7860"
    echo ""
    echo "Alternative manual steps:"
    echo "  - Check VM console: virsh console forge-neo-gpu"
    echo "  - Get VM IP: virsh domifaddr forge-neo-gpu"
    echo "  - SSH to VM: ssh <username>@<VM-IP>"
else
    echo "1. Run this script again and choose to create the VM"
    echo "2. Or manually run: sudo $SCRIPT_DIR/vm/create-vm.sh"
fi

echo -e "\n${BLUE}Documentation:${NC}"
echo "  - Full guide: ../README.md"

echo -e "\n${GREEN}Setup helper completed!${NC}\n"
