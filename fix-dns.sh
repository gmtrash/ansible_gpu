#!/bin/bash
set -e
echo "Adding iptables rules to fix DNS resolution..."
sudo iptables -t nat -I POSTROUTING 1 -s 192.168.1.0/24 -d 192.168.1.1 -p udp --dport 53 -j RETURN
sudo iptables -t nat -I POSTROUTING 2 -s 192.168.1.0/24 -d 192.168.1.1 -p tcp --dport 53 -j RETURN
echo "Saving iptables rules..."
sudo netfilter-persistent save
echo "DNS resolution fixed."
