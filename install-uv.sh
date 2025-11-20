#!/bin/bash
set -euo pipefail

# Script to install Astral UV with default options and re-source environment
# UV is a fast Python package installer and resolver written in Rust

echo "=========================================="
echo "Installing Astral UV"
echo "=========================================="
echo ""

# Check if uv is already installed
if command -v uv &> /dev/null; then
    echo "UV is already installed at: $(command -v uv)"
    uv --version
    echo ""
    echo "To update UV, run: uv self update"
    echo ""
    read -p "Do you want to reinstall anyway? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
fi

echo "Downloading and installing UV..."
echo ""

# Download and run the official installation script
curl -LsSf https://astral.sh/uv/install.sh | sh

echo ""
echo "=========================================="
echo "Installation complete!"
echo "=========================================="
echo ""

# Determine the UV installation directory
UV_BIN_DIR="${CARGO_HOME:-$HOME/.cargo}/bin"

# Re-source environment files to make uv available in current shell
echo "Re-sourcing environment..."

# Source common shell configuration files if they exist
if [ -f "$HOME/.bashrc" ]; then
    echo "Sourcing ~/.bashrc"
    source "$HOME/.bashrc"
fi

if [ -f "$HOME/.profile" ]; then
    echo "Sourcing ~/.profile"
    source "$HOME/.profile"
fi

if [ -f "$HOME/.bash_profile" ]; then
    echo "Sourcing ~/.bash_profile"
    source "$HOME/.bash_profile"
fi

# Also export UV to current PATH explicitly
if [ -d "$UV_BIN_DIR" ]; then
    export PATH="$UV_BIN_DIR:$PATH"
fi

echo ""
echo "=========================================="
echo "Verification"
echo "=========================================="

# Verify installation
if command -v uv &> /dev/null; then
    echo "✓ UV successfully installed!"
    echo "  Location: $(command -v uv)"
    echo "  Version: $(uv --version)"
    echo ""
    echo "UV is now available in your PATH."
    echo ""
    echo "Quick start:"
    echo "  - Create a new project: uv init my-project"
    echo "  - Install a package: uv pip install <package>"
    echo "  - Run a script: uv run script.py"
    echo "  - For more info: uv --help"
else
    echo "✗ Installation may have completed, but 'uv' is not in PATH."
    echo "  Try closing and reopening your terminal, or run:"
    echo "  export PATH=\"$UV_BIN_DIR:\$PATH\""
    exit 1
fi

echo ""
echo "=========================================="
echo "Done!"
echo "=========================================="
