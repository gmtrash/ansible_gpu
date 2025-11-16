#!/bin/bash
# Toggle GPU passthrough on/off without removing configuration
# This script comments/uncomments VFIO config to enable/disable passthrough

set -e

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_NC='\033[0m'

VFIO_CONF="/etc/modprobe.d/vfio.conf"
VFIO_MODULES="/etc/modules-load.d/vfio.conf"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${COLOR_RED}Error: This script must be run as root${COLOR_NC}"
    echo "Usage: sudo $0 {enable|disable|status}"
    exit 1
fi

# Function to check current status
check_status() {
    if [ ! -f "$VFIO_CONF" ]; then
        echo "not_configured"
        return
    fi

    # Check if softdep lines are commented
    if grep -q "^#softdep nvidia pre: vfio-pci" "$VFIO_CONF" 2>/dev/null; then
        echo "disabled"
    elif grep -q "^softdep nvidia pre: vfio-pci" "$VFIO_CONF" 2>/dev/null; then
        echo "enabled"
    else
        echo "unknown"
    fi
}

# Function to show status
show_status() {
    local status=$(check_status)

    echo "=== GPU Passthrough Status ==="
    echo

    if [ "$status" = "not_configured" ]; then
        echo -e "${COLOR_YELLOW}Status: NOT CONFIGURED${COLOR_NC}"
        echo
        echo "GPU passthrough has not been set up yet."
        echo "Run: sudo ./system-config.sh"
        echo
        return
    fi

    if [ "$status" = "enabled" ]; then
        echo -e "${COLOR_GREEN}Status: ENABLED${COLOR_NC}"
        echo
        echo "GPU passthrough is currently ACTIVE."
        echo "NVIDIA GPU will be bound to VFIO-PCI on next boot."
        echo
        echo "To disable and use GPU on host:"
        echo "  sudo $0 disable"
        echo "  sudo reboot"
        echo
    elif [ "$status" = "disabled" ]; then
        echo -e "${COLOR_BLUE}Status: DISABLED${COLOR_NC}"
        echo
        echo "GPU passthrough is currently INACTIVE."
        echo "NVIDIA GPU will be available to host on next boot."
        echo
        echo "To enable for VM passthrough:"
        echo "  sudo $0 enable"
        echo "  sudo reboot"
        echo
    else
        echo -e "${COLOR_YELLOW}Status: UNKNOWN${COLOR_NC}"
        echo "Configuration file exists but format is unexpected."
        echo "You may need to run: sudo ./system-config.sh"
        echo
    fi

    # Show config file content
    if [ -f "$VFIO_CONF" ]; then
        echo "Configuration file: $VFIO_CONF"
        echo "---"
        cat "$VFIO_CONF"
        echo "---"
    fi
    echo
}

# Function to enable passthrough
enable_passthrough() {
    local status=$(check_status)

    if [ "$status" = "not_configured" ]; then
        echo -e "${COLOR_RED}Error: GPU passthrough not configured!${COLOR_NC}"
        echo
        echo "Please run the initial setup first:"
        echo "  sudo ./system-config.sh"
        echo
        exit 1
    fi

    if [ "$status" = "enabled" ]; then
        echo -e "${COLOR_YELLOW}GPU passthrough is already enabled!${COLOR_NC}"
        echo "No changes needed."
        exit 0
    fi

    echo "=== Enabling GPU Passthrough ==="
    echo

    # Create backup
    BACKUP_FILE="${VFIO_CONF}.backup.$(date +%Y%m%d-%H%M%S)"
    cp "$VFIO_CONF" "$BACKUP_FILE"
    echo -e "${COLOR_GREEN}Created backup: $BACKUP_FILE${COLOR_NC}"

    # Uncomment all lines (remove leading #)
    sed -i 's/^#//' "$VFIO_CONF"

    echo -e "${COLOR_GREEN}✓ Uncommented VFIO configuration${COLOR_NC}"
    echo

    # Update initramfs
    echo "Updating initramfs..."
    update-initramfs -u
    echo -e "${COLOR_GREEN}✓ Initramfs updated${COLOR_NC}"
    echo

    echo -e "${COLOR_GREEN}=== GPU Passthrough ENABLED ===${COLOR_NC}"
    echo
    echo "Configuration:"
    cat "$VFIO_CONF"
    echo
    echo -e "${COLOR_YELLOW}IMPORTANT: You must reboot for changes to take effect!${COLOR_NC}"
    echo
    echo "After reboot:"
    echo "  - NVIDIA GPU will be bound to vfio-pci"
    echo "  - GPU will be unavailable to host"
    echo "  - GPU will be available for VM passthrough"
    echo
    read -p "Do you want to reboot now? (y/n): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Rebooting in 5 seconds... (Ctrl+C to cancel)"
        sleep 5
        reboot
    else
        echo "Please reboot manually when ready: sudo reboot"
    fi
}

# Function to disable passthrough
disable_passthrough() {
    local status=$(check_status)

    if [ "$status" = "not_configured" ]; then
        echo -e "${COLOR_YELLOW}GPU passthrough not configured, nothing to disable.${COLOR_NC}"
        exit 0
    fi

    if [ "$status" = "disabled" ]; then
        echo -e "${COLOR_YELLOW}GPU passthrough is already disabled!${COLOR_NC}"
        echo "No changes needed."
        exit 0
    fi

    echo "=== Disabling GPU Passthrough ==="
    echo

    # Create backup
    BACKUP_FILE="${VFIO_CONF}.backup.$(date +%Y%m%d-%H%M%S)"
    cp "$VFIO_CONF" "$BACKUP_FILE"
    echo -e "${COLOR_GREEN}Created backup: $BACKUP_FILE${COLOR_NC}"

    # Comment out all non-comment, non-empty lines
    sed -i '/^[^#]/s/^/#/' "$VFIO_CONF"

    echo -e "${COLOR_GREEN}✓ Commented out VFIO configuration${COLOR_NC}"
    echo

    # Update initramfs
    echo "Updating initramfs..."
    update-initramfs -u
    echo -e "${COLOR_GREEN}✓ Initramfs updated${COLOR_NC}"
    echo

    echo -e "${COLOR_BLUE}=== GPU Passthrough DISABLED ===${COLOR_NC}"
    echo
    echo "Configuration (commented out):"
    cat "$VFIO_CONF"
    echo
    echo -e "${COLOR_YELLOW}IMPORTANT: You must reboot for changes to take effect!${COLOR_NC}"
    echo
    echo "After reboot:"
    echo "  - NVIDIA GPU will be available to host"
    echo "  - NVIDIA drivers will load normally"
    echo "  - GPU will work for desktop/gaming/compute"
    echo
    read -p "Do you want to reboot now? (y/n): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Rebooting in 5 seconds... (Ctrl+C to cancel)"
        sleep 5
        reboot
    else
        echo "Please reboot manually when ready: sudo reboot"
    fi
}

# Main script logic
case "${1:-}" in
    enable)
        enable_passthrough
        ;;
    disable)
        disable_passthrough
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: sudo $0 {enable|disable|status}"
        echo
        echo "Commands:"
        echo "  enable   - Enable GPU passthrough (uncomment VFIO config)"
        echo "  disable  - Disable GPU passthrough (comment out VFIO config)"
        echo "  status   - Show current passthrough status"
        echo
        echo "Example workflow:"
        echo "  1. Initial setup:  sudo ./system-config.sh"
        echo "  2. Check status:   sudo $0 status"
        echo "  3. Disable for host use:  sudo $0 disable && sudo reboot"
        echo "  4. Re-enable for VMs:     sudo $0 enable && sudo reboot"
        echo
        exit 1
        ;;
esac
