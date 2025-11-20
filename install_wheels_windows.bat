@echo off
REM Forge Neo - Install wheel-based acceleration packages for Windows
REM Run after installing base requirements

echo Installing wheel-based acceleration packages for Windows...

REM Flash Attention 2.8.3
echo Installing Flash Attention 2.8.3...
pip install https://github.com/kingbri1/flash-attention/releases/download/v2.8.3/flash_attn-2.8.3+cu128torch2.9.0.cxx11.abi-cp310-cp310-win_amd64.whl

REM SageAttention 2.2.0 (Windows needs wheel, not PyPI)
echo Installing SageAttention 2.2.0...
pip install https://github.com/thu-ml/SageAttention/releases/download/v2.2.0/sageattention-2.2.0+cu128torch2.9.0.post3-cp310-cp310-win_amd64.whl

REM Triton (Windows version)
echo Installing Triton for Windows...
pip install triton-windows==3.5.1.post21

REM Nunchaku 1.0.2
echo Installing Nunchaku 1.0.2...
pip install https://github.com/chengzeyi/nunchaku/releases/download/v1.0.2/nunchaku-1.0.2+torch2.9-cp310-cp310-win_amd64.whl

echo Done! All wheel-based packages installed.
echo.
echo To verify installation:
echo   python -c "from flash_attn import flash_attn_func; print('FlashAttention OK')"
echo   python -c "from sageattention import sageattn; print('SageAttention OK')"
echo   python -c "import nunchaku; print('Nunchaku OK')"
pause
