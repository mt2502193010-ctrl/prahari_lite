# PRAHARI-Lite Architecture Decision

## Why DecisionTree + Autoencoder instead of GBM + IsolationForest?

### The FPGA Constraint

PRAHARI v7 uses HistGradientBoostingClassifier (500 trees) and IsolationForest.
A 500-tree GBM requires approximately 50,000+ LUTs to implement in hardware —
nearly the entire Pynq-Z2 FPGA fabric (53,200 LUTs available).

PRAHARI-Lite targets full FPGA implementability in <4% of available resources.

### Component Comparison

| Aspect | PRAHARI v7 | PRAHARI-Lite | Rationale |
|--------|-----------|--------------|-----------|
| Classifier | GBM (500 trees) | Decision Tree (d=12) | DT: ~800 LUTs vs GBM: ~50K+ LUTs |
| Anomaly Detector | Isolation Forest | Autoencoder (15-8-4-8-15) | AE: deterministic forward pass, HLS-friendly |
| BRAM Usage | ~640 KB | <25 KB | 25x reduction |
| FPGA Native | No (Docker only) | Yes (Pynq-Z2) | Core design goal |
| Features | 31 | 15 | FPGA cost-weighted pruning |
| Zero-day Method | IF score threshold | DT leaf purity + AE | Novel: purity as confidence |
| Latency | 2.06 ms (SW) | ~0.54 us (HW, 54 cycles @ 100MHz) | 3800x speedup (HW) |

### Novel Contribution: Leaf Purity Confidence Gate

Standard DT classification returns a label with no confidence information.
PRAHARI-Lite exploits the leaf purity (fraction of training samples with the
dominant label) as a built-in confidence measure:

```
purity(leaf) = max(class_count) / total_samples_in_leaf
```

**Decision logic:**
1. If `purity >= threshold (0.70)` → DT is confident, accept its label
2. If `purity < threshold` AND `ae_error > ae_threshold` → ZERO_DAY
3. If `purity < threshold` AND `ae_error <= ae_threshold` → accept DT (low-conf)

This provides three routing paths:
- `DT_CONFIDENT`: Fast, deterministic, known class
- `AE_FLAGGED`: Novel anomaly requiring human review
- `DT_LOW_CONF_AE_NORMAL`: Borderline, likely benign

### Autoencoder Design Rationale

The AE is trained ONLY on NORMAL traffic:
- Learns the manifold of normal network behaviour
- Attack traffic → high reconstruction error (anomalous)
- This is the "anomaly detection philosophy"
- The AE threshold is set at the 95th percentile of NORMAL validation errors

This means the AE can detect ANY anomaly — including classes the DT never saw
(demonstrated by the LOCO experiment).

### LOCO Experiment Insight

The key validation: When a class is excluded from DT training:
- DT recall on excluded class ≈ 0% (never seen this pattern)
- AE recall on excluded class > 0% (it's anomalous vs NORMAL manifold)
- Fusion recall = DT_as_attack + AE > 0%

This is PRAHARI-Lite's zero-day capability — provided by the AE without
any changes to the system.

### Feature Selection (15 of 31)

Selected by three-axis composite ranking (same as v7 pruning):
1. GBM permutation importance (weight 0.6)
2. Cross-tool stability CV (weight 0.2)
3. FPGA implementation cost (weight 0.2)

All 15 features are implementable in FPGA hardware with simple counters,
running min/max, or Welford online statistics.

### Threshold Values

| Parameter | Value | How determined |
|-----------|-------|----------------|
| DT confidence threshold | 0.70 | Mean leaf purity of correctly classified val samples |
| AE anomaly threshold | 95th percentile | Of NORMAL validation reconstruction errors |
| Max DT depth | 12 | Highest F1 with BRAM < 25KB constraint |
| AE bottleneck | 4 | Sufficient for 5-class separation |

### FPGA Resource Budget

| Component | LUTs | BRAM18 | DSPs |
|-----------|------|--------|------|
| DT Inference | 800 | 2 | 0 |
| AE Inference | 500 | 1 | 8 |
| Fusion Logic | 100 | 0 | 0 |
| Feature Scaler | 200 | 0 | 4 |
| Total | 1,700 | 3 | 12 |
| % of Pynq-Z2 | 3.2% | 2.8% | 5.5% |

### Isolation from PRAHARI v7

PRAHARI-Lite is completely isolated:
- No shared Python imports
- No shared file paths
- Separate ports (5001/5002 vs 5000/6060)
- Separate Docker network
- Separate experiment log (experiment_log_lite.{md,json})
- Scaler copied, not symlinked, not refitted
