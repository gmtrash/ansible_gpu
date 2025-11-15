#!/bin/bash
# Configure the second NAT interface in Ubuntu VM
# Run this script inside the Ubuntu VM after SSHing from another machine

echo "Checking network interfaces..."
ip link show

echo ""
echo "Current IP addresses:"
ip addr show

echo ""
echo "Finding interface without IP address..."
NAT_IFACE=$(ip -br addr show | grep -v "lo\|UP.*[0-9]\+\.[0-9]\+" | awk '{print $1}' | head -1)

if [ -z "$NAT_IFACE" ]; then
    echo "Error: Could not find interface without IP"
    echo "Please manually identify the second interface and edit this script"
    exit 1
fi

echo "Found interface without IP: $NAT_IFACE"
echo ""
echo "Configuring $NAT_IFACE for DHCP..."

# Backup netplan config
sudo cp /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.backup

# Add the second interface to netplan
sudo tee -a /etc/netplan/50-cloud-init.yaml > /dev/null <<EOF

    $NAT_IFACE:
      dhcp4: true
EOF

echo "✓ Netplan configuration updated"
echo ""
echo "Applying netplan changes..."
sudo netplan apply

echo ""
echo "Waiting for DHCP..."
sleep 3

echo ""
echo "New IP addresses:"
ip addr show

echo ""
NAT_IP=$(ip -4 addr show $NAT_IFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
if [ -n "$NAT_IP" ]; then
    echo "✓ NAT interface $NAT_IFACE got IP: $NAT_IP"
    echo ""
    echo "Testing connectivity to host (192.168.122.1)..."
    if ping -c 2 192.168.122.1 > /dev/null 2>&1; then
        echo "✓ Can reach host!"
        echo ""
        echo "======================================"
        echo "Configuration successful!"
        echo "======================================"
        echo ""
        echo "NAT IP for port forwarding: $NAT_IP"
        echo ""
        echo "Update the socat script on the host with:"
        echo "  UBUNTU_IP=\"$NAT_IP\""
    else
        echo "⚠ Cannot reach host yet, but interface is configured"
    fi
else
    echo "⚠ Interface configured but no IP yet. Check with: ip addr show $NAT_IFACE"
fi
