#!/bin/bash
#
# Add VirtioFS shared directory to VM for model files
# This allows the guest VM to access host LLM models without copying
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
HOST_MODELS_DIR="/media/aubreybailey/vms/models"
VIRTIOFS_TAG="models"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Add VirtioFS Model Share to VM${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Get VM name
if [ -z "$1" ]; then
    read -p "Enter VM name [forge-neo-gpu]: " VM_NAME
    VM_NAME=${VM_NAME:-forge-neo-gpu}
else
    VM_NAME="$1"
fi

# Check if VM exists
if ! virsh list --all | grep -q "$VM_NAME"; then
    echo -e "${RED}Error: VM '$VM_NAME' not found${NC}"
    echo "Available VMs:"
    virsh list --all
    exit 1
fi

# Check if host directory exists
if [ ! -d "$HOST_MODELS_DIR" ]; then
    echo -e "${YELLOW}Warning: Host models directory does not exist: $HOST_MODELS_DIR${NC}"
    read -p "Create it now? [Y/n]: " CREATE_DIR
    CREATE_DIR=${CREATE_DIR:-Y}
    if [[ $CREATE_DIR =~ ^[Yy]$ ]]; then
        sudo mkdir -p "$HOST_MODELS_DIR"
        sudo chown $USER:$USER "$HOST_MODELS_DIR"
        echo -e "${GREEN}✓ Created $HOST_MODELS_DIR${NC}"
    else
        echo -e "${RED}Cannot continue without host directory${NC}"
        exit 1
    fi
fi

# Check if virtiofs is already configured
if virsh dumpxml "$VM_NAME" | grep -q "type='virtiofs'"; then
    echo -e "${YELLOW}⚠ VirtioFS already configured for this VM${NC}"
    read -p "Reconfigure it? [y/N]: " RECONFIG
    RECONFIG=${RECONFIG:-N}
    if [[ ! $RECONFIG =~ ^[Yy]$ ]]; then
        echo "Exiting without changes"
        exit 0
    fi
    echo -e "${BLUE}Removing existing virtiofs configuration...${NC}"
    # This would require more complex XML manipulation
    # For now, just add it and let libvirt handle duplicates
fi

# Check if VM is running
VM_RUNNING=false
if virsh list --state-running | grep -q "$VM_NAME"; then
    VM_RUNNING=true
    echo -e "${YELLOW}⚠ VM is running. It must be shut down to add virtiofs.${NC}"
    read -p "Shut down VM now? [Y/n]: " SHUTDOWN
    SHUTDOWN=${SHUTDOWN:-Y}
    if [[ $SHUTDOWN =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Shutting down VM...${NC}"
        virsh shutdown "$VM_NAME"

        # Wait for shutdown
        echo -n "Waiting for VM to shut down"
        WAIT_COUNT=0
        while virsh list --state-running | grep -q "$VM_NAME" && [ $WAIT_COUNT -lt 30 ]; do
            echo -n "."
            sleep 2
            WAIT_COUNT=$((WAIT_COUNT + 1))
        done
        echo ""

        # Force shutdown if still running
        if virsh list --state-running | grep -q "$VM_NAME"; then
            echo -e "${YELLOW}Force stopping VM...${NC}"
            virsh destroy "$VM_NAME"
            sleep 2
        fi

        echo -e "${GREEN}✓ VM shut down${NC}"
    else
        echo -e "${RED}Cannot continue with VM running${NC}"
        exit 1
    fi
fi

# Add virtiofs device
echo -e "\n${BLUE}Adding VirtioFS device to VM...${NC}"

# Create temporary XML file for the filesystem device
TEMP_XML=$(mktemp)
cat > "$TEMP_XML" <<EOF
<filesystem type='mount' accessmode='passthrough'>
  <driver type='virtiofs'/>
  <source dir='$HOST_MODELS_DIR'/>
  <target dir='$VIRTIOFS_TAG'/>
</filesystem>
EOF

# Attach the device
virsh attach-device "$VM_NAME" "$TEMP_XML" --config

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ VirtioFS device added successfully${NC}"
else
    echo -e "${RED}✗ Failed to add VirtioFS device${NC}"
    rm "$TEMP_XML"
    exit 1
fi

rm "$TEMP_XML"

# Display configuration
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}VirtioFS Configuration Complete${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "Host directory: ${YELLOW}$HOST_MODELS_DIR${NC}"
echo -e "VirtioFS tag:   ${YELLOW}$VIRTIOFS_TAG${NC}"
echo -e "VM:             ${YELLOW}$VM_NAME${NC}"

echo -e "\n${YELLOW}Next steps:${NC}"
echo -e "1. Start the VM: ${BLUE}virsh start $VM_NAME${NC}"
echo -e "2. Re-run the Ansible deployment to mount the share"
echo -e "   The virtiofs role will automatically mount it in the guest"

if [ "$VM_RUNNING" = true ]; then
    echo -e "\n${BLUE}Starting VM...${NC}"
    virsh start "$VM_NAME"
    echo -e "${GREEN}✓ VM started${NC}"
fi

echo -e "\n${GREEN}Done!${NC}"
