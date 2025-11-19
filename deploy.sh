#!/bin/bash
set -e

# AIO deployment script for Forge Neo GPU VM
# Usage: ./deploy.sh <VM_IP> [ansible_user]

if [ -z "$1" ]; then
    echo "Usage: $0 <VM_IP> [ansible_user]"
    echo "Example: $0 192.168.122.171 ubuntu"
    exit 1
fi

VM_IP="$1"
ANSIBLE_USER="${2:-ubuntu}"

echo "=========================================="
echo "Deploying Forge Neo to ${VM_IP}"
echo "User: ${ANSIBLE_USER}"
echo "=========================================="

# Test SSH connectivity
echo "Testing SSH connection..."
ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${ANSIBLE_USER}@${VM_IP}" "echo 'SSH OK'" || {
    echo "ERROR: Cannot connect to ${VM_IP}"
    echo "Make sure:"
    echo "  1. VM is running and accessible"
    echo "  2. SSH keys are set up: ssh-copy-id ${ANSIBLE_USER}@${VM_IP}"
    exit 1
}

# Run Ansible playbook with inline inventory
echo "Running Ansible deployment..."
cd ansible
ansible-playbook \
    -i "${VM_IP}," \
    -u "${ANSIBLE_USER}" \
    -e "ansible_python_interpreter=/usr/bin/python3" \
    playbooks/site.yml

echo "=========================================="
echo "Deployment complete!"
echo "After the VM reboots, access Forge Neo at:"
echo "  http://${VM_IP}:7860"
echo "=========================================="
