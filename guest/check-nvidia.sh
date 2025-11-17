#!/bin/bash
# Check NVIDIA installation status
# Run this inside the VM

echo "=== NVIDIA Driver Status ==="
if command -v nvidia-smi &> /dev/null; then
    echo "✓ nvidia-smi found"
    nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv
else
    echo "✗ nvidia-smi not found"
fi

echo ""
echo "=== NVIDIA Kernel Modules ==="
lsmod | grep -i nvidia || echo "No NVIDIA modules loaded"

echo ""
echo "=== NVIDIA Packages Installed ==="
dpkg -l | grep -i nvidia-driver || echo "No nvidia-driver packages found"

echo ""
echo "=== GPU Devices ==="
lspci | grep -i nvidia || echo "No NVIDIA devices found"

echo ""
echo "=== CUDA Status ==="
if [ -d "/usr/local/cuda" ]; then
    echo "✓ CUDA directory exists"
    ls -la /usr/local/cuda*/bin/nvcc 2>/dev/null || echo "nvcc not found"
else
    echo "✗ CUDA not installed"
fi

echo ""
echo "=== Forge Neo Service ==="
if systemctl is-active --quiet forge-neo; then
    echo "✓ forge-neo service is running"
    curl -s http://localhost:7860 > /dev/null && echo "✓ Web UI responding on port 7860" || echo "✗ Web UI not responding"
else
    echo "✗ forge-neo service not running"
    systemctl status forge-neo --no-pager -l || true
fi
