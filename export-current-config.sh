#!/bin/bash
# Export current system configuration to Ansible variables
# This helps capture your current setup for future redeployment

echo "=========================================="
echo "Export Current Configuration to Ansible"
echo "=========================================="
echo ""

CONFIG_FILE="group_vars/localhost.yml.exported"

cat > "$CONFIG_FILE" << 'EOF'
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
# ROCm Configuration
# ============================================
EOF

# Detect ROCm version
if command -v rocm-smi &> /dev/null; then
    ROCM_VERSION=$(rocm-smi --version 2>/dev/null | grep "ROCm version" | awk '{print $3}' | cut -d. -f1,2)
    echo "rocm_version: \"${ROCM_VERSION:-6.2}\"" >> "$CONFIG_FILE"

    # Detect GPU architecture
    GPU_ARCH=$(rocminfo 2>/dev/null | grep "Name:" | grep "gfx" | head -1 | awk '{print $2}')
    if [ -n "$GPU_ARCH" ]; then
        echo "gpu_architecture: \"$GPU_ARCH\"" >> "$CONFIG_FILE"
    fi
else
    echo "rocm_version: \"6.2\"  # Not detected, using default" >> "$CONFIG_FILE"
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
# SD Forge ROCm Configuration
# ============================================
forge_install_dir: "$HOME/llm/sd-webui-forge-classic"
forge_conda_env: "forge-rocm"
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
if command -v rocm-smi &> /dev/null; then
    echo "  ROCm: ${ROCM_VERSION:-detected}"
    echo "  GPU: ${GPU_ARCH:-unknown}"
fi
if command -v conda &> /dev/null; then
    echo "  Conda: $(conda --version)"
fi
echo ""
