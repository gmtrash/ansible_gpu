#!/bin/bash
# Setup virtiofs for shared models directory
# Run this AFTER deploy-forge-to-vm.sh completes successfully

set -e

# Configuration
VM_NAME="forge-neo-gpu"
HOST_MODELS_DIR="/media/aubreybailey/vms/models/safetensors"
GUEST_MOUNT_POINT="/mnt/models"
VIRTIOFS_TAG="models-share"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Forge Neo - virtiofs Models Setup${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if host models directory exists
if [ ! -d "$HOST_MODELS_DIR" ]; then
    echo -e "${RED}Error: Host models directory does not exist: $HOST_MODELS_DIR${NC}"
    echo "Please create it or update HOST_MODELS_DIR in this script."
    exit 1
fi

echo -e "${GREEN}✓${NC} Host models directory found: $HOST_MODELS_DIR"

# Check if VM exists
if ! virsh list --all | grep -q "$VM_NAME"; then
    echo -e "${RED}Error: VM '$VM_NAME' not found${NC}"
    echo "Please run deploy-forge-to-vm.sh first."
    exit 1
fi

echo -e "${GREEN}✓${NC} VM found: $VM_NAME"

# Get VM state
VM_STATE=$(virsh domstate "$VM_NAME")
echo "Current VM state: $VM_STATE"

# Shutdown VM if running
if [ "$VM_STATE" == "running" ]; then
    echo -e "${YELLOW}Shutting down VM to modify configuration...${NC}"
    virsh shutdown "$VM_NAME"

    # Wait for shutdown (max 60 seconds)
    echo -n "Waiting for VM to shutdown"
    for i in {1..60}; do
        sleep 1
        echo -n "."
        VM_STATE=$(virsh domstate "$VM_NAME")
        if [ "$VM_STATE" == "shut off" ]; then
            echo ""
            break
        fi
    done

    if [ "$VM_STATE" != "shut off" ]; then
        echo -e "${YELLOW}VM didn't shutdown gracefully, forcing...${NC}"
        virsh destroy "$VM_NAME"
        sleep 2
    fi
fi

echo -e "${GREEN}✓${NC} VM is shut off"

# Check if virtiofs is already configured
if virsh dumpxml "$VM_NAME" | grep -q "<target dir='$VIRTIOFS_TAG'/>"; then
    echo -e "${YELLOW}⚠${NC}  virtiofs already configured, skipping XML modification"
else
    echo "Adding virtiofs filesystem to VM configuration..."

    # Create temporary XML snippet
    TEMP_XML=$(mktemp)
    cat > "$TEMP_XML" <<EOF
<filesystem type='mount' accessmode='passthrough'>
  <driver type='virtiofs' queue='1024'/>
  <source dir='$HOST_MODELS_DIR'/>
  <target dir='$VIRTIOFS_TAG'/>
</filesystem>
EOF

    # Attach the filesystem
    if virsh attach-device "$VM_NAME" "$TEMP_XML" --config; then
        echo -e "${GREEN}✓${NC} virtiofs filesystem added to VM configuration"
    else
        echo -e "${RED}Error: Failed to attach virtiofs filesystem${NC}"
        echo "You may need to manually edit the VM XML:"
        echo "  virsh edit $VM_NAME"
        cat "$TEMP_XML"
        rm "$TEMP_XML"
        exit 1
    fi

    rm "$TEMP_XML"
fi

# Check/add memory backing for virtiofs
echo "Checking memory backing configuration..."
if ! virsh dumpxml "$VM_NAME" | grep -q "<memoryBacking>"; then
    echo -e "${YELLOW}⚠${NC}  Adding memory backing configuration (required for virtiofs)..."

    # This needs to be done with virsh edit, so we'll provide instructions
    echo -e "${YELLOW}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "MANUAL STEP REQUIRED:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Please add the following to your VM XML (after <memory>):"
    echo ""
    echo "  <memoryBacking>"
    echo "    <source type='memfd'/>"
    echo "    <access mode='shared'/>"
    echo "  </memoryBacking>"
    echo ""
    echo "Run: virsh edit $VM_NAME"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${NC}"

    read -p "Press Enter after you've added the memory backing configuration..."
else
    echo -e "${GREEN}✓${NC} Memory backing already configured"
fi

# Start the VM
echo "Starting VM..."
virsh start "$VM_NAME"
sleep 5

# Wait for VM to get IP address
echo -n "Waiting for VM to get IP address"
VM_IP=""
for i in {1..60}; do
    VM_IP=$(virsh domifaddr "$VM_NAME" | grep -oP '192\.168\.\d+\.\d+' | head -1)
    if [ -n "$VM_IP" ]; then
        echo ""
        break
    fi
    echo -n "."
    sleep 1
done

if [ -z "$VM_IP" ]; then
    echo -e "${RED}Error: Could not get VM IP address${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} VM IP: $VM_IP"

# Wait for SSH
echo -n "Waiting for SSH to be available"
for i in {1..60}; do
    if ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no "ubuntu@$VM_IP" "exit" 2>/dev/null; then
        echo ""
        break
    fi
    echo -n "."
    sleep 2
done

echo -e "${GREEN}✓${NC} SSH is available"

# Configure guest mounting
echo "Configuring virtiofs mount in guest..."

ssh "ubuntu@$VM_IP" bash <<'EOSSH'
set -e

# Create mount point
sudo mkdir -p /mnt/models

# Mount virtiofs
if ! mountpoint -q /mnt/models; then
    echo "Mounting virtiofs..."
    sudo mount -t virtiofs models-share /mnt/models
    echo "✓ Mounted virtiofs at /mnt/models"
else
    echo "✓ Already mounted"
fi

# Add to fstab if not present
if ! grep -q "models-share" /etc/fstab; then
    echo "Adding to /etc/fstab for automatic mounting..."
    echo "models-share  /mnt/models  virtiofs  defaults  0  0" | sudo tee -a /etc/fstab
    echo "✓ Added to fstab"
else
    echo "✓ Already in fstab"
fi

# Test the mount
echo "Testing mount..."
ls -la /mnt/models/ | head -5
EOSSH

echo -e "${GREEN}✓${NC} Guest mounting configured"

# Set up symlinks
echo "Setting up symlinks to Forge Neo models directory..."

ssh "ubuntu@$VM_IP" bash <<'EOSSH'
set -e

FORGE_MODELS_DIR="/home/ubuntu/forge-neo/app/models/Stable-diffusion"

# Create shared subdirectory if it doesn't exist
if [ ! -L "$FORGE_MODELS_DIR/shared" ] && [ ! -d "$FORGE_MODELS_DIR/shared" ]; then
    echo "Creating symlink: $FORGE_MODELS_DIR/shared -> /mnt/models"
    ln -s /mnt/models "$FORGE_MODELS_DIR/shared"
    echo "✓ Symlink created"
else
    echo "✓ Symlink already exists"
fi

# List available models
echo ""
echo "Available models in /mnt/models:"
ls -lh /mnt/models/ | grep -E "\.safetensors|\.ckpt" || echo "No models found (might be in subdirectories)"
EOSSH

echo -e "${GREEN}✓${NC} Symlinks configured"

# Restart forge-neo service
echo "Restarting forge-neo service..."
ssh "ubuntu@$VM_IP" "sudo systemctl restart forge-neo"
sleep 2

# Final status
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Models directory setup:"
echo "  Host: $HOST_MODELS_DIR"
echo "  Guest mount: $GUEST_MOUNT_POINT"
echo "  Forge Neo access: /home/ubuntu/forge-neo/app/models/Stable-diffusion/shared/"
echo ""
echo "Your models are now accessible in the WebUI!"
echo "WebUI URL: http://$VM_IP:7860"
echo ""
echo -e "${YELLOW}Note:${NC} Models from the host directory will appear in the"
echo "       'shared' subdirectory in the Forge Neo model selector."
