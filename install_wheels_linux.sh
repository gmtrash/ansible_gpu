#!/bin/bash
# Forge Neo - Install wheel-based acceleration packages for Linux
# Run after installing base requirements

set -e

echo "Installing wheel-based acceleration packages for Linux..."

# Flash Attention 2.8.3
echo "Installing Flash Attention 2.8.3..."
pip install https://github.com/Dao-AILab/flash-attention/releases/download/v2.8.3/flash_attn-2.8.3+cu12torch2.9.0cxx11abiFALSE-cp310-cp310-linux_x86_64.whl

# Nunchaku 1.0.2
echo "Installing Nunchaku 1.0.2..."
pip install https://github.com/chengzeyi/nunchaku/releases/download/v1.0.2/nunchaku-1.0.2+torch2.9-cp310-cp310-linux_x86_64.whl

echo "Done! All wheel-based packages installed."
echo ""
echo "To verify installation:"
echo "  python -c 'from flash_attn import flash_attn_func; print(\"FlashAttention OK\")'"
echo "  python -c 'from sageattention import sageattn; print(\"SageAttention OK\")'"
echo "  python -c 'import nunchaku; print(\"Nunchaku OK\")'"
