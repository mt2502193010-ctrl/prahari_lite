#!/usr/bin/env python3
"""
PRAHARI-Lite — Pynq-Z2 Board Test
Run ON THE BOARD: python3 test_pynq.py
Requires: pynq library, prahari_lite.bit + .hwh in same directory
"""
import time, sys, os
import numpy as np

# AXI register offsets
REG_CONTROL  = 0x00
REG_STATUS   = 0x04
REG_FEAT_BASE= 0x08   # feat[0] at 0x08, feat[14] at 0x44
REG_RESULT   = 0x48
REG_AE_ERROR = 0x4C

CLASS_NAMES = {0:'NORMAL', 1:'APT', 2:'RECON', 3:'TRAFFIC_SPIKE', 4:'NR_MALWARE', 5:'ZERO_DAY'}

SCALER_MEAN  = [6234.24,4004.60,3293.05,6593.25,15258.71,
                -2920.63,83.28,1149956.64,8473172.65,646140.88,
                136.47,386.06,13.41,0.028,80.30]
SCALER_SCALE = [16276.14,121751.05,12446.99,14924.56,1822821.79,
                1122323.82,169.27,9106573.25,26295131.51,16298275.25,
                236.50,1199.46,840.13,0.166,196.68]

try:
    from pynq import Overlay
    import pynq.lib.dma
    PYNQ_AVAILABLE = True
except ImportError:
    PYNQ_AVAILABLE = False
    print("WARNING: pynq library not found. Running in simulation mode.")

def load_overlay(bit_path="/home/xilinx/prahari_lite/prahari_lite.bit"):
    if not PYNQ_AVAILABLE:
        raise RuntimeError("pynq not available")
    if not os.path.exists(bit_path):
        raise FileNotFoundError(f"Bitstream not found: {bit_path}")
    ol = Overlay(bit_path)
    print(f"Overlay loaded: {bit_path}")
    return ol

def classify(ip, raw_features):
    """
    Classify one flow.
    raw_features: list of 15 floats (unscaled, raw values)
    Returns: (class_name, zero_day, ae_error_float)
    """
    # Convert to Q8.8 (scale=256), unsigned 16-bit
    for i, v in enumerate(raw_features):
        q88 = int(v * 256) & 0xFFFF
        ip.write(REG_FEAT_BASE + i * 4, q88)

    # Start inference
    ip.write(REG_CONTROL, 1)

    # Poll for done (bit 0 of STATUS), timeout 10ms
    t0 = time.time()
    while True:
        status = ip.read(REG_STATUS)
        if status & 0x1:
            break
        if time.time() - t0 > 0.010:
            raise TimeoutError("Inference timeout after 10ms")
        time.sleep(0.0001)

    result    = ip.read(REG_RESULT)
    status    = ip.read(REG_STATUS)
    ae_raw    = ip.read(REG_AE_ERROR)

    final_cls  = result & 0x7
    zero_day   = bool((status >> 1) & 0x1)
    ae_error_f = ae_raw / (256.0 * 256.0)   # convert Q8.8² back to float

    return CLASS_NAMES.get(final_cls, f"UNKNOWN({final_cls})"), zero_day, ae_error_f

def run_tests(ip):
    print("\n" + "="*60)
    print("PRAHARI-Lite Board Test")
    print("="*60)

    # ── Smoke test: all-zero features ──────────────────────────
    try:
        cls, zd, err = classify(ip, [0.0]*15)
        print(f"\n[SMOKE] all-zeros → class={cls}  zero_day={zd}  ae_error={err:.4f}")
        print(f"  Expected: NORMAL — {'PASS' if cls=='NORMAL' else 'FAIL (review)'}")
    except Exception as e:
        print(f"[SMOKE] FAILED: {e}")

    # ── Latency benchmark: 1000 iterations ────────────────────
    print("\n[LATENCY] Running 1000 iterations...")
    normal_feat = [0.0] * 15
    t0 = time.time()
    for _ in range(1000):
        classify(ip, normal_feat)
    elapsed = time.time() - t0
    avg_us = elapsed * 1e6 / 1000
    print(f"  Total: {elapsed*1000:.1f} ms  Average: {avg_us:.1f} µs/flow")
    print(f"  Throughput: {1e6/avg_us:,.0f} flows/sec")

    # ── Known ATTACK sample (synthetic APT profile) ────────────
    # These are raw unscaled values chosen to land in APT territory
    apt_raw = [
        SCALER_MEAN[i] + 1.5 * SCALER_SCALE[i] * ([1,1.5,0,0,1,0,0,-0.5,0.5,-0.5,0,0,0,0,0][i])
        for i in range(15)
    ]
    try:
        cls, zd, err = classify(ip, apt_raw)
        print(f"\n[APT TEST] → class={cls}  zero_day={zd}  ae_error={err:.4f}")
        print(f"  Expected: APT — {'PASS' if cls in ('APT','ZERO_DAY') else 'FAIL'}")
    except Exception as e:
        print(f"[APT TEST] FAILED: {e}")

    print("\n" + "="*60)
    print("Test complete.")
    print("="*60)

if __name__ == '__main__':
    bit_path = sys.argv[1] if len(sys.argv) > 1 else "/home/xilinx/prahari_lite/prahari_lite.bit"
    if not PYNQ_AVAILABLE:
        print("Cannot run on non-Pynq system. Copy this file and .bit/.hwh to the board.")
        sys.exit(0)
    ol  = load_overlay(bit_path)
    ip  = ol.prahari_lite_0
    run_tests(ip)
