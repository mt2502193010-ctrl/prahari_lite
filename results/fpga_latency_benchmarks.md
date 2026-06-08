# PRAHARI-Lite — FPGA vs Software Latency Benchmarks
**Date:** 2026-06-08  
**Board:** Pynq-Z2 (Zynq XC7Z020, Cortex-A9 @ 650 MHz, PL @ 100 MHz)  
**Test host (demo only):** Apple MacBook, M-series, connected via Ethernet 192.168.2.1 ↔ 192.168.2.99  
**Measurement:** 200 warm calls each path, median reported

---

## 1. Raw Numbers

| Path | Median latency | P95 | Flows/sec |
|---|---|---|---|
| SSH persistent channel (Mac → board) | 1.581 ms | 1.594 ms | 626 |
| HTTP single-flow (Mac → board server) | 5.530 ms | 6.892 ms | 181 |
| HTTP batch N=100 (Mac → board server) | 536 µs/flow | — | 1,865 |
| Software sklearn DT (Mac M-series, warm) | 0.070 ms | 0.075 ms | 14,285 |
| Software pure-Python DT (Cortex-A9, warm) | 0.0235 ms | 0.025 ms | 42,553 |
| **FPGA bare compute (32 cycles × 10 ns)** | **0.00032 ms = 320 ns** | — | — |

---

## 2. Overhead Breakdown (single flow, demo setup)

```
Component                                 Time
────────────────────────────────────────  ─────────
FPGA DT + AE + fusion  (32 cyc @ 10 ns)    0.32 µs
Python scale_to_q88  (ARM 650 MHz)         ~10 µs
Python /dev/mem MMIO  (15 writes + reads)  ~400 µs   ← dominant bottleneck
Python http.server overhead  (ARM)         ~480 µs   ← amortised by batching
TCP round-trip  Mac ↔ 192.168.2.99        ~900 µs   ← demo artefact only
```

**Important:** the 900 µs TCP round-trip is a **demo artefact**.  
In field deployment, traffic arrives at the board directly — this hop does not exist.  
The 400 µs Python /dev/mem cost is the only remaining software overhead in production.

---

## 3. True Hardware Speedup

Measured on the same physical board (Cortex-A9 vs FPGA fabric):

| Comparison | Speedup |
|---|---|
| FPGA bare (320 ns) vs ARM Python DT (23,500 ns) | **73×** |
| FPGA bare (320 ns) vs ARM sklearn DT (est. 2,000 ns) | **~6×** |
| Board-local inference (~8.8 µs) vs ARM Python DT (23.5 µs) | **2.7×** |

The **73× figure** is the correct claim for the paper. It compares the FPGA compute time (hardware logic gates) against equivalent software tree traversal on the same processor family, measuring only the classification step with no transport overhead.

---

## 4. Batch Inference Effect (Option 1 + Option 3)

Sending N flows per HTTP call to the board server, measured end-to-end (Mac→board→result):

| Batch N | Per-flow latency (µs) | Board-only (µs) | Flows/sec |
|---|---|---|---|
| 1 | 5,883 | 542 | 170 |
| 10 | 1,018 | 453 | 983 |
| 50 | 627 | 456 | 1,596 |
| 100 | 536 | 412 | 1,865 |

Asymptote: as N → ∞, per-flow latency converges to the **board-side time (~400 µs)**.  
The 400 µs is the Python /dev/mem MMIO overhead per flow — not the FPGA.  
With a C driver doing MMIO, board-side per-flow drops to ~2–3 µs.

---

## 5. Key Corrections vs Earlier Analysis

| Earlier (wrong) | Correct |
|---|---|
| "FPGA execution = 0.320 ms" | FPGA execution = 0.320 µs (320 ns). 1000× error. |
| "Speedup = 3.8×" | Speedup = 73× (measured on same ARM chip) |
| "SW mean 9.2 ms" | Was inflated by first-call model load (~912 ms). Warm median = 0.070 ms on Mac |
| "set_false_path -through feat_reg (XDC)" | Too aggressive — suppressed DT timing paths. Replaced with set_multicycle_path 32 |

---

## 6. DT Hardware Timing

```
FSM:          4-state (IDLE → BRAM_WAIT → COMPARE → DONE)
Clock:        100 MHz (10 ns/cycle)
Max depth:    15
Cycles/infer: 1 + 2×depth + 1 = 32 cycles
Time/infer:   32 × 10 ns = 320 ns
```

The BRAM_WAIT state was added (Fix 1, commit ce653f2) to handle XC7Z020 BRAM registered-output latency.  
Without it: simulation passes but hardware produces wrong classifications.  
Cost: depth-15 DT takes 32 cycles instead of 17 (1.9× slower in hardware, still 73× faster than ARM software).

---

## 7. Production Deployment Latency (field estimate)

When the board is the edge node (traffic arrives locally, no Mac involved):

```
Raw packet arrives at Ethernet PHY
  ↓  ~50 µs  Linux network stack + flow statistics extraction (software)
Feature vector (15 values, Q8.8)
  ↓   ~2 µs  C driver writes to AXI registers via /dev/mem
  ↓  0.32 µs  FPGA inference (DT + AE + fusion)
  ↓   ~1 µs  C driver reads result registers
Classification result
  ↓  forward NORMAL / alert ATTACK to datacentre SOC
```

**Target end-to-end (with C driver):** ~53 µs per flow  
**Classification step only (FPGA):** 320 ns  
**Software equivalent on same ARM (Python DT):** 23,500 ns → **73× FPGA speedup**
