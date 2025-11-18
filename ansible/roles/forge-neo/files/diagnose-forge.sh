#!/bin/bash
# Forge Neo Diagnostic Script
# This script helps diagnose common issues with Forge Neo installation

set -e

FORGE_DIR="${HOME}/forge-neo/app"
VENV_PATH="${FORGE_DIR}/venv"

echo "============================================================"
echo "Forge Neo Diagnostic Report"
echo "============================================================"
echo ""

# Check if forge directory exists
echo "1. Checking installation directory..."
if [ -d "$FORGE_DIR" ]; then
    echo "   ✓ Forge directory exists: $FORGE_DIR"
else
    echo "   ✗ Forge directory NOT found: $FORGE_DIR"
    exit 1
fi
echo ""

# Check if venv exists
echo "2. Checking virtual environment..."
if [ -d "$VENV_PATH" ]; then
    echo "   ✓ Virtual environment exists: $VENV_PATH"
else
    echo "   ✗ Virtual environment NOT found: $VENV_PATH"
    exit 1
fi
echo ""

# Check systemd service status
echo "3. Checking forge-neo service status..."
if systemctl is-active --quiet forge-neo; then
    echo "   ✓ Service is running"
    systemctl status forge-neo --no-pager | head -n 15
else
    echo "   ✗ Service is NOT running"
    echo "   Status:"
    systemctl status forge-neo --no-pager | head -n 15 || true
fi
echo ""

# Check recent service logs
echo "4. Recent service logs (last 30 lines)..."
echo "   ─────────────────────────────────────────────────────────"
sudo journalctl -u forge-neo -n 30 --no-pager || echo "   Could not retrieve logs"
echo "   ─────────────────────────────────────────────────────────"
echo ""

# Check for errors in logs
echo "5. Checking for errors in service logs..."
ERROR_COUNT=$(sudo journalctl -u forge-neo --since "10 minutes ago" --no-pager | grep -i "error\|exception\|failed\|traceback" | wc -l)
if [ "$ERROR_COUNT" -gt 0 ]; then
    echo "   ⚠ Found $ERROR_COUNT error(s) in last 10 minutes:"
    echo "   ─────────────────────────────────────────────────────────"
    sudo journalctl -u forge-neo --since "10 minutes ago" --no-pager | grep -i "error\|exception\|failed\|traceback" | tail -n 20
    echo "   ─────────────────────────────────────────────────────────"
else
    echo "   ✓ No errors found in last 10 minutes"
fi
echo ""

# Check crash logs
echo "6. Checking crash and application logs..."
CRASH_LOG="${FORGE_DIR}/crash.log"
WEBUI_LOG="${FORGE_DIR}/webui.log"

if [ -f "$CRASH_LOG" ]; then
    CRASH_SIZE=$(stat -f%z "$CRASH_LOG" 2>/dev/null || stat -c%s "$CRASH_LOG" 2>/dev/null)
    CRASH_LINES=$(wc -l < "$CRASH_LOG")
    echo "   ✓ Crash log found: $CRASH_LOG"
    echo "     Size: $CRASH_SIZE bytes, Lines: $CRASH_LINES"

    # Check for recent crashes
    if grep -q "CRASH DETECTED" "$CRASH_LOG" 2>/dev/null; then
        echo "   ⚠ CRASHES DETECTED in crash.log!"
        echo "   Last crash entry:"
        echo "   ─────────────────────────────────────────────────────────"
        grep -A 20 "CRASH DETECTED" "$CRASH_LOG" | tail -n 25
        echo "   ─────────────────────────────────────────────────────────"
    else
        echo "   ✓ No crashes detected in crash.log"
    fi
else
    echo "   ℹ Crash log not found (service may not have been started yet)"
fi

if [ -f "$WEBUI_LOG" ]; then
    WEBUI_SIZE=$(stat -f%z "$WEBUI_LOG" 2>/dev/null || stat -c%s "$WEBUI_LOG" 2>/dev/null)
    echo "   ✓ WebUI log found: $WEBUI_LOG (Size: $WEBUI_SIZE bytes)"

    # Check for errors in webui log
    ERROR_COUNT=$(grep -i "error\|exception\|traceback\|failed" "$WEBUI_LOG" 2>/dev/null | wc -l)
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo "   ⚠ Found $ERROR_COUNT error line(s) in webui.log"
        echo "   Recent errors:"
        echo "   ─────────────────────────────────────────────────────────"
        grep -i "error\|exception\|traceback" "$WEBUI_LOG" | tail -n 10
        echo "   ─────────────────────────────────────────────────────────"
    else
        echo "   ✓ No errors found in webui.log"
    fi
else
    echo "   ℹ WebUI log not found (service may not have been started yet)"
fi
echo ""

# Check NVIDIA GPU
echo "7. Checking NVIDIA GPU status..."
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=name,driver_version,memory.total,memory.used --format=csv,noheader | while read line; do
        echo "   ✓ GPU: $line"
    done
else
    echo "   ✗ nvidia-smi not found"
fi
echo ""

# Check CUDA
echo "8. Checking CUDA installation..."
if [ -d "/usr/local/cuda-12.8" ]; then
    echo "   ✓ CUDA 12.8 is installed"
    if [ -f "/usr/local/cuda-12.8/bin/nvcc" ]; then
        CUDA_VERSION=$(/usr/local/cuda-12.8/bin/nvcc --version | grep "release" | awk '{print $5}' | cut -d',' -f1)
        echo "   ✓ NVCC version: $CUDA_VERSION"
    fi
else
    echo "   ✗ CUDA 12.8 not found in /usr/local/"
fi
echo ""

# Test PyTorch in venv
echo "9. Testing PyTorch and CUDA in virtual environment..."
cd "$FORGE_DIR"
source venv/bin/activate

echo "   Testing PyTorch import..."
python3 -c "import torch; print(f'   ✓ PyTorch version: {torch.__version__}')" 2>&1

echo "   Testing CUDA availability..."
python3 -c "import torch; print(f'   ✓ CUDA available: {torch.cuda.is_available()}'); print(f'   ✓ CUDA version: {torch.version.cuda}'); print(f'   ✓ GPU count: {torch.cuda.device_count()}')" 2>&1

if [ -f "$FORGE_DIR/test_cuda.py" ]; then
    echo ""
    echo "   Running full CUDA test..."
    python3 test_cuda.py 2>&1 || echo "   ✗ CUDA test failed"
fi

deactivate
echo ""

# Check disk space
echo "10. Checking disk space..."
df -h "$FORGE_DIR" | tail -n 1 | awk '{print "   Filesystem: "$1"\n   Size: "$2"\n   Used: "$3"\n   Available: "$4"\n   Use%: "$5}'
echo ""

# Check port 7860
echo "11. Checking if port 7860 is listening..."
if ss -tln | grep -q ":7860 "; then
    echo "   ✓ Port 7860 is listening"
    ss -tlnp | grep ":7860 " | head -n 1
else
    echo "   ✗ Port 7860 is NOT listening"
fi
echo ""

# Summary
echo "============================================================"
echo "Diagnostic Summary"
echo "============================================================"
echo ""
echo "If you see errors above, try the following:"
echo ""
echo "1. Check crash logs (if backend is crashing):"
echo "   tail -f $FORGE_DIR/crash.log"
echo "   tail -f $FORGE_DIR/webui.log"
echo ""
echo "2. View full service logs:"
echo "   sudo journalctl -u forge-neo -f"
echo ""
echo "3. Restart the service:"
echo "   sudo systemctl daemon-reload"
echo "   sudo systemctl restart forge-neo"
echo ""
echo "4. Test manually (to see errors in real-time):"
echo "   cd $FORGE_DIR"
echo "   source venv/bin/activate"
echo "   python3 launch.py --listen --port 7860"
echo ""
echo "5. Check for specific errors and report them for further help"
echo ""
echo "Important log files:"
echo "- Crash log: $FORGE_DIR/crash.log"
echo "- WebUI log: $FORGE_DIR/webui.log"
echo "- System log: journalctl -u forge-neo"
echo ""
