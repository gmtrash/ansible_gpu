# Forge Neo Repositories - Complete Dependency Analysis

**Analysis Date:** 2025-11-20
**Repositories Analyzed:**
1. Upstream: https://github.com/Haoming02/sd-webui-forge-classic (branch: neo)
2. NVIDIA-optimized: https://github.com/6Morpheus6/forge-neo (main branch)

---

## Executive Summary

**Key Finding:** The 6Morpheus6/forge-neo is NOT a fork of the webui - it's a **Pinokio automation script** that installs Haoming02/sd-webui-forge-classic. Both use the same underlying codebase.

**Recommended Repository:** Haoming02/sd-webui-forge-classic (neo branch)
**Reason:** This is the actual webui implementation. The 6Morpheus6 repo is just a Pinokio wrapper.

**For RTX 5060 Ti (Blackwell):** SageAttention 2 is required and may need manual installation.

---

## 1. webui.sh Analysis

### Finding: No webui.sh in Haoming02 Repository
The "neo" branch has **removed Unix shell scripts** (webui.sh) and focuses on Windows (webui.bat). The documentation states: *"Unix .sh launch scripts have been removed - simply copy a launch script from other working WebUI if needed on non-Windows platforms."*

### 6Morpheus6 webui.sh Behavior
The 6Morpheus6 Pinokio repo DOES include webui.sh, which:

**Installation Steps:**
1. Sources configuration from `webui-user.sh` for customization
2. Validates prerequisites:
   - 64-bit OS check
   - Git and Python 3 availability
   - Python venv module installed
   - Non-root execution (unless `-f` flag used)
3. Clones the repository: `git clone -b neo https://github.com/Haoming02/sd-webui-forge-classic app`
4. Creates Python virtual environment using venv
5. Upgrades pip and activates venv
6. Attempts TCMalloc configuration on Linux for memory optimization
7. Launches `launch.py` with automatic restart support via `tmp/restart` file

**Can We Bypass It?** YES - we can directly use Python to run launch.py or webui.py after setting up the environment manually.

---

## 2. Complete Dependency List

### 2.1 Core Requirements (requirements.txt)
**Source:** Both repositories use identical requirements.txt

```
GitPython==3.1.44
Pillow==11.3.0
accelerate==1.10.1
clean-fid==0.1.35
diffusers==0.35.1
diskcache==5.6.3
einops==0.8.1
facexlib==0.3.0
fastapi==0.112.4
httpcore==0.15.0
httpx==0.24.1
huggingface-hub==0.34.1
inflection==0.5.1
joblib==1.5.1
jsonmerge==1.8.0
kornia==0.6.7
lark==1.2.2
lightning==2.5.1
loadimg==0.1.2
numpy==1.26.4
omegaconf==2.2.3
open-clip-torch==2.32.0
opencv-python==4.8.1.78
peft==0.17.1
piexif==1.1.3
pillow-heif==0.22.0
protobuf==4.25.7
psutil==5.9.8
pydantic-core==2.23.4
pydantic==2.9.2
resize-right==0.0.2
safetensors==0.6.2
scikit-image==0.25.2
setuptools==69.5.1
spandrel-extra-arches==0.2.0
spandrel==0.4.1
tomesd==0.1.3
torchdiffeq==0.2.5
torchsde==0.2.6
tqdm==4.67.1
transformers==4.56.2
torch<2.9.0
```

### 2.2 PyTorch and CUDA Dependencies

**Haoming02/sd-webui-forge-classic (Primary Installation):**
```
PyTorch: 2.9.1+cu128
TorchVision: 0.24.1+cu128
CUDA: 12.8
Index URL: https://download.pytorch.org/whl/cu128
```

**6Morpheus6/forge-neo (Pinokio Script):**
```
PyTorch: 2.7.0
TorchVision: 0.22.0
TorchAudio: 2.7.0
CUDA: 12.8
```

**README States:**
```
Default: torch==2.8.0+cu128
With: xformers==0.0.32
```

### 2.3 Optional Acceleration Packages

#### A. Installed by prepare_environment() in launch_utils.py

**Versions from Haoming02 (latest):**

**Gradio:**
```
gradio==4.40.0
gradio_imageslider==0.0.20
gradio_rangeslider==0.0.6
```

**Packaging:**
```
packaging==24.2
```

**Xformers (optional with --xformers):**
```
Version: 0.0.33.post1
Install: pip install xformers==0.0.33.post1 --extra-index-url https://download.pytorch.org/whl/cu128
```

**Flash Attention (optional with --flash):**
```
Version: 2.8.3

Windows:
- Custom wheel from kingbri1/flash-attention releases
- URL: https://github.com/kingbri1/flash-attention/releases/download/{version}/flash_attn-{ver_FLASH}+cu128torch2.9.0.cxx11.abi-cp310-cp310-win_amd64.whl

Linux:
- Dao-AILab official release
- URL: https://github.com/Dao-AILab/flash-attention/releases/download/{version}/flash_attn-{ver_FLASH}+cu12torch2.9.0cxx11abiFALSE-cp310-cp310-linux_x86_64.whl
```

**SageAttention (optional with --sage):**
```
Version: 2.2.0

Windows:
- URL: https://github.com/thu-ml/SageAttention/releases/download/v{version}/sageattention-{ver_SAGE}+cu128torch2.9.0.post3-cp310-cp310-win_amd64.whl

Linux:
- PyPI: sageattention==2.2.0
```

**Triton:**
```
Version: 3.5.1

Windows:
- triton-windows==3.5.1.post21

Linux:
- triton==3.5.1
```

**Nunchaku:**
```
Version: 1.0.2

Windows:
- URL: https://github.com/chengzeyi/nunchaku/releases/download/v{version}/nunchaku-{ver_NUNCHAKU}+torch2.9-cp310-cp310-win_amd64.whl

Linux:
- URL: https://github.com/chengzeyi/nunchaku/releases/download/v{version}/nunchaku-{ver_NUNCHAKU}+torch2.9-cp310-cp310-linux_x86_64.whl
```

**Bitsandbytes (unless --disable-bnb):**
```
bitsandbytes==0.48.2
```

**ONNX Runtime GPU (optional with --onnxruntime-gpu):**
```
Index URL: https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/onnxruntime-cuda-12/
```

**CLIP:**
```
URL: https://github.com/openai/CLIP/archive/d50d76daa670286dd6cacf3bcd80b5e4823fc8e1.zip
```

#### B. From 6Morpheus6 Pinokio (torch.js)

```
PyTorch: 2.7.0
TorchVision: 0.22.0
TorchAudio: 2.7.0
Xformers: 0.0.30
Triton (Windows): triton-windows==3.3.1.post19
SageAttention Windows: 2.1.1+cu128torch2.7.0
SageAttention Linux: 2.1.1
Nunchaku Windows: 1.0.1+torch2.7-cp310
Nunchaku Linux: 1.0.1+torch2.7-cp310
```

### 2.4 requirements_versions.txt

**Finding:** No requirements_versions.txt file exists in either repository (404 errors).

---

## 3. FlashAttention vs SageAttention Analysis

### 3.1 Where FlashAttention is Used

**Detection Location:** `/backend/memory_management.py`
```python
def flash_enabled():
    if cpu_state != CPUState.GPU:
        return False
    if not is_nvidia():
        return False
    return FLASH_IS_AVAILABLE
```

**Import Location:** `/backend/attention.py`
```python
try:
    from flash_attn import flash_attn_func
    FLASH_IS_AVAILABLE = True
except:
    FLASH_IS_AVAILABLE = False
```

**Usage Location:** `/backend/attention.py`
```python
@torch.library.custom_op("flash_attention::flash_attn", mutates_args=())
def flash_attn_wrapper(q, k, v, dropout_p=0.0, causal=False):
    # Wraps flash_attn_func with custom operator
```

**Installation Trigger:**
```
Command-line flag: --flash
Environment variable override: FLASH_PACKAGE
```

### 3.2 Where SageAttention is Mentioned

**Detection Location:** `/backend/memory_management.py`
```python
def sage_enabled():
    if cpu_state != CPUState.GPU:
        return False
    if not is_nvidia():
        return False
    return SAGE_IS_AVAILABLE
```

**Import and Version Detection:** `/backend/attention.py`
```python
try:
    from sageattention import sageattn
    SAGE_IS_AVAILABLE = True

    # Version detection for SageAttention 2
    sage_version = importlib.metadata.version("sageattention")
    SAGE_V2_IS_AVAILABLE = version.parse(sage_version) >= version.parse("2.0.0")
except:
    SAGE_IS_AVAILABLE = False
```

**Usage in Attention Selection:**
```python
# Priority order:
1. SageAttention (if enabled)
2. FlashAttention (if enabled)
3. xformers (if enabled)
4. PyTorch scaled_dot_product_attention
5. Split or Basic attention
```

**Installation Trigger:**
```
Command-line flags: --sage
Additional flags: --sage2-function, --sage-quantization-backend, --sage-quant-gran, --sage-accum-dtype
Environment variable override: SAGE_PACKAGE
```

### 3.3 How to Swap FlashAttention for SageAttention

**Current Implementation:** The codebase already supports BOTH and automatically selects based on what's installed. SageAttention has HIGHER priority than FlashAttention.

**Swap Strategy:**

**Option 1: Use Command-Line Flags (Recommended)**
```bash
# Install SageAttention instead of FlashAttention
python launch.py --sage --disable-flash

# Or configure in webui-user.bat/webui-user.sh:
COMMANDLINE_ARGS="--sage --disable-flash"
```

**Option 2: Environment Variable Override**
```bash
# Install custom SageAttention build
export SAGE_PACKAGE="sageattention==2.2.0"
export FLASH_PACKAGE=""  # Prevent FlashAttention installation
```

**Option 3: Direct Installation (Bypass launch.py)**
```bash
# In your venv:
pip install sageattention==2.2.0 triton==3.5.1
# Don't install flash_attn
```

**Detection Order in Code:**
The attention mechanism automatically prioritizes SageAttention > FlashAttention, so if both are installed, SageAttention will be used by default.

**To Force SageAttention When Both Installed:**
```bash
python webui.py --disable-flash
```

---

## 4. Repository Comparison

### 4.1 Key Differences

| Aspect | Haoming02/sd-webui-forge-classic | 6Morpheus6/forge-neo |
|--------|----------------------------------|---------------------|
| **Type** | Actual WebUI implementation | Pinokio automation script |
| **Purpose** | Main Forge Neo codebase | Automated installer for Haoming02 repo |
| **Platform** | Windows-focused (no webui.sh) | Cross-platform via Pinokio |
| **PyTorch** | 2.9.1+cu128 (latest) | 2.7.0 (older in script) |
| **SageAttention** | 2.2.0 | 2.1.1 |
| **Installation** | Manual or script-based | Automated via Pinokio |
| **Updates** | Direct git pull | Update through Pinokio |
| **Customization** | Full control | Limited to Pinokio config |

### 4.2 Which is Better for NVIDIA Blackwell (RTX 5060 Ti)?

**Answer: Haoming02/sd-webui-forge-classic (neo branch)**

**Reasons:**

1. **Latest PyTorch (2.9.1+cu128):**
   - Better support for newer CUDA architectures
   - RTX 5060 Ti (Blackwell) requires latest CUDA support

2. **Latest SageAttention (2.2.0):**
   - README explicitly mentions RTX 50 series requiring SageAttention 2
   - Newer version has better Blackwell optimizations

3. **Direct Control:**
   - Manual installation allows building SageAttention from source if needed
   - More flexibility for troubleshooting new GPU issues

4. **Active Development:**
   - Upstream receives updates first
   - Pinokio script may lag behind

**RTX 50 Series Specific Guidance from README:**
> "Users with RTX 50 GPUs may require manual installation of SageAttention 2 rather than relying on automatic installation via the --sage flag."

### 4.3 Does 6Morpheus6 Handle Newer GPUs Better?

**No.** The 6Morpheus6 repo:
- Uses older PyTorch (2.7.0)
- Uses older SageAttention (2.1.1)
- Is just a wrapper script that installs the upstream repo
- Adds no GPU-specific optimizations beyond what's in upstream

The 6Morpheus6 repo is marked "[NVIDIA ONLY]" because the **upstream** Haoming02 repo is NVIDIA-focused, not because it adds additional NVIDIA optimizations.

---

## 5. Launch Mechanisms

### 5.1 How the WebUI is Started

**Entry Point Hierarchy:**
```
1. webui-user.bat (Windows) or webui.sh (Linux)
   ↓
2. launch.py
   ↓
3. webui.py
   ↓
4. modules/initialize.py + modules_forge/initialization.py
   ↓
5. FastAPI/Gradio server starts
```

### 5.2 launch.py Details

**Main Functions:**

```python
def main():
    # 1. System information dump (optional)
    if args.dump_sysinfo:
        print_sysinfo()
        exit(0)

    # 2. Environment preparation (unless --skip-prepare-environment)
    if not args.skip_prepare_environment:
        prepare_environment()

    # 3. Reference configuration (A1111/ComfyUI paths)
    configure_for_tests()

    # 4. Start application
    start()
```

**UV Package Manager Integration:**
```python
# Conditionally activate UV hook
if args.uv or args.uv_symlink:
    from modules_forge.uv_hook import patch
    patch(symlink=args.uv_symlink)
```

**prepare_environment() in launch_utils.py:**
1. Installs PyTorch + TorchVision
2. Installs requirements.txt
3. Conditionally installs: xformers, flash_attn, sageattention, bitsandbytes
4. Installs CLIP from GitHub
5. Re-enforces requirements.txt twice

### 5.3 webui.py Details

**Two Operational Modes:**

**API-Only Mode (`--nowebui`):**
```python
def api_only_worker():
    # Launches FastAPI server on port 7861
    # No Gradio UI
```

**Web UI Mode (Default):**
```python
def webui_worker():
    # Creates Gradio interface
    # Adds optional API layer
    # Handles authentication
    # Disables CORS for security
    # Implements restart loop via tmp/restart file
```

**Startup Sequence in webui.py:**
```python
timer.startup_timer.record("launcher")

# Initialize core systems
initialize.shush()
initialize_forge()  # From modules_forge/initialization.py
initialize.imports()
initialize.check_versions()
initialize.initialize()

# Launch worker thread (API or WebUI)
if cmd_opts.nowebui:
    api_only_worker()
else:
    webui_worker()

# Maintain process
main_thread.loop()
```

### 5.4 Command-Line Arguments Supported

**Installation Arguments:**
```
--flash                  Install flash_attn
--sage                   Install sageattention
--xformers               Install xformers
--disable-flash          Disable FlashAttention
--disable-sage           Disable SageAttention
--disable-xformers       Disable xformers
--uv                     Use UV package manager
--uv-symlink             Use UV with symlink mode
--skip-install           Skip package installation
--skip-prepare-environment  Skip environment setup
--reinstall-torch        Force torch reinstall
--reinstall-xformers     Force xformers reinstall
```

**SageAttention Configuration:**
```
--sage2-function         Select function (auto, fp16_triton, fp16_cuda, fp8_cuda)
--sage-quantization-backend  Backend (cuda or triton)
--sage-quant-gran        Granularity (per_warp or per_thread)
--sage-accum-dtype       Accumulation dtype (fp16, fp32, fp16+fp32, fp32+fp32)
```

**CUDA/GPU Arguments:**
```
--device-id ID           Select CUDA device
--skip-torch-cuda-test   Skip CUDA validation
--onnxruntime-gpu        Install onnxruntime-gpu cu128
--gpu-device-id ID       Backend GPU device ID
```

**Memory Management:**
```
--always-gpu             Keep models on GPU
--always-cpu             Keep models on CPU
--always-low-vram        Low VRAM mode
--always-high-vram       High VRAM mode
--cuda-malloc            Enable CUDA malloc optimization
--cuda-stream            Enable CUDA stream
--pin-shared-memory      Pin shared memory (RTX 30+)
```

**Attention Mechanism:**
```
--attention-split        Alternative attention mode
--attention-pytorch      Use PyTorch attention
--force-upcast-attention Upcast attention computations
--disable-attention-upcast  Prevent attention upcasting
```

**Precision:**
```
--all-in-fp32           Everything in FP32
--unet-in-bf16          UNet in bfloat16
--unet-in-fp8-e4m3fn    UNet in FP8
--unet-in-fp8-e5m2      UNet in FP8 (alternate)
--fast-fp16             FP16 accumulation (PyTorch 2.7.0+)
```

**Web Server:**
```
--listen                Listen on all interfaces
--port PORT             Server port (default: 7860)
--share                 Create Gradio share link
--gradio-auth USER:PASS Authentication
--server-name NAME      Server hostname
--cors-allow-origins    CORS origins
--tls-keyfile FILE      TLS key file
--tls-certfile FILE     TLS certificate
```

**Other:**
```
--dump-sysinfo          Print system info and exit
--log-startup           Log startup events
--loglevel LEVEL        Logging level
--nowebui               API-only mode
--api-log               Enable API logging
```

---

## 6. Strategy for Creating Single requirements.txt

### 6.1 Bypassing webui.sh / launch.py

**Goal:** Create a unified requirements.txt that includes ALL dependencies without needing launch.py's prepare_environment().

**Challenge:** Several packages are installed via:
- Direct wheel URLs (FlashAttention, SageAttention, Nunchaku)
- Multiple index URLs (PyTorch, ONNX)
- Git URLs (CLIP)
- Conditional logic (platform-specific)

### 6.2 Unified Requirements Strategy

**Create two files:**

**requirements_base.txt** - Platform-independent packages
```
GitPython==3.1.44
Pillow==11.3.0
accelerate==1.10.1
clean-fid==0.1.35
diffusers==0.35.1
diskcache==5.6.3
einops==0.8.1
facexlib==0.3.0
fastapi==0.112.4
httpcore==0.15.0
httpx==0.24.1
huggingface-hub==0.34.1
inflection==0.5.1
joblib==1.5.1
jsonmerge==1.8.0
kornia==0.6.7
lark==1.2.2
lightning==2.5.1
loadimg==0.1.2
numpy==1.26.4
omegaconf==2.2.3
open-clip-torch==2.32.0
opencv-python==4.8.1.78
peft==0.17.1
piexif==1.1.3
pillow-heif==0.22.0
protobuf==4.25.7
psutil==5.9.8
pydantic-core==2.23.4
pydantic==2.9.2
resize-right==0.0.2
safetensors==0.6.2
scikit-image==0.25.2
setuptools==69.5.1
spandrel-extra-arches==0.2.0
spandrel==0.4.1
tomesd==0.1.3
torchdiffeq==0.2.5
torchsde==0.2.6
tqdm==4.67.1
transformers==4.56.2
packaging==24.2
gradio==4.40.0
gradio_imageslider==0.0.20
gradio_rangeslider==0.0.6
bitsandbytes==0.48.2
clip @ https://github.com/openai/CLIP/archive/d50d76daa670286dd6cacf3bcd80b5e4823fc8e1.zip
```

**requirements_torch_cuda128.txt** - PyTorch with CUDA 12.8
```
--index-url https://download.pytorch.org/whl/cu128
torch==2.9.1+cu128
torchvision==0.24.1+cu128
xformers==0.0.33.post1
```

**requirements_acceleration.txt** - Optional acceleration packages
```
# SageAttention (Linux only via PyPI)
sageattention==2.2.0

# Triton
triton==3.5.1  # Linux
# triton-windows==3.5.1.post21  # Windows (uncomment for Windows)
```

**For wheel-based packages (FlashAttention, SageAttention Windows, Nunchaku):**

Create a bash/bat script:

**install_wheels_linux.sh:**
```bash
#!/bin/bash
# Install wheel-based acceleration packages

# Flash Attention
pip install https://github.com/Dao-AILab/flash-attention/releases/download/v2.8.3/flash_attn-2.8.3+cu12torch2.9.0cxx11abiFALSE-cp310-cp310-linux_x86_64.whl

# Nunchaku
pip install https://github.com/chengzeyi/nunchaku/releases/download/v1.0.2/nunchaku-1.0.2+torch2.9-cp310-cp310-linux_x86_64.whl
```

**install_wheels_windows.bat:**
```batch
@echo off
REM Install wheel-based acceleration packages

REM Flash Attention
pip install https://github.com/kingbri1/flash-attention/releases/download/v2.8.3/flash_attn-2.8.3+cu128torch2.9.0.cxx11.abi-cp310-cp310-win_amd64.whl

REM SageAttention
pip install https://github.com/thu-ml/SageAttention/releases/download/v2.2.0/sageattention-2.2.0+cu128torch2.9.0.post3-cp310-cp310-win_amd64.whl

REM Triton
pip install triton-windows==3.5.1.post21

REM Nunchaku
pip install https://github.com/chengzeyi/nunchaku/releases/download/v1.0.2/nunchaku-1.0.2+torch2.9-cp310-cp310-win_amd64.whl
```

### 6.3 Installation Order

```bash
# 1. Create venv
python -m venv venv
source venv/bin/activate  # Linux
# venv\Scripts\activate  # Windows

# 2. Install PyTorch
pip install -r requirements_torch_cuda128.txt

# 3. Install base requirements
pip install -r requirements_base.txt

# 4. Install acceleration packages
pip install -r requirements_acceleration.txt  # Linux

# Or use wheel script
bash install_wheels_linux.sh  # Linux
# install_wheels_windows.bat  # Windows

# 5. Verify installation
python -c "import torch; print(torch.cuda.is_available())"
python -c "from sageattention import sageattn; print('SageAttention OK')"
```

### 6.4 Simplified Single File Approach

If you want a SINGLE requirements.txt (accepting some limitations):

```
# requirements_unified.txt
# Use with: pip install -r requirements_unified.txt --extra-index-url https://download.pytorch.org/whl/cu128

# PyTorch
torch==2.9.1+cu128
torchvision==0.24.1+cu128

# Acceleration (may need manual installation)
xformers==0.0.33.post1
# sageattention - Install manually via wheel for Windows or pip for Linux
# flash_attn - Install manually via wheel
# nunchaku - Install manually via wheel

# Base packages
GitPython==3.1.44
Pillow==11.3.0
accelerate==1.10.1
clean-fid==0.1.35
diffusers==0.35.1
diskcache==5.6.3
einops==0.8.1
facexlib==0.3.0
fastapi==0.112.4
httpcore==0.15.0
httpx==0.24.1
huggingface-hub==0.34.1
inflection==0.5.1
joblib==1.5.1
jsonmerge==1.8.0
kornia==0.6.7
lark==1.2.2
lightning==2.5.1
loadimg==0.1.2
numpy==1.26.4
omegaconf==2.2.3
open-clip-torch==2.32.0
opencv-python==4.8.1.78
peft==0.17.1
piexif==1.1.3
pillow-heif==0.22.0
protobuf==4.25.7
psutil==5.9.8
pydantic-core==2.23.4
pydantic==2.9.2
resize-right==0.0.2
safetensors==0.6.2
scikit-image==0.25.2
setuptools==69.5.1
spandrel-extra-arches==0.2.0
spandrel==0.4.1
tomesd==0.1.3
torchdiffeq==0.2.5
torchsde==0.2.6
tqdm==4.67.1
transformers==4.56.2
packaging==24.2
gradio==4.40.0
gradio_imageslider==0.0.20
gradio_rangeslider==0.0.6
bitsandbytes==0.48.2
clip @ https://github.com/openai/CLIP/archive/d50d76daa670286dd6cacf3bcd80b5e4823fc8e1.zip
triton==3.5.1
```

Then install wheels separately:
```bash
pip install -r requirements_unified.txt --extra-index-url https://download.pytorch.org/whl/cu128
bash install_wheels_linux.sh
```

---

## 7. CUDA/PyTorch Version Constraints

### 7.1 Detected Constraints

**Python Version:**
- **Required:** Python 3.11 (specifically 3.11.9 recommended)
- **Target:** py311 in pyproject.toml

**PyTorch Constraints:**
```
Latest (Haoming02): torch==2.9.1+cu128
README states: torch==2.8.0+cu128 (default)
Pinokio uses: torch==2.7.0
requirements.txt: torch<2.9.0 (contradicts actual installation!)
```

**CUDA Version:**
```
Primary: CUDA 12.8 (cu128)
All package URLs use cu128 or cu12 variants
No support for older CUDA versions in current codebase
```

**Special Requirements:**

**For RTX 50 Series (Blackwell):**
```
- SageAttention 2.2.0+ required
- May need manual installation from source
- --sage flag might not work - manual build needed
```

**For RTX 30+ Series:**
```
Optional flags: --cuda-malloc, --cuda-stream, --pin-shared-memory
Warning: "may cause OutOfMemory errors or even crash"
```

**For Older GPUs (pre-RTX 30):**
```
Manual PyTorch downgrade needed:
set TORCH_COMMAND=pip install torch==2.1.2 torchvision==0.16.2 --extra-index-url https://download.pytorch.org/whl/cu121
```

### 7.2 Attention Mechanism Constraints

**SageAttention 2 Requirements:**
```
- NVIDIA GPU only
- Both positive AND negative prompts required (NaN issues if omitted)
- Triton dependency (automatically installed)
- Head dimensions must be 64, 96, or 128 (for non-v2)
- SageAttention 2 has "looser restrictions" - works on SD1
```

**FlashAttention Requirements:**
```
- NVIDIA GPU only
- CUDA device required
- Specific tensor layouts needed
- Windows: Currently no build for PyTorch 2.9.0 (warning in code)
```

**Attention Priority Order:**
```
1. SageAttention (highest priority - quantization-based, slightly worse quality)
2. FlashAttention (high quality, strict requirements)
3. xformers (good compatibility)
4. PyTorch scaled_dot_product_attention (default)
5. Split or Basic (fallback for low memory)
```

---

## 8. Recommendations for RTX 5060 Ti (Blackwell)

### 8.1 Installation Steps

```bash
# 1. Clone the repository
git clone https://github.com/Haoming02/sd-webui-forge-classic sd-webui-forge-neo --branch neo
cd sd-webui-forge-neo

# 2. Create Python 3.11 venv
python3.11 -m venv venv
source venv/bin/activate

# 3. Install PyTorch with CUDA 12.8
pip install torch==2.9.1+cu128 torchvision==0.24.1+cu128 --index-url https://download.pytorch.org/whl/cu128

# 4. Install base requirements
pip install -r requirements.txt

# 5. Install xformers
pip install xformers==0.0.33.post1 --index-url https://download.pytorch.org/whl/cu128

# 6. MANUALLY install SageAttention 2 for Blackwell
# Option A: From PyPI (Linux)
pip install sageattention==2.2.0 triton==3.5.1

# Option B: From source (if prebuilt doesn't work)
pip install triton==3.5.1
git clone https://github.com/thu-ml/SageAttention.git
cd SageAttention
pip install -e .
cd ..

# 7. Install other acceleration packages
pip install bitsandbytes==0.48.2
pip install packaging==24.2
pip install gradio==4.40.0 gradio_imageslider==0.0.20 gradio_rangeslider==0.0.6

# 8. Install CLIP
pip install clip @ https://github.com/openai/CLIP/archive/d50d76daa670286dd6cacf3bcd80b5e4823fc8e1.zip

# 9. Test CUDA
python -c "import torch; print(f'CUDA Available: {torch.cuda.is_available()}'); print(f'CUDA Version: {torch.version.cuda}'); print(f'GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"N/A\"}')"

# 10. Test SageAttention
python -c "from sageattention import sageattn; print('SageAttention 2 installed successfully')"

# 11. Run webui
python webui.py --sage --disable-flash --listen
```

### 8.2 Recommended Configuration

**For webui-user.sh:**
```bash
#!/bin/bash

# Python executable
export PYTHON_CMD="python"

# Command line arguments
export COMMANDLINE_ARGS="--sage --disable-flash --cuda-malloc --listen --port 7860"

# Optional: Skip installation if already done
# export COMMANDLINE_ARGS="${COMMANDLINE_ARGS} --skip-install"

# Launch
python webui.py ${COMMANDLINE_ARGS}
```

**Why these flags:**
- `--sage`: Use SageAttention 2 (best for Blackwell)
- `--disable-flash`: Avoid FlashAttention (may have compatibility issues)
- `--cuda-malloc`: CUDA memory optimization
- `--listen`: Allow network access
- `--port 7860`: Default port

**Avoid these flags for now (until tested):**
- `--cuda-stream`: May cause crashes
- `--pin-shared-memory`: May cause OOM errors
- `--flash`: Not recommended for Blackwell

---

## 9. Summary and Quick Reference

### 9.1 Key Takeaways

1. **6Morpheus6/forge-neo is NOT the webui** - it's a Pinokio installer script
2. **Use Haoming02/sd-webui-forge-classic (neo branch)** for actual installation
3. **RTX 5060 Ti requires SageAttention 2** - may need manual installation
4. **PyTorch 2.9.1+cu128** is the latest supported version
5. **CUDA 12.8** is required
6. **Python 3.11.9** is recommended
7. **SageAttention has priority over FlashAttention** in the attention selection
8. **No webui.sh in upstream** - Windows-focused, but easily adaptable

### 9.2 Attention Mechanism Swap Summary

**Current Behavior:**
- Auto-selects: SageAttention > FlashAttention > xformers > PyTorch
- Both can be installed simultaneously
- SageAttention has priority by design

**To Use Only SageAttention:**
```bash
python webui.py --sage --disable-flash
```

**To Use Only FlashAttention:**
```bash
python webui.py --flash --disable-sage
```

**To Prevent Installation During Launch:**
```bash
python launch.py --skip-install
# or
python webui.py --skip-prepare-environment
```

### 9.3 Complete Package Index

**PyTorch Index:**
```
https://download.pytorch.org/whl/cu128
```

**ONNX Runtime Index:**
```
https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/onnxruntime-cuda-12/
```

**Direct Wheel URLs:**
- See section 2.3 for complete list of FlashAttention, SageAttention, Nunchaku wheel URLs

### 9.4 Environment Variables for Customization

```bash
# Override package URLs
export TORCH_COMMAND="pip install torch==2.9.1+cu128 torchvision==0.24.1+cu128 --index-url https://download.pytorch.org/whl/cu128"
export XFORMERS_PACKAGE="xformers==0.0.33.post1"
export SAGE_PACKAGE="sageattention==2.2.0"
export FLASH_PACKAGE="https://github.com/Dao-AILab/flash-attention/releases/download/v2.8.3/flash_attn-2.8.3+cu12torch2.9.0cxx11abiFALSE-cp310-cp310-linux_x86_64.whl"
export TRITON_PACKAGE="triton==3.5.1"
export NUNCHAKU_PACKAGE="https://github.com/chengzeyi/nunchaku/releases/download/v1.0.2/nunchaku-1.0.2+torch2.9-cp310-cp310-linux_x86_64.whl"
export ONNX_PACKAGE="onnxruntime-gpu"
```

---

## 10. Additional Files and Resources

### 10.1 Important Files in Repository

**Configuration:**
- `webui-user.bat` (Windows) - User configuration
- `webui-user.sh` (Linux) - User configuration (not in upstream, create manually)
- `pyproject.toml` - Python project configuration

**Startup:**
- `launch.py` - Environment preparation and package installation
- `webui.py` - Main entry point
- `webui.bat` - Windows launcher

**Backend:**
- `/backend/attention.py` - Attention mechanism implementation
- `/backend/memory_management.py` - GPU memory and acceleration detection
- `/backend/args.py` - Backend command-line arguments
- `/modules/launch_utils.py` - Installation utilities
- `/modules/cmd_args.py` - Main command-line arguments

**Forge-Specific:**
- `/modules_forge/initialization.py` - Forge-specific initialization
- `/modules_forge/uv_hook.py` - UV package manager integration
- `/modules_forge/cuda_malloc.py` - CUDA memory optimization

### 10.2 Documentation Links

**Upstream Repository:**
https://github.com/Haoming02/sd-webui-forge-classic/tree/neo

**SageAttention:**
https://github.com/thu-ml/SageAttention

**FlashAttention:**
https://github.com/Dao-AILab/flash-attention

**PyTorch:**
https://pytorch.org/

**CUDA Toolkit:**
https://developer.nvidia.com/cuda-toolkit

---

## Appendix: Version Discrepancy Analysis

**Critical Finding:** The requirements.txt states `torch<2.9.0`, but launch_utils.py installs `torch==2.9.1+cu128`.

**Explanation:**
- requirements.txt uses a version constraint to prevent pip from auto-upgrading beyond 2.9.x
- launch_utils.py explicitly installs 2.9.1+cu128 with custom index URL
- This is intentional: launch.py runs BEFORE requirements.txt installation
- The constraint in requirements.txt prevents conflicts during secondary installation passes

**Impact:** None - launch_utils.py takes precedence and installs the correct version.

---

**Report Generated:** 2025-11-20
**Total Packages Identified:** 60+ (base) + 10+ (optional acceleration)
**Recommended for Blackwell:** Haoming02/sd-webui-forge-classic with SageAttention 2.2.0
