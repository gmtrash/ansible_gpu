#!/bin/bash
# Quick start script for Ansible deployment
# This script helps you get started with deploying your Ubuntu + SD Forge setup

set -e

echo "============================================"
echo "Ansible Deployment Quick Start"
echo "Ubuntu Desktop + SD Forge CUDA"
echo "============================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if running on Ubuntu
if [ ! -f /etc/lsb-release ]; then
    echo -e "${RED}Error: This script is designed for Ubuntu.${NC}"
    exit 1
fi

source /etc/lsb-release
echo -e "${GREEN}Detected: $DISTRIB_DESCRIPTION${NC}"
echo ""

# Check if Ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo -e "${YELLOW}Ansible is not installed. Installing now...${NC}"
    sudo apt update
    sudo apt install -y ansible git
    echo -e "${GREEN}✓ Ansible installed${NC}"
else
    echo -e "${GREEN}✓ Ansible is already installed${NC}"
    ansible --version | head -1
fi
echo ""

# Check if we're in the right directory
if [ ! -f "main.yml" ]; then
    echo -e "${RED}Error: main.yml not found. Please run this from the ansible/ directory.${NC}"
    exit 1
fi

echo "This script will configure your system with:"
echo "  - Base system packages"
echo "  - NVIDIA drivers and CUDA toolkit for GPU acceleration"
echo "  - Conda/Miniforge"
echo "  - Stable Diffusion WebUI Forge (CUDA)"
echo "  - Desktop preferences and shortcuts"
echo ""

echo -e "${YELLOW}Before proceeding:${NC}"
echo "  1. Review and edit: group_vars/localhost.yml"
echo "  2. Check your username, email, and preferences"
echo "  3. Ensure you have sudo access"
echo ""

read -p "Have you reviewed the configuration? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Please edit: group_vars/localhost.yml"
    echo "Then run this script again."
    exit 0
fi

echo ""
echo "Choose deployment option:"
echo "  1) Full deployment (everything)"
echo "  2) Dry run (check mode - no changes)"
echo "  3) NVIDIA/CUDA only"
echo "  4) SD Forge only (assumes NVIDIA/CUDA/conda already installed)"
echo "  5) Custom (you'll specify tags)"
echo ""

read -p "Enter choice (1-5): " choice

case $choice in
    1)
        echo ""
        echo -e "${GREEN}Running full deployment...${NC}"
        ansible-playbook main.yml --ask-become-pass
        ;;
    2)
        echo ""
        echo -e "${YELLOW}Running dry run (check mode)...${NC}"
        ansible-playbook main.yml --check --ask-become-pass
        ;;
    3)
        echo ""
        echo -e "${GREEN}Installing NVIDIA/CUDA only...${NC}"
        ansible-playbook main.yml --tags "base,nvidia" --ask-become-pass
        ;;
    4)
        echo ""
        echo -e "${GREEN}Installing SD Forge only...${NC}"
        ansible-playbook main.yml --tags "forge" --ask-become-pass
        ;;
    5)
        echo ""
        echo "Available tags: base, nvidia, conda, forge, desktop"
        read -p "Enter tags (comma-separated): " tags
        ansible-playbook main.yml --tags "$tags" --ask-become-pass
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo "============================================"
echo -e "${GREEN}Deployment complete!${NC}"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Reboot your system (REQUIRED for NVIDIA driver)"
echo "  2. Verify NVIDIA: nvidia-smi"
echo "  3. Verify CUDA: nvcc --version"
echo "  4. Check installation log: cat ~/.ansible-deployment-log"
echo "  5. Launch Forge: forge-launch (or cd ~/llm/sd-webui-forge && ./launch-cuda.sh)"
echo ""
