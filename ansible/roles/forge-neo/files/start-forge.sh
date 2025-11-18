#!/bin/bash
# Forge Neo startup wrapper with enhanced crash logging
# This script wraps the Forge Neo launch to capture crashes that happen too fast for journald

set -e

FORGE_DIR="${HOME}/forge-neo/app"
LOG_FILE="${FORGE_DIR}/crash.log"
WEBUI_LOG="${FORGE_DIR}/webui.log"

# Ensure we're in the right directory
cd "${FORGE_DIR}"

# Function to log with timestamp
log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

# Function to handle crashes
handle_crash() {
    local exit_code=$?
    log_msg "========================================="
    log_msg "CRASH DETECTED! Exit code: ${exit_code}"
    log_msg "========================================="

    # Dump recent Python traceback if available
    if [ -f "${WEBUI_LOG}" ]; then
        log_msg "Last 50 lines of webui.log:"
        tail -n 50 "${WEBUI_LOG}" >> "${LOG_FILE}" 2>&1
    fi

    # Dump GPU status
    log_msg ""
    log_msg "GPU Status at crash time:"
    nvidia-smi >> "${LOG_FILE}" 2>&1 || log_msg "nvidia-smi failed"

    # Dump Python process info if still running
    log_msg ""
    log_msg "Python processes:"
    ps aux | grep python3 >> "${LOG_FILE}" 2>&1 || true

    log_msg "========================================="

    # Force flush logs
    sync

    exit ${exit_code}
}

# Set up crash handler
trap handle_crash ERR EXIT

log_msg "========================================="
log_msg "Starting Forge Neo"
log_msg "========================================="
log_msg "Working directory: $(pwd)"
log_msg "Virtual environment: ${VIRTUAL_ENV:-NOT SET}"
log_msg "Python: $(which python3)"
log_msg "Python version: $(python3 --version)"

# Verify PyTorch before starting
log_msg ""
log_msg "Verifying PyTorch..."
if ! python3 -c "import torch; print(f'PyTorch: {torch.__version__}, CUDA: {torch.cuda.is_available()}')"; then
    log_msg "ERROR: PyTorch verification failed!"
    log_msg "This should not happen - venv may not be activated properly"
    exit 1
fi

log_msg ""
log_msg "Starting launch.py..."
log_msg "Logs will be written to: ${WEBUI_LOG}"
log_msg "Crash logs will be written to: ${LOG_FILE}"
log_msg "========================================="
log_msg ""

# Run the actual Forge Neo server with output to both file and journal
# Use 'exec' to replace this script's process with python, but first set up logging
exec python3 launch.py --listen --port 7860 --enable-insecure-extension-access 2>&1 | tee -a "${WEBUI_LOG}"
