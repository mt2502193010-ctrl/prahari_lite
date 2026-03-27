# FPGA Resource Estimates: Pynq-Z2 (XC7Z020)

## Available Resources

| Resource | Available | PRAHARI-Lite | % Used |
|----------|-----------|--------------|--------|
| LUTs     | 53,200    | 1,700        | 3.2%   |
| BRAM18   | 106       | 3            | 2.8%   |
| DSPs     | 220       | 12           | 5.5%   |

## Component Breakdown

```
Component          | LUTs  | BRAM18 | DSPs | Latency
-------------------+-------+--------+------+--------
DT Inference       |   800 |      2 |    0 | 12 cy
AE Inference       |   500 |      1 |    8 | 38 cy
Fusion Logic       |   100 |      0 |    0 |  1 cy
Feature Scaler     |   200 |      0 |    4 |  2 cy
Top-Level Glue     |   100 |      0 |    0 |  1 cy
-------------------+-------+--------+------+--------
TOTAL             | 1,700 |      3 |   12 | 54 cy
% of Pynq-Z2      |  3.2% |   2.8% | 5.5% | 540ns
```

At 100 MHz clock → **540 ns latency** per flow classification.

## Why DT instead of GBM?

GBM (500 trees) alone would require ~50,000+ LUTs → **cannot fit** on Pynq-Z2.
PRAHARI-Lite fits in **<4% of available LUTs** with full inference capability.

```
PRAHARI v7 (GBM):    ~50,000+ LUTs (94% of Pynq-Z2) — NOT IMPLEMENTABLE
PRAHARI-Lite (DT):      1,700 LUTs  (3.2% of Pynq-Z2) — FITS WITH MARGIN
```

## BRAM Usage Detail

### DT Inference BRAM (2 BRAM18 = 36 Kbit)
- Tree node storage: 512 nodes × 6 fields × ~5 bits = ~15 Kbit
- Leaf purity lookup: 256 leaves × 16 bits = ~4 Kbit
- Remaining headroom for node expansion

### AE Inference BRAM (1 BRAM18 = 18 Kbit)
- Weight storage (FP8 quantised):
  - enc1: 15×8 = 120 weights × 8 bits = 960 bits
  - enc2: 8×4 = 32 weights × 8 bits = 256 bits
  - dec1: 4×8 = 32 weights × 8 bits = 256 bits
  - dec2: 8×15 = 120 weights × 8 bits = 960 bits
  - Total: ~2,432 bits — easily fits in 1 BRAM18

## DSP Usage

### Feature Scaler (4 DSPs)
- 15 multiply-accumulate operations for StandardScaler: (x - mean) / std
- Pipelined to 4 DSPs with II=4

### AE Inference (8 DSPs)
- Dense layer MAC operations
- Shared across encoder/decoder layers via time-multiplexing

## Timing Analysis

```
Stage          | Cycles | Cumulative
---------------+--------+-----------
Feature scaling|      2 |          2
DT traversal   |     12 |         14  ← parallel with AE
AE forward pass|     38 |         40  (DT done at cycle 14)
Fusion logic   |      1 |         41
Output          |      1 |         42
Pipeline fill  |     12 |         54  (first result after 54 cy)
Throughput     |      1 cycle/flow (pipelined)
```

At 100 MHz: **540 ns** to first result, then **10 ns per flow** (pipelined).

## Comparison with Software Inference

| Implementation | Latency | Throughput |
|----------------|---------|------------|
| Python (host CPU) | ~0.5-2 ms | ~500-2000 flows/s |
| FPGA HLS (Pynq-Z2) | ~540 ns | ~100M flows/s (pipelined) |
| Speedup | ~1000-4000x | ~100,000x |

## Implementation Notes

1. **DT Traversal**: Iterative, not recursive. Fixed maximum depth=16 loop.
   Unrolled inner feature comparison. BRAM for node storage.

2. **AE Weights**: Quantised to AP_FIXED<8,4> (Q4.4) for BRAM density.
   Minimal accuracy loss (<0.5% AUC) measured in Python simulation.

3. **Fusion Logic**: Pure combinational (1 cycle). No BRAM needed.
   Three-way mux based on dt_confident and ae_anomaly signals.

4. **Feature Scaler**: StandardScaler precomputed as FPGA constants.
   16-bit fixed-point arithmetic sufficient for normalised features.

5. **Pynq-Z2 Integration**: PS (ARM Cortex-A9) handles:
   - Model weight loading at boot
   - Threshold configuration
   - Alert logging to SD card
   PL (Zynq XC7Z020) handles:
   - Real-time flow classification at line rate
   - DT + AE + Fusion pipeline
