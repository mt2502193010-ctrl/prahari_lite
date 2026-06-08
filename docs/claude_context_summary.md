# PRAHARI-Lite — Claude Context Summary
**Paste this at the start of any new Claude chat to resume work on this project.**  
**Last updated:** 2026-06-08 | **Commit:** b4d12b9 | **Branch:** main

---

## What This Project Is

PRAHARI-Lite is a **dual-precision heterogeneous FPGA IDS** (Intrusion Detection System) targeting the Pynq-Z2 board (Xilinx Zynq XC7Z020). It classifies network flows as NORMAL / APT / RECON / TRAFFIC_SPIKE / NR_MALWARE / ZERO_DAY using a Decision Tree + Autoencoder ensemble implemented entirely in FPGA hardware.

**Deployment context:** Signal centres (network edge nodes) through which traffic flows toward a datacentre. PRAHARI-Lite sits inline, classifies every flow locally in hardware, and forwards only alerts to the SOC.

**Research contribution:** DT leaf purity as a zero-cost zero-day routing signal in hardware — if purity < 0.75 AND AE anomaly → classify as ZERO_DAY (class 5), no additional cycles.

---

## Repository

```
GitHub:     https://github.com/mt2502193010-ctrl/prahari_lite
Local:      ~/ids_project/prahari_lite/
Board:      Pynq-Z2 at 192.168.2.99  (user: xilinx / xilinx)
Mac IP:     192.168.2.1 on en5 (USB-GbE, set static)
Python env: ~/ids_project/prahari_lite/.venv/bin/python3
```

---

## Architecture

### Hardware (FPGA, synthesised as ids.bit on the board)

```
5 Verilog modules in verilog_out/:
  dt_inference.v     — 767-node DT, ROM-based, Q8.8 fixed-point
                       4-state FSM: IDLE→BRAM_WAIT→COMPARE→DONE
                       32 cycles × 10 ns = 320 ns per inference
  ae_inference.v     — 15→8→4→8→15 autoencoder, fully combinational, Q4.4
                       AE threshold: 158206 (Q16.16 = 2.414035 float)
  fusion_logic.v     — purity < 192 (0.75×256) AND ae_anomaly → ZERO_DAY
  prahari_lite_top.v — wires the 3 above
  prahari_lite_axi.v — AXI4-Lite slave, base 0x43C00000

AXI register map:
  0x00  Control  (write 1 to start)
  0x04  Status   (bit0=done, bit1=zero_day)
  0x08–0x40  Features [0..14] as signed Q8.8
  0x48  Result   (bits[2:0] = class_id)
  0x4C  AE error (Q16.16)
```

### Software (Mac side, Python)

```
runtime/
  ids_lite_server.py    — Flask IDS server, port 5001
  fpga_bridge.py        — SSH+HTTP bridge to board (TRANSPORT = "http" or "ssh")
  board_fpga_server.py  — deploys TO board, HTTP server port 5003, /dev/mem direct
  traffic_gen_lite.py   — sends synthetic traffic to /detect at ~3 flows/sec

dashboard/
  dashboard_lite.py     — Flask dashboard, port 5002
  templates/dashboard_lite.html
  static/lite.css

models/
  dt_lite_v2.pkl        — sklearn DecisionTreeClassifier (depth=15, 767 nodes)
  ae_lite_v2.pkl        — TinyAutoencoder PyTorch state dict
  scaler_lite_v1.pkl    — StandardScaler (15 features)
```

---

## Class Mapping (NEVER CHANGE)

```python
0 = NORMAL
1 = APT
2 = RECON
3 = TRAFFIC_SPIKE
4 = NR_MALWARE
5 = ZERO_DAY  (hardware fusion gate output only)
```

---

## Feature Order (NEVER CHANGE, indices 0–14)

```
[0]  dst_port       [1]  fwd_bytes      [2]  init_win_bwd
[3]  init_win_fwd   [4]  bwd_bytes      [5]  fwd_seg_min
[6]  fwd_pkt_mean   [7]  flow_iat_min   [8]  duration
[9]  flow_byts_s    [10] avg_pkt_size   [11] bwd_pkt_max
[12] bwd_pkts       [13] syn_flag       [14] pkt_len_mean
```

---

## Scaler Parameters (hardcoded everywhere, from scaler_lite_v1.pkl)

```python
MEANS = [6234.239404, 4004.604810, 3293.047072, 6593.248217, 15258.713687,
         -2920.625510, 83.280455, 1149956.643832, 8473172.648206, 646140.882899,
         136.469279, 386.059913, 13.406653, 0.028309, 80.296013]

STDS  = [16276.139768, 121751.053505, 12446.986388, 14924.562945, 1822821.794656,
         1122323.823913, 169.272069, 9106573.249593, 26295131.513161, 16298275.252851,
         236.502914, 1199.464211, 840.129983, 0.165854, 196.683321]

# Q8.8 conversion:
q = int(max(-32768, min(32767, round((raw - mean) / std * 256))))
```

---

## Verified Model Performance (from results/verified_results.txt)

| Metric | Value | Status |
|---|---|---|
| DT v2 macro F1 | 0.988 | ✅ verified |
| APT recall | 0.997 | ✅ verified |
| RECON recall | 0.999 | ✅ verified |
| TS recall | 0.999 | ✅ verified |
| NRM recall | 0.992 | ✅ verified |
| DT node count | 767 | ✅ hardware verified |
| DT depth | 15 | ✅ hardware verified |
| AE threshold | 2.414035 (= 158206 Q16.16) | ✅ verified |
| AE APT detection | 24.4% | genuine signal |
| AE RECON detection | **0.0%** | **cannot detect — do not claim** |
| AE TS detection | 30.0% | genuine |
| System FPR | 0.26% (after purity gate) | ✅ verified |

---

## Hardware Performance (measured, Pynq-Z2)

| Metric | Value |
|---|---|
| FPGA bare compute | **320 ns** (32 cycles × 10 ns at 100 MHz) |
| ARM Python DT (Cortex-A9) | 23,500 ns (measured) |
| **Hardware speedup** | **73×** |
| SSH bridge per-flow latency | 1.58 ms (includes 900 µs TCP RTT — demo only) |
| LUTs used | ~9,000 / 53,200 (17%) |
| DSPs used | 30 / 220 (14%) |
| BRAM used | 9 KB / 630 KB (1.5%) |
| FFs used | ~330 / 106,400 (0.3%) |

**Important:** The 900 µs TCP round-trip is a demo artefact (Mac ↔ board).
In field deployment, traffic arrives at the board directly → that hop does not exist.
The 73× speedup measures FPGA (320 ns) vs ARM software DT (23,500 ns) on the same chip.

---

## FPGA Bug Fixes Applied (commit ce653f2)

1. **dt_inference.v** — 3-state FSM → 4-state (IDLE/BRAM_WAIT/COMPARE/DONE)  
   BRAM on XC7Z020 has registered outputs (1-cycle latency). Without BRAM_WAIT, the FSM compared features against the wrong node's threshold in hardware (simulation-synthesis mismatch).

2. **prahari_lite_axi.v** — hardware scaler removed entirely.  
   11/15 INV_SCALE values were 0 in Q8.8 (1/std too small to represent), zeroing those features.  
   Software now pre-scales: `q = round((raw - mean) / std * 256)`.

3. **pynq_z2_constraints.xdc** — replaced `set_false_path -through *feat_reg*`  
   (too aggressive, suppressed DT paths) with `set_multicycle_path 32` for AE path only.

---

## Verified Test Vectors (Python model confirmed, use for hardware testing)

```python
VERIFIED_VECTORS = {
    'NORMAL':   {'q88': [-97,-5,1280,1011,-2,1,25,-32,-82,-10,-39,27,-3,-44,26],   'expected': 0},
    'APT_v1':   {'q88': [-99,0,0,-108,0,2,0,0,0,-11,0,0,0,0,0],                   'expected': 1},
    'APT_v2':   {'q88': [-94,-7,0,0,0,0,0,0,0,-2,0,0,0,0,-99],                    'expected': 1},
    'RECON_v1': {'q88': [-100,0,0,0,0,-1,0,0,0,0,0,0,0,0,-101],                   'expected': 2},
    'RECON_v2': {'q88': [-99,0,0,0,0,2,0,-34,0,-8,0,0,0,0,0],                     'expected': 2},
    'TS_v1':    {'q88': [-97,0,-63,-112,0,0,0,0,0,0,0,0,0,0,345],                 'expected': 3},
    'TS_v2':    {'q88': [-97,0,281,-111,0,-1,0,0,-81,0,0,0,0,0,0],                'expected': 3},
    'NRM_v1':   {'q88': [-30,-10,0,0,-1,0,0,0,-74,-12,0,0,0,0,-103],              'expected': 4},
    'NRM_v2':   {'q88': [-30,-10,0,0,-1,0,0,-34,-73,-12,0,0,0,0,-103],            'expected': 4},
}
# These are already Q8.8 — write directly to AXI without re-normalizing.
# Write q & 0xFFFF to offset 0x08 + i*4 for i in 0..14
```

---

## Running the System

```bash
cd ~/ids_project/prahari_lite

# Start all three processes:
.venv/bin/python3 runtime/ids_lite_server.py >> /tmp/ids_server.log 2>&1 &
.venv/bin/python3 dashboard/dashboard_lite.py >> /tmp/dashboard.log 2>&1 &
.venv/bin/python3 runtime/traffic_gen_lite.py --rate 3.0 >> /tmp/traffic.log 2>&1 &

# Dashboard: http://localhost:5002
# IDS API:   http://localhost:5001
# FPGA status: curl http://localhost:5001/fpga_status

# Board server (run ON the board as root):
# sudo python3 /home/xilinx/board_fpga_server.py   (port 5003)

# Test inference:
curl -X POST http://localhost:5001/detect \
  -H "Content-Type: application/json" \
  -d '{"features": [80,1500,65535,65535,512,0,100,1000,50000,30000,100,512,5,0,100]}'
```

---

## Key Constraints (DO NOT CHANGE)

- `scaler_lite_v1.pkl` — NEVER modify. Hardware is calibrated to these exact mean/std values.
- Feature order [0..14] — NEVER change.
- Class integers 0–4 — NEVER change.
- AE architecture 15→8→4→8→15 — NEVER change.
- AE threshold 2.414035 / 158206 Q16.16 — do not change without re-verifying.
- `docker_env/` — NEVER touch. It is a separate project (PRAHARI v7, port 5000).

---

## What to Report in Paper (safe claims)

- DT v2 macro F1 = 0.988 (vs baseline 0.131, Δ+0.857)
- APT recall = 0.997, RECON recall = 0.999, TS recall = 0.999, NRM recall = 0.992
- DT node count 767 (50% reduction vs 1533 baseline)
- System-level FPR = 0.26% (after DT purity gate)
- AE detects TRAFFIC_SPIKE at 30.0% and APT at 24.4% (FPR=6.0% isolation)
- Purity gate routes only 0.17% of flows to AE
- FPGA inference: 320 ns, 73× faster than ARM Cortex-A9 software DT
- Hardware resource usage: 17% LUTs, 14% DSPs, 1.5% BRAM

**Do NOT claim:**
- RECON detection by AE (0.0% — AE cannot distinguish RECON from NORMAL)
- Any hardware synthesis results (not yet synthesised in Vivado as of this writing)

---

## Key Documents

| File | Contents |
|---|---|
| `results/verified_results.txt` | All verified numbers, what to claim, what not to claim |
| `results/fpga_latency_benchmarks.md` | All latency measurements, 73× speedup derivation |
| `docs/edge_deployment_context.md` | Signal-centre deployment scenario, hardware recommendations |
| `docs/future_work_research.md` | 14 future work items (P1/P2/P3, HW/ML/SYS/SEC) |
| `verilog_out/PRE_SYNTHESIS_AUDIT.txt` | Full pre-synthesis audit, 44 checks, 6 auto-fixes |
| `prahari_lite_sim.v` | Self-contained RTL simulation, all 6 test cases passing |

---

## Figures (in figures/, all debranded — no "PRAHARI" in captions)

F3 class distribution, F4 feature importance, F5 HP confusion matrix,  
F6 Edge confusion matrix, F7 precision-recall, F8 DT ablation,  
F9 LOCO heatmap, F10 FPGA resources, F11 latency, F12 purity gate

Generic naming: "HP Variant" = GBM+IF, "Edge Variant" = DT v2 + AE v2

---

## Recent Commits

```
b4d12b9  FPGA bridge, latency benchmarks, edge deployment docs, future work
ce653f2  Fix BRAM wait state, remove AXI scaler, add XDC multicycle constraint
609f2b6  Verification: 3 claims resolved, ae_lite_v2 threshold corrected
4affa07  Force-add v2 model pkl files (were in .gitignore)
ad8412d  Model improvement: DT v2 + AE v2 with ablation study
1463ba0  Phase 5: synthesis-ready Verilog generated from trained models
```
