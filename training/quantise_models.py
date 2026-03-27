#!/usr/bin/env python3
"""
PRAHARI-Lite: Model Quantisation
Loads ae_lite_v1.pkl (fp32), saves ae_lite_v1_quantised.pkl (fp16).
"""
import sys
from pathlib import Path

BASE_DIR  = Path(__file__).parent.parent
MODEL_DIR = BASE_DIR / "models"

try:
    import torch
    import torch.nn as nn
    TORCH_AVAILABLE = True
except ImportError:
    TORCH_AVAILABLE = False


def quantise():
    if not TORCH_AVAILABLE:
        print("[QUANT] torch not available — skipping quantisation")
        return

    ae_path    = MODEL_DIR / "ae_lite_v1.pkl"
    quant_path = MODEL_DIR / "ae_lite_v1_quantised.pkl"

    if not ae_path.exists():
        print(f"[QUANT] {ae_path} not found. Run train_autoencoder.py first.")
        sys.exit(1)

    print(f"[QUANT] Loading model from {ae_path}")
    checkpoint = torch.load(ae_path, map_location='cpu', weights_only=False)
    state_dict = checkpoint['state_dict']
    threshold  = checkpoint['threshold']

    # Convert to fp16
    fp16_state = {k: v.half() for k, v in state_dict.items()}

    torch.save({
        'state_dict_fp16': fp16_state,
        'threshold': float(threshold),
        'original_dtype': 'float32',
        'quantised_dtype': 'float16',
    }, quant_path)

    # Size comparison
    fp32_size = ae_path.stat().st_size / 1024
    fp16_size = quant_path.stat().st_size / 1024
    reduction = 100 * (1 - fp16_size / fp32_size)

    print(f"[QUANT] Saved quantised model to {quant_path}")
    print(f"[QUANT] FP32 size: {fp32_size:.1f} KB")
    print(f"[QUANT] FP16 size: {fp16_size:.1f} KB")
    print(f"[QUANT] Size reduction: {reduction:.1f}%")
    print(f"[QUANT] Threshold preserved: {threshold:.6f}")


if __name__ == '__main__':
    quantise()
