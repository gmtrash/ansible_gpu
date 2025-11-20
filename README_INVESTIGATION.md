# Forge Neo Investigation - Files Overview

## Investigation Complete!

This investigation analyzed both Forge Neo repositories to extract complete dependency information for deploying on NVIDIA RTX 5060 Ti (Blackwell architecture).

---

## Files Created (10 files)

### 📋 Documentation (3 files)

1. **FORGE_NEO_INVESTIGATION_SUMMARY.md** (7.7K)
   - Executive summary with key findings
   - Quick start guide
   - Troubleshooting tips
   - **START HERE** for overview

2. **FORGE_NEO_ANALYSIS.md** (29K)
   - Complete detailed analysis report
   - All dependencies with versions
   - Comprehensive technical details
   - webui.sh behavior analysis
   - FlashAttention vs SageAttention comparison
   - Repository comparison
   - Installation strategies

3. **FORGE_NEO_QUICKSTART.md** (4.9K)
   - Quick start installation guide
   - Testing procedures
   - Troubleshooting section
   - Command reference

### 📦 Requirements Files (3 files)

4. **forge_neo_requirements_torch_cuda128.txt** (231 bytes)
   - PyTorch 2.9.1 + CUDA 12.8
   - TorchVision 0.24.1
   - xformers 0.0.33.post1

5. **forge_neo_requirements_base.txt** (1.1K)
   - 60+ core packages
   - Platform-independent
   - All pinned versions

6. **forge_neo_requirements_acceleration_linux.txt** (333 bytes)
   - SageAttention 2.2.0
   - Triton 3.5.1
   - Linux-specific acceleration

### 🔧 Installation Scripts (3 files)

7. **install_forge_neo.sh** (3.0K) ⭐ **MAIN INSTALLER**
   - Complete automated installation
   - Clones repository
   - Sets up Python 3.11 venv
   - Installs all dependencies
   - Tests CUDA and SageAttention
   - Creates configuration files

8. **install_wheels_linux.sh** (924 bytes)
   - Installs FlashAttention wheel
   - Installs Nunchaku wheel
   - Linux-specific packages

9. **install_wheels_windows.bat** (1.3K)
   - Windows version of wheel installer
   - FlashAttention, SageAttention, Triton, Nunchaku
   - For Windows users

### ⚙️ Configuration (1 file)

10. **webui-user.sh** (1.3K)
    - Optimized for Blackwell GPUs
    - Recommended command-line arguments
    - Easy customization

---

## Quick Start (3 Commands)

```bash
# 1. Run automated installation
bash install_forge_neo.sh

# 2. Navigate and activate
cd sd-webui-forge-neo
source venv/bin/activate

# 3. Launch webui
./webui-user.sh
```

Open browser: http://localhost:7860

---

## Key Findings Summary

### ✅ Recommended Repository
**Use:** https://github.com/Haoming02/sd-webui-forge-classic (branch: neo)
**Avoid:** https://github.com/6Morpheus6/forge-neo (just a Pinokio wrapper with outdated packages)

### ✅ Best Configuration for RTX 5060 Ti
```bash
python webui.py --sage --disable-flash --cuda-malloc --listen
```

### ✅ Required Versions
- Python: 3.11.9
- PyTorch: 2.9.1+cu128
- CUDA: 12.8
- SageAttention: 2.2.0
- Triton: 3.5.1

### ✅ FlashAttention vs SageAttention
- **Both are supported** in the same codebase
- **SageAttention has priority** if both installed
- **SageAttention recommended** for Blackwell GPUs
- **Swap easily** with command-line flags: `--sage` or `--flash`

### ⚠️ Important Notes
1. SageAttention 2 may need **manual installation** for RTX 50 series
2. Both positive and negative prompts **required** with SageAttention 2
3. The 6Morpheus6 repo is **NOT** a fork - it's an installer script
4. webui.sh **doesn't exist** in upstream - Windows-focused repo

---

## Installation Paths

After running `install_forge_neo.sh`, you'll have:

```
/home/user/ansible_gpu/
├── sd-webui-forge-neo/          # Cloned repository
│   ├── venv/                    # Python virtual environment
│   ├── webui-user.sh           # Launch configuration
│   ├── webui.py                # Main entry point
│   ├── launch.py               # Package installer
│   ├── backend/                # Core backend
│   ├── modules/                # Core modules
│   ├── modules_forge/          # Forge-specific modules
│   ├── models/                 # Model storage
│   └── outputs/                # Generated images
│
├── Documentation/
│   ├── FORGE_NEO_INVESTIGATION_SUMMARY.md
│   ├── FORGE_NEO_ANALYSIS.md
│   └── FORGE_NEO_QUICKSTART.md
│
├── Requirements/
│   ├── forge_neo_requirements_torch_cuda128.txt
│   ├── forge_neo_requirements_base.txt
│   └── forge_neo_requirements_acceleration_linux.txt
│
└── Installation Scripts/
    ├── install_forge_neo.sh
    ├── install_wheels_linux.sh
    └── webui-user.sh
```

---

## Complete Dependency List (70+ packages)

### PyTorch Stack
- torch==2.9.1+cu128
- torchvision==0.24.1+cu128
- xformers==0.0.33.post1

### Acceleration
- sageattention==2.2.0
- flash_attn==2.8.3
- triton==3.5.1
- nunchaku==1.0.2

### Core ML/AI
- transformers==4.56.2
- diffusers==0.35.1
- accelerate==1.10.1
- safetensors==0.6.2
- peft==0.17.1
- lightning==2.5.1

### Web Interface
- gradio==4.40.0
- gradio_imageslider==0.0.20
- gradio_rangeslider==0.0.6
- fastapi==0.112.4

### Computer Vision
- opencv-python==4.8.1.78
- Pillow==11.3.0
- pillow-heif==0.22.0
- kornia==0.6.7
- scikit-image==0.25.2

### Utilities
- numpy==1.26.4
- tqdm==4.67.1
- psutil==5.9.8
- bitsandbytes==0.48.2
- And 40+ more...

See `forge_neo_requirements_base.txt` for complete list.

---

## Troubleshooting

### SageAttention Won't Install
```bash
# Manual build from source
pip install triton==3.5.1
git clone https://github.com/thu-ml/SageAttention.git
cd SageAttention
pip install -e .
```

### CUDA Not Available
```bash
# Check NVIDIA drivers
nvidia-smi

# Verify PyTorch CUDA
python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')"
```

### Out of Memory
```bash
# Use low VRAM mode
python webui.py --sage --always-low-vram
```

---

## Testing Installation

```bash
cd sd-webui-forge-neo
source venv/bin/activate

# Test CUDA
python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}'); print(f'GPU: {torch.cuda.get_device_name(0)}')"

# Test SageAttention
python -c "from sageattention import sageattn; print('SageAttention OK')"

# Test FlashAttention (if installed)
python -c "from flash_attn import flash_attn_func; print('FlashAttention OK')"

# Test Gradio
python -c "import gradio; print(f'Gradio version: {gradio.__version__}')"
```

---

## Next Steps

1. ✅ Read **FORGE_NEO_INVESTIGATION_SUMMARY.md** for overview
2. ✅ Run **install_forge_neo.sh** for installation
3. ✅ Review **FORGE_NEO_QUICKSTART.md** for usage
4. ✅ Consult **FORGE_NEO_ANALYSIS.md** for technical details
5. ✅ Download models to `sd-webui-forge-neo/models/Stable-diffusion/`
6. ✅ Launch and test with sample generation
7. ✅ Monitor GPU memory usage and adjust flags

---

## Repository Information

### Analyzed Repositories
1. **Upstream (Primary):** https://github.com/Haoming02/sd-webui-forge-classic (branch: neo)
   - Actual WebUI implementation
   - Latest packages (PyTorch 2.9.1, SageAttention 2.2.0)
   - Windows-focused but works on Linux
   - Active development

2. **Pinokio Wrapper:** https://github.com/6Morpheus6/forge-neo (main branch)
   - Automation script only
   - Installs upstream repository
   - Outdated packages (PyTorch 2.7.0, SageAttention 2.1.1)
   - Not recommended for direct use

### Recommendation
**Use the upstream repository directly** for best Blackwell GPU support.

---

## Support and Resources

- **GitHub Issues:** https://github.com/Haoming02/sd-webui-forge-classic/issues
- **SageAttention:** https://github.com/thu-ml/SageAttention
- **FlashAttention:** https://github.com/Dao-AILab/flash-attention
- **PyTorch:** https://pytorch.org/
- **CUDA Toolkit:** https://developer.nvidia.com/cuda-toolkit

---

**Investigation Date:** 2025-11-20
**Target GPU:** NVIDIA RTX 5060 Ti (Blackwell)
**Status:** ✅ Complete - Ready for deployment

---

## File Size Summary

```
Total: 10 files, ~50KB
├── Documentation:  3 files (~42KB)
├── Requirements:   3 files (~2KB)
├── Scripts:        3 files (~5KB)
└── Configuration:  1 file  (~1KB)
```

All files are located in: `/home/user/ansible_gpu/`
