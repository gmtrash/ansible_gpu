# Forge Neo Quick Start Guide

## Installation (Linux)

### Option 1: Automated Installation (Recommended)

```bash
# Run the complete installation script
bash install_forge_neo.sh
```

### Option 2: Manual Installation

```bash
# 1. Clone repository
git clone https://github.com/Haoming02/sd-webui-forge-classic sd-webui-forge-neo --branch neo
cd sd-webui-forge-neo

# 2. Create Python 3.11 virtual environment
python3.11 -m venv venv
source venv/bin/activate

# 3. Upgrade pip
pip install --upgrade pip

# 4. Install PyTorch with CUDA 12.8
pip install -r ../forge_neo_requirements_torch_cuda128.txt

# 5. Install base requirements
pip install -r ../forge_neo_requirements_base.txt

# 6. Install Linux acceleration packages
pip install -r ../forge_neo_requirements_acceleration_linux.txt

# 7. Install wheel-based packages
bash ../install_wheels_linux.sh

# 8. Copy user configuration
cp ../webui-user.sh .

# 9. Make it executable
chmod +x webui-user.sh
```

## Running the WebUI

### Simple Launch
```bash
cd sd-webui-forge-neo
source venv/bin/activate
python webui.py --sage --disable-flash --listen
```

### Using Configuration Script
```bash
cd sd-webui-forge-neo
source venv/bin/activate
./webui-user.sh
```

### First Run
The first run will install any remaining dependencies automatically. This may take several minutes.

## Recommended Settings for RTX 5060 Ti (Blackwell)

```bash
python webui.py --sage --disable-flash --cuda-malloc --listen --port 7860
```

**Flags explained:**
- `--sage`: Use SageAttention 2 (optimized for Blackwell)
- `--disable-flash`: Avoid FlashAttention (compatibility)
- `--cuda-malloc`: CUDA memory optimization
- `--listen`: Allow network access
- `--port 7860`: Default port

## Testing Installation

```bash
# Test CUDA
python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}'); print(f'GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"N/A\"}')"

# Test SageAttention
python -c "from sageattention import sageattn; print('SageAttention OK')"

# Test FlashAttention (if installed)
python -c "from flash_attn import flash_attn_func; print('FlashAttention OK')"
```

## Troubleshooting

### SageAttention Not Working
If SageAttention fails to install from wheel, build from source:
```bash
pip install triton==3.5.1
git clone https://github.com/thu-ml/SageAttention.git
cd SageAttention
pip install -e .
cd ..
```

### CUDA Not Available
Check NVIDIA drivers:
```bash
nvidia-smi
```

Verify CUDA version matches PyTorch:
```bash
python -c "import torch; print(f'PyTorch CUDA: {torch.version.cuda}')"
nvcc --version  # Should show CUDA 12.x
```

### Out of Memory Errors
Try low VRAM mode:
```bash
python webui.py --sage --always-low-vram
```

### Port Already in Use
Change port:
```bash
python webui.py --sage --port 7861
```

## Accessing the WebUI

After starting, open in browser:
- Local: http://localhost:7860
- Network: http://YOUR_IP:7860

## Updating

```bash
cd sd-webui-forge-neo
git pull
source venv/bin/activate
pip install -r requirements.txt --upgrade
```

## Command-Line Arguments Reference

**Attention:**
- `--sage`: Install/use SageAttention
- `--flash`: Install/use FlashAttention
- `--disable-sage`: Disable SageAttention
- `--disable-flash`: Disable FlashAttention
- `--xformers`: Install/use xformers

**Memory:**
- `--always-low-vram`: Low VRAM mode
- `--always-high-vram`: High VRAM mode
- `--cuda-malloc`: CUDA malloc optimization

**Server:**
- `--listen`: Listen on all interfaces
- `--port PORT`: Change port (default: 7860)
- `--share`: Create Gradio share link

**Performance:**
- `--fast-fp16`: FP16 accumulation
- `--cuda-stream`: CUDA stream (experimental)
- `--pin-shared-memory`: Pin memory (experimental)

**Installation:**
- `--skip-install`: Skip package installation
- `--skip-prepare-environment`: Skip environment setup
- `--reinstall-torch`: Force PyTorch reinstall

For complete list: `python webui.py --help`

## Files Created

After running the installation, you'll have:

```
sd-webui-forge-neo/
├── venv/                          # Virtual environment
├── webui-user.sh                  # User configuration
├── webui.py                       # Main launcher
├── launch.py                      # Environment setup
├── requirements.txt               # Base requirements
├── backend/                       # Core backend
├── modules/                       # Core modules
├── modules_forge/                 # Forge-specific modules
├── models/                        # Model storage
├── outputs/                       # Generated images
└── ...
```

## Next Steps

1. Download models to `models/Stable-diffusion/`
2. Install extensions in `extensions/`
3. Configure settings in the WebUI
4. Start generating!

## Support

- GitHub Issues: https://github.com/Haoming02/sd-webui-forge-classic/issues
- Documentation: https://github.com/Haoming02/sd-webui-forge-classic/tree/neo
