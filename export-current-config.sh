#!/bin/bash
# Export current system configuration to Ansible variables
# This helps capture your current setup for future redeployment

echo "=========================================="
echo "Export Current Configuration to Ansible"
echo "=========================================="
echo ""

CONFIG_FILE="group_vars/localhost.yml.exported"

cat > "$CONFIG_FILE" << EOF
---
# Exported configuration from current system
# Generated on: $(date)
# Hostname: $(hostname)

# ============================================
# User Configuration
# ============================================
username: $USER
home_dir: "$HOME"
user_group: $(id -gn)

# ============================================
# NVIDIA/CUDA Configuration
# ============================================
EOF

# Detect NVIDIA driver and CUDA version
if command -v nvidia-smi &> /dev/null; then
    NVIDIA_DRIVER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1)
    echo "nvidia_driver_version: ${NVIDIA_DRIVER%%.*}  # Detected: $NVIDIA_DRIVER" >> "$CONFIG_FILE"

    # Detect GPU compute capability
    COMPUTE_CAP=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader 2>/dev/null | head -1)
    if [ -n "$COMPUTE_CAP" ]; then
        echo "cuda_compute_capability: \"$COMPUTE_CAP\"" >> "$CONFIG_FILE"
    fi

    # Detect GPU name
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
    echo "# GPU: $GPU_NAME" >> "$CONFIG_FILE"
else
    echo "# NVIDIA driver not detected" >> "$CONFIG_FILE"
    echo "nvidia_driver_version: 550  # Default" >> "$CONFIG_FILE"
fi

# Detect CUDA toolkit version
if command -v nvcc &> /dev/null; then
    CUDA_VERSION=$(nvcc --version 2>/dev/null | grep "release" | awk '{print $5}' | cut -d, -f1)
    echo "cuda_version: \"$CUDA_VERSION\"  # Detected" >> "$CONFIG_FILE"
else
    echo "cuda_version: \"12.6\"  # Not detected, using default" >> "$CONFIG_FILE"
fi

cat >> "$CONFIG_FILE" << EOF

# ============================================
# Conda Configuration
# ============================================
EOF

# Detect conda
if command -v conda &> /dev/null; then
    CONDA_BASE=$(conda info --base)
    if [[ "$CONDA_BASE" == *"miniforge"* ]]; then
        echo "conda_installer: \"miniforge\"" >> "$CONFIG_FILE"
    else
        echo "conda_installer: \"miniconda\"" >> "$CONFIG_FILE"
    fi
    echo "conda_install_dir: \"$CONDA_BASE\"" >> "$CONFIG_FILE"
else
    echo "# Conda not detected" >> "$CONFIG_FILE"
    echo "conda_installer: \"miniforge\"" >> "$CONFIG_FILE"
    echo "conda_install_dir: \"{{ home_dir }}/miniforge3\"" >> "$CONFIG_FILE"
fi

cat >> "$CONFIG_FILE" << EOF

# ============================================
# SD Forge CUDA Configuration
# ============================================
forge_install_dir: "$HOME/llm/sd-webui-forge"
forge_conda_env: "forge-cuda"
forge_models_dir: "{{ forge_install_dir }}/models"

# ============================================
# Desktop Preferences
# ============================================
EOF

# Git config
GIT_NAME=$(git config --global user.name 2>/dev/null || echo "Your Name")
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "your.email@example.com")

echo "git_user_name: \"$GIT_NAME\"" >> "$CONFIG_FILE"
echo "git_user_email: \"$GIT_EMAIL\"" >> "$CONFIG_FILE"

echo ""
echo "Configuration exported to: $CONFIG_FILE"
echo ""
echo "Review the file and copy relevant settings to group_vars/localhost.yml"
echo ""
echo "Detected configuration:"
echo "  User: $USER"
echo "  Home: $HOME"
if command -v nvidia-smi &> /dev/null; then
    echo "  NVIDIA Driver: ${NVIDIA_DRIVER:-detected}"
    echo "  GPU: ${GPU_NAME:-unknown}"
    echo "  Compute Capability: ${COMPUTE_CAP:-unknown}"
fi
if command -v nvcc &> /dev/null; then
    echo "  CUDA: ${CUDA_VERSION:-detected}"
fi
if command -v conda &> /dev/null; then
    echo "  Conda: $(conda --version)"
fi
echo ""
