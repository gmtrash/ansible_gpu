#!/bin/bash
# Fix Macvtap interface activation for existing VMs
# Run this inside the VM as: sudo ./fix-macvtap.sh

set -e

echo "Creating netplan configuration for all network interfaces..."

cat > /etc/netplan/99-all-interfaces.yaml <<'EOF'
network:
  version: 2
  ethernets:
    enp1s0:
      dhcp4: true
      dhcp6: true
    enp9s0:
      dhcp4: true
      dhcp6: true
      optional: true
EOF

echo "Setting permissions..."
chmod 600 /etc/netplan/99-all-interfaces.yaml

echo "Applying network configuration..."
netplan apply

echo ""
echo "Waiting for interface to come up..."
sleep 3

echo ""
echo "Current network status:"
ip addr show enp9s0

echo ""
echo "Done! Check if enp9s0 has an IP address above."
echo "If it doesn't have an IPv4 address yet, wait a moment and run: ip addr show enp9s0"
