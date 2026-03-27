# PRAHARI-Lite

Lightweight full-FPGA-implementable hybrid IDS.
**Completely isolated from PRAHARI v7 at `../docker_env/`**

## Architecture

```
Flow Packets
     │
     ▼
┌──────────────────────────────────────────────────────────────┐
│                     PRAHARI-Lite Pipeline                    │
│                                                              │
│  15 features   ┌──────────────┐   DT pred + purity          │
│  ──────────►  │  Decision    │──────────────────────┐        │
│               │  Tree (d=12) │                      │        │
│               └──────────────┘                      ▼        │
│                                             ┌──────────────┐ │
│  15 features   ┌──────────────┐   AE error  │    Fusion    │ │
│  ──────────►  │  Autoencoder │────────────►│    Logic     │ │
│               │ 15-8-4-8-15  │             │  (Purity Gate│ │
│               └──────────────┘             └──────┬───────┘ │
│                                                   │          │
└───────────────────────────────────────────────────┼──────────┘
                                                    │
                                                    ▼
                              ┌─────────────────────────────────┐
                              │  Final Decision                  │
                              │  ● DT confident  → DT label     │
                              │  ● AE anomaly    → ZERO_DAY     │
                              │  ● Low conf+norm → DT label     │
                              └─────────────────────────────────┘
```

## Port Assignments

| Service                  | Port |
|--------------------------|------|
| PRAHARI v7 API           | 5000 |
| PRAHARI-Lite API         | 5001 |
| PRAHARI-Lite Dashboard   | 5002 |
| PRAHARI v7 Signal Centre | 6060 |

## Novel Contribution

**DT leaf purity as confidence gate for zero-day routing:**

Traditional DT classification returns a label regardless of confidence.
PRAHARI-Lite uses the purity of the predicted leaf node as a confidence
proxy. If leaf purity < threshold (default 0.70), the DT is "uncertain"
and the AE reconstruction error is consulted.

- If AE error > threshold → **ZERO_DAY** (novel anomaly)
- If AE error <= threshold → accept low-confidence DT prediction

This enables detection of unseen attack classes without explicit labels,
validated by the LOCO experiment.

## Quick Start

### 1. Training (run in order)

```bash
cd /Users/deepakkumaryadav/ids_project/prahari_lite

python training/train_decision_tree.py
python training/train_autoencoder.py
python training/validate_lite.py
```

### 2. Experiments

```bash
python experiments/loco_experiment.py
python experiments/leaf_purity_analysis.py
python experiments/compare_prahari_vs_lite.py
```

### 3. Start Servers

```bash
# IDS API server (port 5001)
python runtime/ids_lite_server.py &

# Dashboard (port 5002)
python dashboard/dashboard_lite.py &
```

### 4. Test

```bash
# Quick test
curl http://localhost:5001/health

# Full validation
python runtime/local_lab_validate_lite.py
```

### 5. Docker (optional)

```bash
docker-compose -f docker-compose-lite.yml up -d
```

## Directory Structure

```
prahari_lite/
├── training/
│   ├── train_decision_tree.py   # DT trainer (depths 6-15)
│   ├── train_autoencoder.py     # AE trainer (15-8-4-8-15)
│   ├── validate_lite.py         # Fusion validation
│   └── quantise_models.py       # FP32→FP16 quantisation
├── experiments/
│   ├── loco_experiment.py       # Leave-one-class-out
│   ├── leaf_purity_analysis.py  # Purity plots
│   └── compare_prahari_vs_lite.py
├── runtime/
│   ├── ids_lite_server.py       # Flask API (port 5001)
│   ├── local_lab_validate_lite.py
│   └── prahari_lite_logger.py   # Isolated logger
├── dashboard/
│   ├── dashboard_lite.py        # Flask dashboard (port 5002)
│   ├── templates/dashboard_lite.html
│   └── static/lite.css
├── fpga/
│   ├── hls/
│   │   ├── dt_inference.cpp
│   │   ├── ae_inference.cpp
│   │   ├── fusion_logic.cpp
│   │   └── prahari_lite_top.cpp
│   └── notes/resource_estimates.md
├── models/
│   ├── scaler_lite_v1.pkl       # Copied from v7, NOT refitted
│   ├── dt_lite_v1.pkl           # Trained DT
│   ├── ae_lite_v1.pkl           # Trained AE (fp32)
│   └── ae_lite_v1_quantised.pkl # AE fp16
├── outputs/
│   ├── dt_depth_comparison.csv
│   ├── leaf_purity_distribution.csv
│   ├── dt_confidence_threshold.json
│   ├── ae_threshold.json
│   ├── ae_error_distributions.csv
│   ├── loco_results.csv
│   ├── validation_lite_results.csv
│   └── *.png (charts)
├── docs/
│   ├── experiment_log_lite.md
│   ├── experiment_log_lite.json
│   └── architecture_decision.md
├── requirements_lite.txt
├── docker-compose-lite.yml
├── Dockerfile.lite
└── prahari_lite_commit.sh
```

## PRAHARI v7 Safety

This project **DOES NOT** modify `../docker_env/` in any way.
- The scaler was **copied** (not symlinked) to `models/scaler_lite_v1.pkl`
- No imports from `../docker_env/` anywhere in the codebase
- Separate ports: 5001/5002 vs v7's 5000/6060
- Separate Docker network: `prahari_lite_network` vs `ids_net`
- Separate logger writing to `docs/experiment_log_lite.{md,json}`

## Features Used (15 of 31)

Selected by PRAHARI v7's FPGA cost-weighted ranking:

| Feature | Description | FPGA Cost |
|---------|-------------|-----------|
| dst_port | Destination port | 1 (counter) |
| fwd_bytes | Total fwd bytes | 1 (accumulator) |
| init_win_bwd | Init backward window | 1 (first-packet) |
| init_win_fwd | Init forward window | 1 (first-packet) |
| bwd_bytes | Total bwd bytes | 1 (accumulator) |
| fwd_seg_min | Min fwd segment size | 2 (running min) |
| fwd_pkt_mean | Mean fwd packet length | 3 (Welford online) |
| flow_iat_min | Min flow IAT | 2 (running min) |
| duration | Flow duration | 1 (timer) |
| flow_byts_s | Bytes per second | 2 (ratio) |
| avg_pkt_size | Average packet size | 3 (Welford online) |
| bwd_pkt_max | Max bwd packet | 2 (running max) |
| bwd_pkts | Backward packet count | 1 (counter) |
| syn_flag | SYN flag count | 1 (flag counter) |
| pkt_len_mean | Mean packet length | 3 (Welford online) |

## API Reference

### POST /detect

Request body (all 15 features required):
```json
{
  "dst_port": 443,
  "fwd_bytes": 5000,
  ...
}
```

Response:
```json
{
  "final_label": "NORMAL",
  "dt_label": "NORMAL",
  "dt_purity": 0.95,
  "dt_confident": true,
  "ae_error": 0.012,
  "ae_anomaly": false,
  "routing": "DT_CONFIDENT",
  "is_attack": false,
  "is_zero_day": false
}
```

### GET /health

Returns server status, model info, uptime.

### GET /stats

Returns total flows, attacks, zero-day alerts, class counts, routing breakdown.

### GET /recent_alerts?n=50

Returns last N alert records (newest first).
