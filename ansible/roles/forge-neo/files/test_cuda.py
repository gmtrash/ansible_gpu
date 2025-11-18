#!/usr/bin/env python3
"""
CUDA and PyTorch verification script for Forge Neo installation.
This script verifies that PyTorch is properly installed with CUDA support.
"""

import sys

def test_pytorch_import():
    """Test if PyTorch can be imported."""
    try:
        import torch
        print("✓ PyTorch imported successfully")
        print(f"  PyTorch version: {torch.__version__}")
        return torch
    except ImportError as e:
        print(f"✗ Failed to import PyTorch: {e}")
        sys.exit(1)

def test_cuda_availability(torch):
    """Test if CUDA is available in PyTorch."""
    if torch.cuda.is_available():
        print("✓ CUDA is available")
        print(f"  CUDA version: {torch.version.cuda}")
        print(f"  cuDNN version: {torch.backends.cudnn.version()}")
        return True
    else:
        print("✗ CUDA is NOT available")
        print("  Please check NVIDIA driver and CUDA installation")
        sys.exit(1)

def test_gpu_devices(torch):
    """Test GPU device detection."""
    device_count = torch.cuda.device_count()
    print(f"✓ Detected {device_count} GPU device(s)")

    for i in range(device_count):
        device_name = torch.cuda.get_device_name(i)
        device_props = torch.cuda.get_device_properties(i)
        total_memory = device_props.total_memory / (1024**3)  # Convert to GB
        print(f"  GPU {i}: {device_name}")
        print(f"    Total memory: {total_memory:.2f} GB")
        print(f"    Compute capability: {device_props.major}.{device_props.minor}")

def test_tensor_operations(torch):
    """Test basic tensor operations on GPU."""
    try:
        # Create a small tensor and move it to GPU
        x = torch.randn(100, 100, device='cuda')
        y = torch.randn(100, 100, device='cuda')

        # Perform matrix multiplication
        z = torch.matmul(x, y)

        # Verify result is on GPU
        assert z.device.type == 'cuda'

        print("✓ GPU tensor operations working")
        print(f"  Test tensor shape: {z.shape}")
        print(f"  Test tensor device: {z.device}")
        return True
    except Exception as e:
        print(f"✗ GPU tensor operations failed: {e}")
        sys.exit(1)

def main():
    """Run all CUDA verification tests."""
    print("=" * 60)
    print("CUDA and PyTorch Verification")
    print("=" * 60)
    print()

    # Run tests
    torch = test_pytorch_import()
    test_cuda_availability(torch)
    test_gpu_devices(torch)
    test_tensor_operations(torch)

    print()
    print("=" * 60)
    print("✓ All tests passed! PyTorch with CUDA is working correctly.")
    print("=" * 60)

    return 0

if __name__ == "__main__":
    sys.exit(main())
