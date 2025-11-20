#!/bin/bash
# Complete installation script for Forge Neo on Linux
# Optimized for NVIDIA Blackwell GPUs (RTX 5060 Ti)

set -e

REPO_URL="https://github.com/Haoming02/sd-webui-forge-classic"
BRANCH="neo"
INSTALL_DIR="sd-webui-forge-neo"
PYTHON_VERSION="3.11"

echo "====================================="
echo "Forge Neo Installation Script"
echo "====================================="
echo ""

# Check if Python 3.11 is available
if ! command -v python${PYTHON_VERSION} &> /dev/null; then
    echo "Error: Python ${PYTHON_VERSION} not found!"
    echo "Please install Python ${PYTHON_VERSION} first."
    exit 1
fi

# Clone repository
if [ ! -d "${INSTALL_DIR}" ]; then
    echo "Cloning Forge Neo repository..."
    git clone ${REPO_URL} ${INSTALL_DIR} --branch ${BRANCH}
else
    echo "Directory ${INSTALL_DIR} already exists. Skipping clone."
fi

cd ${INSTALL_DIR}

# Create virtual environment
if [ ! -d "venv" ]; then
    echo "Creating Python ${PYTHON_VERSION} virtual environment..."
    python${PYTHON_VERSION} -m venv venv
else
    echo "Virtual environment already exists. Skipping creation."
fi

# Activate venv
source venv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Install PyTorch with CUDA 12.8
echo "Installing PyTorch 2.9.1 with CUDA 12.8..."
pip install -r ../forge_neo_requirements_torch_cuda128.txt

# Install base requirements
echo "Installing base requirements..."
pip install -r ../forge_neo_requirements_base.txt

# Install Linux acceleration packages
echo "Installing acceleration packages..."
pip install -r ../forge_neo_requirements_acceleration_linux.txt

# Install wheel-based packages
echo "Installing wheel-based packages..."
bash ../install_wheels_linux.sh

# Test CUDA
echo ""
echo "Testing CUDA availability..."
python -c "import torch; print(f'CUDA Available: {torch.cuda.is_available()}'); print(f'CUDA Version: {torch.version.cuda}'); print(f'PyTorch Version: {torch.__version__}')"

# Test SageAttention
echo ""
echo "Testing SageAttention..."
python -c "from sageattention import sageattn; import importlib.metadata; print(f'SageAttention Version: {importlib.metadata.version(\"sageattention\")}')"

# Create webui-user.sh
if [ ! -f "webui-user.sh" ]; then
    echo ""
    echo "Creating webui-user.sh..."
    cat > webui-user.sh << 'EOF'
#!/bin/bash

# Python executable
export PYTHON_CMD="python"

# Command line arguments
export COMMANDLINE_ARGS="--sage --disable-flash --cuda-malloc --listen --port 7860"

# Optional: Skip installation if already done
export COMMANDLINE_ARGS="${COMMANDLINE_ARGS} --skip-install"

# Launch
python webui.py ${COMMANDLINE_ARGS}
EOF
    chmod +x webui-user.sh
    echo "Created webui-user.sh"
fi

echo ""
echo "====================================="
echo "Installation Complete!"
echo "====================================="
echo ""
echo "To start the webui:"
echo "  cd ${INSTALL_DIR}"
echo "  source venv/bin/activate"
echo "  ./webui-user.sh"
echo ""
echo "Or run directly:"
echo "  python webui.py --sage --disable-flash --listen"
echo ""
