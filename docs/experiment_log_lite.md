# PRAHARI-Lite Experiment Log

*Append-only. Each run adds a new section.*
*Isolated from PRAHARI v7 at ../docker_env/*

---

## prahari_lite Run: train_decision_tree (v1) — 2026-03-28 05:50:41 UTC
**Git:** `389c3ab` | **Python:** 3.14.3 | **Host:** Deepaks-MacBook-Air.local | **Env:** venv:3.14

### Setup
- **Decision:** Use prahari_lite isolated training — _Completely separate from v7_

### Data
- **data_source:** real
- **total_rows:** 15047
- **class_distribution:** {"TRAFFIC_SPIKE": 7500, "APT": 3047, "NORMAL": 1500, "NR_MALWARE": 1500, "RECON": 1500}

### Training
- **depth_6_f1:** 0.971
- **depth_6_bram_kb:** 0.45
- **depth_8_f1:** 0.9733
- **depth_8_bram_kb:** 0.66
- **depth_10_f1:** 0.9752
- **depth_10_bram_kb:** 0.77
- **depth_12_f1:** 0.9759
- **depth_12_bram_kb:** 0.95
- **depth_15_f1:** 0.9811
- **depth_15_bram_kb:** 1.18

### Results
- **best_depth:** 15
- **f1_test:** 0.9839
- **fpr_test:** 0.05
- **bram_kb:** 1.18
- **confidence_threshold:** 0.9977
- **n_leaves:** 81
- [PASS] F1 >= 0.80 (0.9839)
- [PASS] BRAM < 25KB (1.1841)
- `models/dt_lite_v1.pkl` (SHA256: `b1a3540ef5b0...`) — DT depth=15
- `outputs/dt_depth_comparison.csv` (SHA256: `b87188c9ef10...`)
- `outputs/leaf_purity_distribution.csv` (SHA256: `7504f5743372...`)
- `outputs/dt_confidence_threshold.json` (SHA256: `c4beaed035cb...`)

### Artifacts
- `models/dt_lite_v1.pkl` (17.7 KB) SHA256: `b1a3540ef5b0...` — DT depth=15
- `outputs/dt_depth_comparison.csv` (0.3 KB) SHA256: `b87188c9ef10...`
- `outputs/leaf_purity_distribution.csv` (1.8 KB) SHA256: `7504f5743372...`
- `outputs/dt_confidence_threshold.json` (0.3 KB) SHA256: `c4beaed035cb...`

---

## prahari_lite Run: train_autoencoder (v1) — 2026-03-28 05:50:52 UTC
**Git:** `389c3ab` | **Python:** 3.14.3 | **Host:** Deepaks-MacBook-Air.local | **Env:** venv:3.14

### Setup
- **Decision:** Train AE on NORMAL only — _Anomaly detection philosophy_

### Results
- **threshold:** 1.564258
- **best_val_loss:** 0.688474
- `models/ae_lite_v1.pkl` (SHA256: `ba82733a1792...`) — AE 15-8-4-8-15 fp32
- `models/ae_lite_v1_quantised.pkl` (SHA256: `6c576df24214...`) — AE fp16 quantised

### Artifacts
- `models/ae_lite_v1.pkl` (4.8 KB) SHA256: `ba82733a1792...` — AE 15-8-4-8-15 fp32
- `models/ae_lite_v1_quantised.pkl` (4.1 KB) SHA256: `6c576df24214...` — AE fp16 quantised

---

## prahari_lite Run: train_decision_tree (v1) — 2026-03-28 06:12:31 UTC
**Git:** `1f60cd8` | **Python:** 3.14.3 | **Host:** Deepaks-MacBook-Air.local | **Env:** venv:3.14

### Setup
- **Decision:** Use prahari_lite isolated training — _Completely separate from v7_

### Data
- **data_source:** real
- **total_rows:** 350000
- **class_distribution:** {"NORMAL": 255968, "APT": 34579, "TRAFFIC_SPIKE": 31883, "NR_MALWARE": 17877, "RECON": 9693}

### Training
- **depth_6_f1:** 0.6693
- **depth_6_bram_kb:** 0.61
- **depth_8_f1:** 0.7425
- **depth_8_bram_kb:** 1.3
- **depth_10_f1:** 0.7654
- **depth_10_bram_kb:** 2.84
- **depth_12_f1:** 0.7791
- **depth_12_bram_kb:** 5.2
- **depth_15_f1:** 0.7848
- **depth_15_bram_kb:** 11.23

### Results
- **best_depth:** 15
- **f1_test:** 0.7888
- **fpr_test:** 0.0475
- **bram_kb:** 11.23
- **confidence_threshold:** 0.9618
- **n_leaves:** 767
- [FAIL] F1 >= 0.80 (0.7888)
- [PASS] BRAM < 25KB (11.2329)
- `models/dt_lite_v1.pkl` (SHA256: `dabaabd3b615...`) — DT depth=15
- `outputs/dt_depth_comparison.csv` (SHA256: `2170e7a5ff0f...`)
- `outputs/leaf_purity_distribution.csv` (SHA256: `78723178211a...`)
- `outputs/dt_confidence_threshold.json` (SHA256: `71cfe4278d14...`)

### Artifacts
- `models/dt_lite_v1.pkl` (157.0 KB) SHA256: `dabaabd3b615...` — DT depth=15
- `outputs/dt_depth_comparison.csv` (0.4 KB) SHA256: `2170e7a5ff0f...`
- `outputs/leaf_purity_distribution.csv` (22.7 KB) SHA256: `78723178211a...`
- `outputs/dt_confidence_threshold.json` (0.3 KB) SHA256: `71cfe4278d14...`

---

## prahari_lite Run: train_autoencoder (v1) — 2026-03-28 06:12:45 UTC
**Git:** `1f60cd8` | **Python:** 3.14.3 | **Host:** Deepaks-MacBook-Air.local | **Env:** venv:3.14

### Setup
- **Decision:** Train AE on NORMAL only — _Anomaly detection philosophy_

### Results
- **threshold:** 2.408013
- **best_val_loss:** 1.342997
- `models/ae_lite_v1.pkl` (SHA256: `ac8cddf71fa9...`) — AE 15-8-4-8-15 fp32
- `models/ae_lite_v1_quantised.pkl` (SHA256: `799074b8ddee...`) — AE fp16 quantised

### Artifacts
- `models/ae_lite_v1.pkl` (4.8 KB) SHA256: `ac8cddf71fa9...` — AE 15-8-4-8-15 fp32
- `models/ae_lite_v1_quantised.pkl` (4.1 KB) SHA256: `799074b8ddee...` — AE fp16 quantised
