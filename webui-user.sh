#!/bin/bash
# Forge Neo - User Configuration Script
# Optimized for NVIDIA Blackwell GPUs (RTX 5060 Ti)

# Python executable
export PYTHON_CMD="python"

# Venv directory
export VENV_DIR="venv"

# Command line arguments for optimal Blackwell performance
export COMMANDLINE_ARGS="--sage --disable-flash --cuda-malloc --listen --port 7860"

# Optional: Skip installation if packages already installed
# Uncomment the line below after first successful run
# export COMMANDLINE_ARGS="${COMMANDLINE_ARGS} --skip-install"

# Optional: Additional performance flags (test before using in production)
# export COMMANDLINE_ARGS="${COMMANDLINE_ARGS} --cuda-stream"
# export COMMANDLINE_ARGS="${COMMANDLINE_ARGS} --pin-shared-memory"

# Optional: SageAttention 2 configuration
# export COMMANDLINE_ARGS="${COMMANDLINE_ARGS} --sage2-function fp16_cuda"
# export COMMANDLINE_ARGS="${COMMANDLINE_ARGS} --sage-quantization-backend cuda"

# Optional: Memory management (uncomment one if needed)
# export COMMANDLINE_ARGS="${COMMANDLINE_ARGS} --always-high-vram"
# export COMMANDLINE_ARGS="${COMMANDLINE_ARGS} --always-low-vram"

# Optional: Precision settings
# export COMMANDLINE_ARGS="${COMMANDLINE_ARGS} --fast-fp16"

# Launch webui
python webui.py ${COMMANDLINE_ARGS}
