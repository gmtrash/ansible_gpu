#!/bin/bash
# Fix the systemd service to use the wrapper script

echo "Fixing systemd service configuration..."

# Stop and disable the broken service
sudo systemctl stop vm-port-forward.service 2>/dev/null || true
sudo systemctl disable vm-port-forward.service 2>/dev/null || true

# Copy wrapper script to system location
sudo cp "/home/aubreybailey/llm/gpu passthrough/vm-port-forward-start.sh" /usr/local/bin/vm-port-forward-start.sh
sudo chmod +x /usr/local/bin/vm-port-forward-start.sh

# Create corrected systemd service
sudo tee /etc/systemd/system/vm-port-forward.service > /dev/null <<'EOF'
[Unit]
Description=Port forwarding to VMs using socat
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/vm-port-forward-start.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "✓ Service file fixed"

# Reload, enable, and start
sudo systemctl daemon-reload
sudo systemctl enable vm-port-forward.service
sudo systemctl start vm-port-forward.service

echo ""
echo "Checking service status..."
sleep 2
if sudo systemctl is-active --quiet vm-port-forward.service; then
    echo "✓ Port forwarding service is running!"
    echo ""
    sudo systemctl status vm-port-forward.service --no-pager -l
else
    echo "⚠ Service failed to start. Details:"
    sudo systemctl status vm-port-forward.service --no-pager -l
    exit 1
fi

echo ""
echo "Testing port forwarding..."
if timeout 3 bash -c 'cat < /dev/null > /dev/tcp/localhost/2222' 2>/dev/null; then
    echo "✓ Port 2222 is listening (SSH forward working)"
else
    echo "⚠ Port 2222 not responding yet (VM may not be running)"
fi

echo ""
echo "=========================================="
echo "Port Forwarding Active!"
echo "=========================================="
echo ""
echo "Try: ssh -p 2222 localhost"
echo "Try: curl http://localhost:11435/api/tags"
echo "Try: curl http://localhost:8004"
echo ""
