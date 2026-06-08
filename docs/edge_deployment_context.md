# PRAHARI-Lite — Edge Deployment Context
**Last updated:** 2026-06-08

---

## Deployment Scenario

PRAHARI-Lite is deployed at **signal centres** — edge network nodes through which traffic flows toward a central datacentre or ISP backbone. Each signal centre sits at a network aggregation point and must classify traffic locally before forwarding it upstream.

```
[Field devices / users]
        ↓
[Signal centre — Pynq-Z2 running PRAHARI-Lite]   ← deployment point
        ↓  NORMAL traffic passes through
        ↓  ATTACK alerts forwarded to SOC
[Datacentre / SOC]
```

This means:
- The MacBook in the development demo is **not part of production**. It was only the test harness.
- In production, traffic arrives at the board's Ethernet interface directly.
- Classification must complete before the packet is forwarded — latency budget is tight.
- The 900 µs demo network round-trip does **not exist** in field deployment.

---

## Why FPGA at the Edge

| Requirement | CPU (ARM) | FPGA |
|---|---|---|
| Deterministic latency | No (OS scheduling jitter) | Yes (fixed cycle count) |
| Power consumption | ~2–4 W active | ~0.5–1 W for PL inference |
| Classification speed | 23,500 ns (Python DT) | 320 ns (hardware) |
| Operates without OS | No | Yes (PL runs independently) |
| No model IP exposure | No (weights in RAM) | Partially (bitstream encrypted) |
| Fail-open under load | Risky | Yes (hardware pipeline never stalls) |

---

## Current Hardware: Pynq-Z2 (Development)

| Parameter | Value |
|---|---|
| FPGA | Xilinx Zynq XC7Z020 |
| ARM | Dual Cortex-A9 @ 650 MHz |
| BRAM | 630 KB (9 KB used by DT ROM) |
| LUTs | 53,200 (15–22% used) |
| DSPs | 220 (14% used) |
| PL clock | 100 MHz |
| Interface | AXI4-Lite slave at 0x43C00000 |
| Form factor | Development board — not field-hardened |

---

## Recommended Production Hardware

### Primary: AMD/Xilinx Kria K26 SOM

The natural production successor to Pynq-Z2 for signal centre deployment.

| Parameter | Pynq-Z2 | Kria K26 |
|---|---|---|
| FPGA family | Zynq-7000 | Zynq UltraScale+ |
| ARM cores | 2× Cortex-A9 @ 650 MHz | 4× Cortex-A53 @ 1.3 GHz |
| RAM | 512 MB DDR3 | 4 GB LPDDR4 |
| Temperature | 0–70°C (commercial) | −40°C to +100°C (industrial) |
| Network I/O | 10/100/1000 BaseT | SFP+ (1/10 GbE fibre) |
| Power | ~5 W | ~8 W |
| Form factor | Dev board | SOM (fits custom carrier) |
| RTL compatibility | Baseline | Requires re-targeting to UltraScale+ |

No RTL logic changes required — the DT, AE, and fusion modules are standard Verilog-2001. Re-synthesis targets the larger fabric.

### For higher-throughput signal centres (10G/40G links):

**AMD Versal AI Edge Series** — integrates FPGA fabric + dedicated AI Engine tiles.  
The AE (autoencoder) anomaly detector runs in the AI Engine while the DT runs in programmable logic simultaneously, eliminating the sequential DT→AE dependency entirely.  
Requires re-targeting synthesis and potentially restructuring the AE layer.

### For ultra-low-power deployments (sub-1G traffic, remote sites):

**Xilinx Spartan-7 or Artix-7 based appliance** — drop the AE (move anomaly detection to cloud), keep only the DT classification core. Power envelope drops to ~1–2 W. Suitable for battery-backed or solar-powered edge nodes.

---

## Production Latency Budget (field estimate, with C driver)

```
Raw packet → Linux network stack + feature extraction:  ~50 µs
Feature vector → C AXI driver → FPGA registers:          ~2 µs
FPGA inference (DT + AE + fusion @ 100 MHz):            0.32 µs
Result register read → classification decision:          ~1 µs
──────────────────────────────────────────────────────────────
Total classification latency:                          ~53 µs
FPGA compute fraction:                                  0.6%
```

The bottleneck is Linux network stack and software feature extraction (~50 µs), not the FPGA.  
Moving feature extraction into FPGA logic (future work) reduces this to sub-microsecond end-to-end.

---

## Verified Speedup (for paper/thesis)

**73×** — FPGA bare compute (320 ns) vs equivalent software DT on the same Cortex-A9 (23,500 ns).  
Measured on Pynq-Z2 board. No simulation. No extrapolation.

This is the correct figure for the paper because it:
- Compares the same algorithm (DT traversal, 767 nodes, depth 15)
- On the same physical chip family (Zynq = ARM + FPGA on one die)
- Without transport overhead in either case
- Using real measured values, not estimates
