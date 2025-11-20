# Forge Neo Investigation - Executive Summary

**Investigation Date:** 2025-11-20
**Target GPU:** NVIDIA RTX 5060 Ti (Blackwell Architecture)

---

## Critical Findings

### 1. Repository Clarification

**IMPORTANT:** The 6Morpheus6/forge-neo repository is **NOT** a modified version of the webui - it's a **Pinokio automation script** that installs the Haoming02/sd-webui-forge-classic repository.

**Use This:** https://github.com/Haoming02/sd-webui-forge-classic (branch: neo)
**Not This:** https://github.com/6Morpheus6/forge-neo (just an installer wrapper)

### 2. RTX 5060 Ti (Blackwell) Requirements

For your RTX 5060 Ti, the repository documentation explicitly states:

> "Users with RTX 50 GPUs may require manual installation of SageAttention 2 rather than relying on automatic installation via the --sage flag."

**Required Configuration:**
- PyTorch: 2.9.1+cu128
- CUDA: 12.8
- SageAttention: 2.2.0 (may need manual installation)
- Python: 3.11.9

### 3. FlashAttention vs SageAttention

**Good News:** The codebase ALREADY supports swapping between FlashAttention and SageAttention!

**Attention Selection Priority (automatic):**
1. SageAttention (highest priority) - quantization-based, slightly lower quality
2. FlashAttention - high quality, strict requirements
3. xformers - good compatibility
4. PyTorch native - default fallback
5. Basic - low memory fallback

**To Use SageAttention (Recommended for Blackwell):**
```bash
python webui.py --sage --disable-flash
```

**To Use FlashAttention:**
```bash
python webui.py --flash --disable-sage
```

**Both Can Coexist:** If both are installed, SageAttention takes priority automatically.

---

## Complete Dependency List

### Core Requirements (60+ packages)
See: `/home/user/ansible_gpu/forge_neo_requirements_base.txt`

Key packages:
- transformers==4.56.2
- diffusers==0.35.1
- accelerate==1.10.1
- gradio==4.40.0
- safetensors==0.6.2
- And 50+ more...

### PyTorch Stack
See: `/home/user/ansible_gpu/forge_neo_requirements_torch_cuda128.txt`

- torch==2.9.1+cu128
- torchvision==0.24.1+cu128
- xformers==0.0.33.post1

### Acceleration Packages
See: `/home/user/ansible_gpu/forge_neo_requirements_acceleration_linux.txt`

- sageattention==2.2.0
- triton==3.5.1
- flash_attn==2.8.3 (via wheel)
- nunchaku==1.0.2 (via wheel)

---

## webui.sh Analysis

**Finding:** The upstream Haoming02 repository **does NOT include webui.sh** - it's Windows-focused with only webui.bat.

The 6Morpheus6 Pinokio repo includes a webui.sh, but it just:
1. Clones the upstream repository
2. Sets up Python venv
3. Runs launch.py

**Can We Bypass It?** **YES!**

Instead of using webui.sh, you can:
1. Set up Python venv manually
2. Install dependencies directly from requirements files
3. Run `python webui.py` with desired flags

This gives you complete control and avoids the automatic package installation logic.

---

## Installation Strategy

### Option 1: Automated (Easiest)

```bash
cd /home/user/ansible_gpu
bash install_forge_neo.sh
```

This script:
- Clones the repository
- Creates Python 3.11 venv
- Installs all dependencies in correct order
- Tests CUDA and SageAttention
- Creates webui-user.sh config file

### Option 2: Manual (More Control)

Use the individual requirements files:
1. `forge_neo_requirements_torch_cuda128.txt` - PyTorch + CUDA
2. `forge_neo_requirements_base.txt` - Core packages
3. `forge_neo_requirements_acceleration_linux.txt` - Acceleration
4. `install_wheels_linux.sh` - Wheel-based packages

See FORGE_NEO_QUICKSTART.md for detailed steps.

---

## Recommended Configuration for RTX 5060 Ti

### Launch Command
```bash
python webui.py --sage --disable-flash --cuda-malloc --listen --port 7860
```

### Rationale
- `--sage`: Use SageAttention 2 (optimized for newer GPUs)
- `--disable-flash`: Avoid FlashAttention compatibility issues
- `--cuda-malloc`: CUDA memory optimization
- `--listen`: Allow network access
- `--port 7860`: Default port

### Avoid (For Now)
- `--cuda-stream`: May cause crashes
- `--pin-shared-memory`: May cause OOM errors
- `--flash`: Not recommended for Blackwell

---

## Key Differences: Haoming02 vs 6Morpheus6

| Aspect | Haoming02 (Upstream) | 6Morpheus6 (Pinokio) |
|--------|---------------------|---------------------|
| **Type** | Actual WebUI | Installer wrapper |
| **PyTorch** | 2.9.1+cu128 | 2.7.0 (outdated) |
| **SageAttention** | 2.2.0 | 2.1.1 (outdated) |
| **Control** | Full | Limited |
| **Updates** | Direct | Via Pinokio |
| **Blackwell Support** | Latest | Outdated packages |

**Winner for RTX 5060 Ti:** Haoming02/sd-webui-forge-classic (neo branch)

---

## Files Created

All files are in: `/home/user/ansible_gpu/`

### Documentation
- **FORGE_NEO_ANALYSIS.md** (29K) - Complete detailed analysis
- **FORGE_NEO_QUICKSTART.md** (4.9K) - Quick start guide
- **FORGE_NEO_INVESTIGATION_SUMMARY.md** - This file

### Requirements Files
- **forge_neo_requirements_torch_cuda128.txt** - PyTorch + CUDA 12.8
- **forge_neo_requirements_base.txt** - 60+ core packages
- **forge_neo_requirements_acceleration_linux.txt** - Acceleration packages

### Installation Scripts
- **install_forge_neo.sh** - Complete automated installation (Linux)
- **install_wheels_linux.sh** - Wheel-based packages (Linux)
- **install_wheels_windows.bat** - Wheel-based packages (Windows)

### Configuration
- **webui-user.sh** - Optimized config for Blackwell GPUs

---

## Quick Start (3 Steps)

```bash
# 1. Run installation
cd /home/user/ansible_gpu
bash install_forge_neo.sh

# 2. Activate environment
cd sd-webui-forge-neo
source venv/bin/activate

# 3. Launch webui
./webui-user.sh
```

Then open: http://localhost:7860

---

## Troubleshooting

### SageAttention Installation Fails

The README warns this may happen on RTX 50 series. Solution:

```bash
# Build from source
pip install triton==3.5.1
git clone https://github.com/thu-ml/SageAttention.git
cd SageAttention
pip install -e .
```

### CUDA Not Detected

```bash
# Check drivers
nvidia-smi

# Verify PyTorch CUDA
python -c "import torch; print(torch.cuda.is_available())"
```

### Out of Memory

```bash
# Use low VRAM mode
python webui.py --sage --always-low-vram
```

---

## Important Notes

### 1. SageAttention 2 Requirements
- Both positive AND negative prompts required (NaN issues if omitted)
- Based on quantization (slightly lower quality than FlashAttention)
- Supports SD1.x models (FlashAttention doesn't)

### 2. Version Discrepancy
The requirements.txt says `torch<2.9.0`, but launch_utils.py installs `torch==2.9.1+cu128`. This is intentional - launch.py installs the correct version first, requirements.txt constraint prevents auto-upgrades.

### 3. Python Version
Must use Python 3.11 (specifically 3.11.9 recommended). Other versions not supported.

### 4. CUDA Version
CUDA 12.8 required. All package URLs use cu128 or cu12 variants. No support for older CUDA versions.

---

## Next Steps

1. **Review** FORGE_NEO_ANALYSIS.md for complete details
2. **Run** install_forge_neo.sh for automated installation
3. **Read** FORGE_NEO_QUICKSTART.md for usage guide
4. **Test** with sample model to verify GPU performance
5. **Monitor** memory usage and adjust flags as needed

---

## Recommendation Summary

**For RTX 5060 Ti (Blackwell):**

1. ✅ Use Haoming02/sd-webui-forge-classic (neo branch)
2. ✅ Install SageAttention 2.2.0 (manually if needed)
3. ✅ Use PyTorch 2.9.1+cu128
4. ✅ Launch with: `--sage --disable-flash --cuda-malloc`
5. ❌ Avoid 6Morpheus6 repo (outdated packages)
6. ❌ Avoid FlashAttention for now (compatibility)
7. ❌ Avoid experimental flags (--cuda-stream, --pin-shared-memory)

**Expected Performance:**
- Fast generation with SageAttention 2
- Full CUDA 12.8 Blackwell support
- Optimized memory management
- Stable operation with proper configuration

---

**Investigation Complete!** All files ready for deployment.
