#!/bin/bash
#
# Deploy Stable Diffusion Forge Neo to VM using Ansible
# This script waits for the VM to be ready and runs the Ansible playbook
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
echo -e "${GREEN}Deploy Forge Neo to VM${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Get VM name
read -p "Enter VM name [forge-neo-gpu]: " VM_NAME
VM_NAME=${VM_NAME:-forge-neo-gpu}

# Check if VM exists
if ! virsh list --all | grep -q "$VM_NAME"; then
    echo -e "${RED}Error: VM '$VM_NAME' not found${NC}"
    echo "Available VMs:"
    virsh list --all
    exit 1
fi

# Check if VM is running
if ! virsh list --state-running | grep -q "$VM_NAME"; then
    echo -e "${YELLOW}VM is not running. Starting it now...${NC}"
    virsh start "$VM_NAME"
    echo -e "${GREEN}✓ VM started${NC}"
fi

# Get VM username
read -p "Enter VM username [ubuntu]: " VM_USER
VM_USER=${VM_USER:-ubuntu}

# Wait for VM to get an IP address
echo -e "\n${BLUE}Waiting for VM to get an IP address...${NC}"
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
    echo -e "${RED}Error: Could not get VM IP address after $((MAX_WAIT * 2)) seconds${NC}"
    echo "Try manually checking with: virsh domifaddr $VM_NAME"
    exit 1
fi

echo -e "${GREEN}✓ VM IP address: $VM_IP${NC}"

# Wait for SSH to be available
echo -e "\n${BLUE}Waiting for SSH to be available...${NC}"
MAX_SSH_WAIT=60
SSH_WAIT_COUNT=0

while [ $SSH_WAIT_COUNT -lt $MAX_SSH_WAIT ]; do
    if nc -z -w 2 "$VM_IP" 22 2>/dev/null; then
        echo -e "${GREEN}✓ SSH is available${NC}"
        break
    fi
    echo -n "."
    sleep 2
    SSH_WAIT_COUNT=$((SSH_WAIT_COUNT + 1))
done
echo ""

if [ $SSH_WAIT_COUNT -ge $MAX_SSH_WAIT ]; then
    echo -e "${RED}Error: SSH not available after $((MAX_SSH_WAIT * 2)) seconds${NC}"
    exit 1
fi

# Additional wait for cloud-init to complete
echo -e "\n${BLUE}Waiting for cloud-init to complete (this may take a few minutes)...${NC}"
sleep 10

# Check if SSH key authentication works
echo -e "\n${BLUE}Checking SSH authentication...${NC}"
SSH_KEY_WORKS=false
if ssh -o BatchMode=yes -o ConnectTimeout=5 "${VM_USER}@${VM_IP}" echo "test" &>/dev/null; then
    echo -e "${GREEN}✓ SSH key authentication available${NC}"
    SSH_KEY_WORKS=true
else
    echo -e "${YELLOW}⚠ SSH key not configured${NC}"
    read -p "Copy SSH key to VM now? [Y/n]: " COPY_KEY
    COPY_KEY=${COPY_KEY:-Y}
    if [[ $COPY_KEY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Copying SSH key...${NC}"
        ssh-copy-id "${VM_USER}@${VM_IP}"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ SSH key copied successfully${NC}"
            SSH_KEY_WORKS=true
        else
            echo -e "${YELLOW}⚠ Failed to copy SSH key, will use password${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Will use password authentication${NC}"
    fi
fi

# Run Ansible playbook
echo -e "\n${BLUE}Running Ansible playbook...${NC}"
if [ "$SSH_KEY_WORKS" = false ]; then
    echo -e "${YELLOW}You will be prompted for the SSH password${NC}\n"
    ANSIBLE_PASS_FLAG="--ask-pass"
else
    echo -e "${GREEN}Using SSH key authentication (no password needed)${NC}\n"
    ANSIBLE_PASS_FLAG=""
fi

cd "$SCRIPT_DIR/../ansible"

ansible-playbook -i "${VM_IP}," playbooks/site.yml \
    $ANSIBLE_PASS_FLAG \
    --extra-vars "ansible_user=${VM_USER}" \
    -v

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}Deployment Complete!${NC}"
    echo -e "${GREEN}========================================${NC}\n"
    echo -e "VM IP: ${YELLOW}${VM_IP}${NC}"
    echo -e "Username: ${YELLOW}${VM_USER}${NC}"
    echo -e "\n${YELLOW}Access Stable Diffusion WebUI:${NC}"
    echo -e "  From host: http://${VM_IP}:7860"
    echo -e "  From LAN:  http://$(hostname -I | awk '{print $1}'):7860 ${BLUE}(if macvtap configured)${NC}"
    echo -e "\n${YELLOW}Useful commands:${NC}"
    echo -e "  SSH to VM:     ssh ${VM_USER}@${VM_IP}"
    echo -e "  VM console:    virsh console ${VM_NAME}"
    echo -e "  Check service: ssh ${VM_USER}@${VM_IP} 'sudo systemctl status forge-neo'"
    echo -e "  View logs:     ssh ${VM_USER}@${VM_IP} 'sudo journalctl -u forge-neo -f'"
else
    echo -e "\n${RED}Deployment failed!${NC}"
    echo -e "Check the Ansible output above for errors"
    exit 1
fi
