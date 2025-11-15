# Dual Networking Setup - Macvtap + NAT

Both VMs now have two network interfaces:

## Ubuntu ML VM

**Interface 1 (macvtap):** For LAN access - 192.168.1.11
**Interface 2 (NAT):** For host access - will be 192.168.122.x

### Configure Second Interface in Ubuntu

SSH into Ubuntu from another machine, then:

```bash
# Check network interfaces
ip link show

# You should see two interfaces, something like:
# - enp1s0 (macvtap, has 192.168.1.11)
# - enp7s0 (NAT, no IP yet)

# Find which interface has no IP
ip addr show

# Configure netplan to enable the second interface
sudo tee -a /etc/netplan/50-cloud-init.yaml > /dev/null <<'EOF'

    enp7s0:
      dhcp4: true
EOF

# Apply netplan (replace enp7s0 with your actual second interface name)
sudo netplan apply

# Check if it got an IP
ip addr show

# Test connectivity to host
ping -c 2 192.168.122.1
```

Once the second interface gets an IP (like 192.168.122.x), note it down.

## Windows 11 VM

**Interface 1 (macvtap):** For LAN access - 192.168.1.20
**Interface 2 (NAT):** For host access - configure manually

### Configure Second Interface in Windows

1. Start Windows VM
2. Open **Network & Internet** settings
3. You should see **two Ethernet adapters**
4. Configure them:
   - **Ethernet 1:** Set to 192.168.1.20 (for LAN) - already done
   - **Ethernet 2:** Set to DHCP or manual:
     - IP: 192.168.122.10 (or any IP in 192.168.122.0/24 range)
     - Subnet: 255.255.255.0
     - Gateway: 192.168.122.1

## Update Port Forwarding to Use NAT IPs

Once both VMs have NAT IPs, update the socat service:

```bash
# Edit the wrapper script
sudo nano /usr/local/bin/vm-port-forward-start.sh

# Change the IPs:
# UBUNTU_IP="192.168.122.x"  # Replace with actual NAT IP
# WIN11_IP="192.168.122.10"   # Or whatever you set

# Restart the service
sudo systemctl restart vm-port-forward.service
```

## Network Summary

| VM | Purpose | Macvtap IP (LAN) | NAT IP (Host Access) |
|----|---------|------------------|----------------------|
| ubuntu-ml | ML/Ollama | 192.168.1.11 | 192.168.122.x (auto) |
| win11 | Gaming | 192.168.1.20 | 192.168.122.10 (manual) |

## Access Patterns

**From LAN computers:**
- Use macvtap IPs (192.168.1.11, 192.168.1.20)

**From hypervisor host:**
- Use NAT IPs via port forwarding (192.168.122.x)
- After port forwarding: localhost:2222, localhost:11435, etc.

## Verification

```bash
# Check VMs have both interfaces
virsh -c qemu:///system domiflist ubuntu-ml
virsh -c qemu:///system domiflist win11

# Check NAT DHCP leases
virsh -c qemu:///system net-dhcp-leases default

# Test host can ping NAT gateway
ping 192.168.122.1

# Test host can reach VM on NAT network (after VM configured)
ping 192.168.122.x
```
