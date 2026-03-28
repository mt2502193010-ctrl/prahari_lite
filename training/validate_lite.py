#!/usr/bin/env python3
"""PRAHARI-Lite: Fusion Validation — compares against PRAHARI v7 reference."""
import sys
import json
import warnings
from pathlib import Path
import numpy as np
import pandas as pd
import joblib

warnings.filterwarnings('ignore')

BASE_DIR   = Path(__file__).parent.parent
MODEL_DIR  = BASE_DIR / "models"
OUTPUT_DIR = BASE_DIR / "outputs"
RUNTIME_DIR = BASE_DIR / "runtime"
sys.path.insert(0, str(RUNTIME_DIR))

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

FEATURES_15 = [
    'dst_port', 'fwd_bytes', 'init_win_bwd', 'init_win_fwd', 'bwd_bytes',
    'fwd_seg_min', 'fwd_pkt_mean', 'flow_iat_min', 'duration', 'flow_byts_s',
    'avg_pkt_size', 'bwd_pkt_max', 'bwd_pkts', 'syn_flag', 'pkt_len_mean'
]

CLASSES = ['NORMAL', 'APT', 'RECON', 'TRAFFIC_SPIKE', 'NR_MALWARE']

PRAHARI_V7_REFERENCE = {
    'combined_f1': 0.855,
    'cic2017_f1':  0.992,
    'cic2017_fpr': 0.0042,
    'apt_recall':  0.881,
    'recon_recall': 0.840,
    'ts_recall':   0.817,
    'nrm_recall':  0.936,
    'latency_ms':  2.06,
    'bram_kb':     640,
}

# Import torch if available
try:
    import torch
    import torch.nn as nn
    TORCH_AVAILABLE = True

    class TinyAutoencoder(nn.Module):
        def __init__(self):
            super().__init__()
            self.encoder = nn.Sequential(
                nn.Linear(15, 8), nn.ReLU(),
                nn.Linear(8, 4), nn.ReLU()
            )
            self.decoder = nn.Sequential(
                nn.Linear(4, 8), nn.ReLU(),
                nn.Linear(8, 15)
            )

        def forward(self, x):
            return self.decoder(self.encoder(x))

        def reconstruction_error(self, x):
            with torch.no_grad():
                recon = self.forward(x)
                return torch.mean((x - recon) ** 2, dim=1)

except ImportError:
    TORCH_AVAILABLE = False
    print("[VAL] torch not available — AE validation will be skipped")


def generate_synthetic_data(n_per_class=5000, random_state=99):
    """Generate synthetic test data."""
    rng = np.random.RandomState(random_state)
    frames = []
    n = n_per_class

    normal = pd.DataFrame({
        'dst_port':    rng.choice([80, 443, 53, 8080], n).astype(float),
        'fwd_bytes':   rng.uniform(100, 50000, n),
        'init_win_bwd': rng.uniform(8000, 65535, n),
        'init_win_fwd': rng.uniform(8000, 65535, n),
        'bwd_bytes':   rng.uniform(50, 30000, n),
        'fwd_seg_min': rng.uniform(20, 100, n),
        'fwd_pkt_mean': rng.uniform(100, 1500, n),
        'flow_iat_min': rng.uniform(100, 100000, n),
        'duration':    rng.uniform(10000, 10000000, n),
        'flow_byts_s': rng.uniform(100, 100000, n),
        'avg_pkt_size': rng.uniform(100, 1500, n),
        'bwd_pkt_max': rng.uniform(100, 65535, n),
        'bwd_pkts':    rng.uniform(1, 20, n),
        'syn_flag':    rng.randint(0, 2, n).astype(float),
        'pkt_len_mean': rng.uniform(100, 1500, n),
        'label': 'NORMAL'
    })
    frames.append(normal)

    apt = pd.DataFrame({
        'dst_port':    rng.choice([22, 21, 23], n).astype(float),
        'fwd_bytes':   rng.uniform(10, 500, n),
        'init_win_bwd': rng.uniform(8000, 32768, n),
        'init_win_fwd': rng.uniform(8000, 32768, n),
        'bwd_bytes':   rng.uniform(5, 300, n),
        'fwd_seg_min': rng.uniform(20, 50, n),
        'fwd_pkt_mean': rng.uniform(10, 100, n),
        'flow_iat_min': rng.uniform(10, 5000, n),
        'duration':    rng.uniform(1000, 500000, n),
        'flow_byts_s': rng.uniform(1000, 500000, n),
        'avg_pkt_size': rng.uniform(10, 150, n),
        'bwd_pkt_max': rng.uniform(10, 500, n),
        'bwd_pkts':    rng.uniform(1, 50, n),
        'syn_flag':    rng.randint(0, 2, n).astype(float),
        'pkt_len_mean': rng.uniform(10, 150, n),
        'label': 'APT'
    })
    frames.append(apt)

    recon = pd.DataFrame({
        'dst_port':    rng.randint(1, 65535, n).astype(float),
        'fwd_bytes':   rng.uniform(0, 10, n),
        'init_win_bwd': rng.uniform(0, 1024, n),
        'init_win_fwd': rng.uniform(0, 1024, n),
        'bwd_bytes':   rng.uniform(0, 5, n),
        'fwd_seg_min': rng.uniform(0, 20, n),
        'fwd_pkt_mean': rng.uniform(0, 10, n),
        'flow_iat_min': rng.uniform(0, 1000, n),
        'duration':    rng.uniform(100, 10000, n),
        'flow_byts_s': rng.uniform(10, 10000, n),
        'avg_pkt_size': rng.uniform(0, 10, n),
        'bwd_pkt_max': rng.uniform(0, 50, n),
        'bwd_pkts':    rng.uniform(0, 2, n),
        'syn_flag':    np.ones(n),
        'pkt_len_mean': rng.uniform(0, 10, n),
        'label': 'RECON'
    })
    frames.append(recon)

    ts_df = pd.DataFrame({
        'dst_port':    rng.choice([80, 443], n).astype(float),
        'fwd_bytes':   rng.uniform(50, 5000, n),
        'init_win_bwd': rng.uniform(0, 8192, n),
        'init_win_fwd': rng.uniform(0, 8192, n),
        'bwd_bytes':   rng.uniform(0, 500, n),
        'fwd_seg_min': rng.uniform(0, 40, n),
        'fwd_pkt_mean': rng.uniform(50, 500, n),
        'flow_iat_min': rng.uniform(0, 100, n),
        'duration':    rng.uniform(100, 100000, n),
        'flow_byts_s': rng.uniform(100000, 10000000, n),
        'avg_pkt_size': rng.uniform(50, 500, n),
        'bwd_pkt_max': rng.uniform(0, 1000, n),
        'bwd_pkts':    rng.uniform(0, 5, n),
        'syn_flag':    rng.randint(0, 2, n).astype(float),
        'pkt_len_mean': rng.uniform(50, 500, n),
        'label': 'TRAFFIC_SPIKE'
    })
    frames.append(ts_df)

    nrm = pd.DataFrame({
        'dst_port':    rng.choice([4444, 6666, 8888, 1337, 31337], n).astype(float),
        'fwd_bytes':   rng.uniform(100, 10000, n),
        'init_win_bwd': rng.uniform(4096, 32768, n),
        'init_win_fwd': rng.uniform(4096, 32768, n),
        'bwd_bytes':   rng.uniform(50, 5000, n),
        'fwd_seg_min': rng.uniform(20, 80, n),
        'fwd_pkt_mean': rng.uniform(50, 800, n),
        'flow_iat_min': rng.uniform(1000, 1000000, n),
        'duration':    rng.uniform(100000, 100000000, n),
        'flow_byts_s': rng.uniform(100, 10000, n),
        'avg_pkt_size': rng.uniform(50, 800, n),
        'bwd_pkt_max': rng.uniform(50, 5000, n),
        'bwd_pkts':    rng.uniform(1, 15, n),
        'syn_flag':    rng.randint(0, 2, n).astype(float),
        'pkt_len_mean': rng.uniform(50, 800, n),
        'label': 'NR_MALWARE'
    })
    frames.append(nrm)

    return pd.concat(frames, ignore_index=True)


def load_models():
    """Load DT and AE models. Return (dt, scaler, leaf_purities, dt_threshold, ae_model, ae_threshold)."""
    # Load DT
    dt_path = MODEL_DIR / "dt_lite_v1.pkl"
    if not dt_path.exists():
        print(f"[VAL] ERROR: {dt_path} not found. Run train_decision_tree.py first.")
        sys.exit(1)
    dt = joblib.load(dt_path)
    print(f"[VAL] Loaded DT from {dt_path}")

    # Load scaler
    scaler_path = MODEL_DIR / "scaler_lite_v1.pkl"
    scaler = joblib.load(scaler_path)

    # Precompute leaf purities
    tree_ = dt.tree_
    leaf_purities = {}
    for i in range(tree_.node_count):
        if tree_.children_left[i] == -1:
            values = tree_.value[i][0]
            total = values.sum()
            purity = float(values.max() / total) if total > 0 else 0.0
            leaf_purities[i] = purity

    # Load DT threshold
    thresh_path = OUTPUT_DIR / "dt_confidence_threshold.json"
    if thresh_path.exists():
        with open(thresh_path) as f:
            td = json.load(f)
        dt_threshold = td['confidence_threshold']
    else:
        dt_threshold = 0.7
    print(f"[VAL] DT confidence threshold: {dt_threshold:.4f}")

    # Load AE
    ae_model = None
    ae_threshold = 0.05

    ae_path = MODEL_DIR / "ae_lite_v1.pkl"
    ae_thresh_path = OUTPUT_DIR / "ae_threshold.json"

    if ae_thresh_path.exists():
        with open(ae_thresh_path) as f:
            atd = json.load(f)
        ae_threshold = atd.get('threshold', 0.05)

    if TORCH_AVAILABLE and ae_path.exists():
        try:
            checkpoint = torch.load(ae_path, map_location='cpu', weights_only=False)
            ae_model = TinyAutoencoder()
            ae_model.load_state_dict(checkpoint['state_dict'])
            ae_model.eval()
            ae_threshold = checkpoint.get('threshold', ae_threshold)
            print(f"[VAL] Loaded AE model, threshold={ae_threshold:.6f}")
        except Exception as e:
            print(f"[VAL] Could not load AE: {e}")
            ae_model = None
    else:
        print(f"[VAL] AE model not available (torch={TORCH_AVAILABLE}, file={ae_path.exists()})")

    return dt, scaler, leaf_purities, dt_threshold, ae_model, ae_threshold


def fusion_predict(X_scaled, dt, scaler, leaf_purities, dt_threshold, ae_model, ae_threshold):
    """Apply fusion logic: DT + AE."""
    n = len(X_scaled)
    dt_preds = dt.predict(X_scaled)
    dt_leaves = dt.apply(X_scaled)
    dt_purities = np.array([leaf_purities.get(leaf, 0.0) for leaf in dt_leaves])

    # DT confidence gate
    dt_confident_mask = dt_purities >= dt_threshold

    # AE anomaly detection
    if ae_model is not None:
        X_t = torch.FloatTensor(X_scaled)
        with torch.no_grad():
            ae_errors = ae_model.reconstruction_error(X_t).numpy()
        ae_anomaly_mask = ae_errors > ae_threshold
    else:
        ae_anomaly_mask = np.zeros(n, dtype=bool)
        ae_errors = np.zeros(n)

    # Fusion
    final_preds = np.full(n, -1, dtype=int)
    routing = np.full(n, 'UNKNOWN', dtype=object)

    for i in range(n):
        if dt_confident_mask[i]:
            # DT is confident
            final_preds[i] = dt_preds[i]
            routing[i] = 'DT_CONFIDENT'
        elif ae_anomaly_mask[i]:
            # DT not confident but AE flags anomaly → zero-day
            final_preds[i] = len(CLASSES)  # ZERO_DAY
            routing[i] = 'AE_FLAGGED'
        else:
            # DT not confident, AE says normal
            final_preds[i] = dt_preds[i]  # trust DT anyway but flag as low conf
            routing[i] = 'DT_LOW_CONF_AE_NORMAL'

    return final_preds, routing, dt_preds, dt_purities, ae_errors


CIC_COL_MAP = {
    'dst_port': 'Destination Port', 'fwd_bytes': 'Total Length of Fwd Packets',
    'init_win_bwd': 'Init_Win_bytes_backward', 'init_win_fwd': 'Init_Win_bytes_forward',
    'bwd_bytes': 'Total Length of Bwd Packets', 'fwd_seg_min': 'min_seg_size_forward',
    'fwd_pkt_mean': 'Fwd Packet Length Mean', 'flow_iat_min': 'Flow IAT Min',
    'duration': 'Flow Duration', 'flow_byts_s': 'Flow Bytes/s',
    'avg_pkt_size': 'Average Packet Size', 'bwd_pkt_max': 'Bwd Packet Length Max',
    'bwd_pkts': 'Total Backward Packets', 'syn_flag': 'SYN Flag Count',
    'pkt_len_mean': 'Packet Length Mean',
}
LABEL_MAP = {
    'BENIGN': 'NORMAL', 'benign': 'NORMAL', 'Normal': 'NORMAL', 'NORMAL': 'NORMAL',
    'FTP-Patator': 'APT', 'SSH-Patator': 'APT', 'Heartbleed': 'APT',
    'Infiltration': 'APT', 'INFILTRATION': 'APT', 'APT': 'APT',
    'PortScan': 'RECON', 'RECON': 'RECON',
    'Bot': 'NR_MALWARE', 'BOT': 'NR_MALWARE', 'NR_MALWARE': 'NR_MALWARE',
    'DoS Hulk': 'TRAFFIC_SPIKE', 'DoS GoldenEye': 'TRAFFIC_SPIKE',
    'DoS slowloris': 'TRAFFIC_SPIKE', 'DoS Slowhttptest': 'TRAFFIC_SPIKE',
    'DDoS': 'TRAFFIC_SPIKE', 'DDOS': 'TRAFFIC_SPIKE', 'TRAFFIC_SPIKE': 'TRAFFIC_SPIKE',
    'Web Attack - Brute Force': 'APT', 'Web Attack - XSS': 'APT',
    'Web Attack - Sql Injection': 'APT',
}


def _load_real_data_for_val():
    """Load real CSV data for validation (same source as DT training) with synthetic fallback."""
    data_paths = [
        Path('/Users/deepakkumaryadav/ids_project/docker_env/data/cicids_combined.csv'),
        Path('/Users/deepakkumaryadav/ids_project/docker_env/data/cicids_upload.csv'),
        Path('/app/data/cicids_combined.csv'),
    ]
    for p in data_paths:
        if not p.exists():
            continue
        try:
            df = pd.read_csv(p, nrows=200000)
            rev = {v: k for k, v in CIC_COL_MAP.items()}
            df = df.rename(columns={c: rev[c] for c in df.columns if c in rev})
            label_col = next((lc for lc in ['label', 'Label', 'Label '] if lc in df.columns), None)
            if label_col is None:
                continue
            df['label'] = df[label_col].map(LABEL_MAP)
            df = df.dropna(subset=['label'])
            if not all(f in df.columns for f in FEATURES_15):
                continue
            print(f"[VAL] Using real data: {p.name} ({len(df)} rows)")
            return df[FEATURES_15 + ['label']]
        except Exception:
            continue
    print("[VAL] No real data found — using synthetic fallback")
    return generate_synthetic_data(n_per_class=5000, random_state=99)


def validate():
    print("=" * 60)
    print("PRAHARI-Lite: Fusion Validation")
    print("=" * 60)

    dt, scaler, leaf_purities, dt_threshold, ae_model, ae_threshold = load_models()

    # Load test data — use real data if available (same source as DT training),
    # else fall back to synthetic. Using real data gives meaningful F1 numbers.
    df = _load_real_data_for_val()
    print(f"[VAL] Test dataset: {len(df)} rows")

    X = df[FEATURES_15].values.astype(float)
    X = np.nan_to_num(X, nan=0.0, posinf=0.0, neginf=0.0)
    try:
        X_scaled = scaler.transform(X)
    except Exception:
        from sklearn.preprocessing import StandardScaler
        sc = StandardScaler()
        X_scaled = sc.fit_transform(X)

    y_true = df['label'].map({c: i for i, c in enumerate(CLASSES)}).fillna(-1).astype(int).values

    final_preds, routing, dt_preds, dt_purities, ae_errors = fusion_predict(
        X_scaled, dt, scaler, leaf_purities, dt_threshold, ae_model, ae_threshold
    )

    # Compute metrics — only consider samples with known true label (not ZERO_DAY)
    known_mask = y_true >= 0
    y_true_known = y_true[known_mask]
    y_pred_known = final_preds[known_mask]
    # Replace ZERO_DAY preds with DT pred for known labels eval
    y_pred_eval = np.where(y_pred_known == len(CLASSES), dt_preds[known_mask], y_pred_known)

    from sklearn.metrics import f1_score, recall_score, confusion_matrix

    f1_combined = f1_score(y_true_known, y_pred_eval, average='macro', zero_division=0)

    # Per-class recall
    recalls = {}
    for i, cls in enumerate(CLASSES):
        cls_mask = y_true_known == i
        if cls_mask.sum() == 0:
            recalls[cls] = 0.0
        else:
            recalls[cls] = float(np.mean(y_pred_eval[cls_mask] == i))

    # FPR
    normal_idx = CLASSES.index('NORMAL')
    normal_mask = y_true_known == normal_idx
    fp = np.sum(y_pred_eval[normal_mask] != normal_idx)
    tn = np.sum(y_pred_eval[normal_mask] == normal_idx)
    fpr = fp / (fp + tn) if (fp + tn) > 0 else 0.0

    # Zero-day detections
    n_zero_day = np.sum(final_preds == len(CLASSES))
    zero_day_pct = 100 * n_zero_day / len(final_preds)

    # Routing stats
    routing_counts = {
        'DT_CONFIDENT': int(np.sum(routing == 'DT_CONFIDENT')),
        'AE_FLAGGED': int(np.sum(routing == 'AE_FLAGGED')),
        'DT_LOW_CONF_AE_NORMAL': int(np.sum(routing == 'DT_LOW_CONF_AE_NORMAL')),
    }

    print(f"\n{'='*60}")
    print("PRAHARI-Lite Validation Results")
    print(f"{'='*60}")
    print(f"  Combined F1:       {f1_combined:.4f}")
    print(f"  FPR:               {fpr:.4f}")
    print(f"  APT Recall:        {recalls['APT']:.4f}")
    print(f"  RECON Recall:      {recalls['RECON']:.4f}")
    print(f"  TS Recall:         {recalls['TRAFFIC_SPIKE']:.4f}")
    print(f"  NRM Recall:        {recalls['NR_MALWARE']:.4f}")
    print(f"  Zero-day alerts:   {n_zero_day} ({zero_day_pct:.1f}%)")
    print(f"  Routing: {routing_counts}")

    print(f"\n{'='*60}")
    print("Comparison: PRAHARI-Lite vs PRAHARI v7")
    print(f"{'='*60}")
    print(f"{'Metric':<25} {'v7 Reference':>15} {'Lite':>15} {'Delta':>10}")
    print("-" * 65)

    comparisons = [
        ('combined_f1',  'Combined F1',    f1_combined),
        ('cic2017_fpr',  'FPR',            fpr),
        ('apt_recall',   'APT Recall',     recalls['APT']),
        ('recon_recall', 'RECON Recall',   recalls['RECON']),
        ('ts_recall',    'TS Recall',      recalls['TRAFFIC_SPIKE']),
        ('nrm_recall',   'NRM Recall',     recalls['NR_MALWARE']),
        ('bram_kb',      'BRAM KB',        None),
    ]

    bram_path = OUTPUT_DIR / "dt_confidence_threshold.json"
    bram_kb = 5.0
    if bram_path.exists():
        with open(bram_path) as f:
            td = json.load(f)
        bram_kb = td.get('bram_kb', 5.0)

    lite_vals = {
        'combined_f1':  f1_combined,
        'cic2017_fpr':  fpr,
        'apt_recall':   recalls['APT'],
        'recon_recall': recalls['RECON'],
        'ts_recall':    recalls['TRAFFIC_SPIKE'],
        'nrm_recall':   recalls['NR_MALWARE'],
        'bram_kb':      bram_kb,
    }

    for key, label, _ in comparisons:
        v7_val = PRAHARI_V7_REFERENCE[key]
        lite_val = lite_vals[key]
        delta = lite_val - v7_val
        print(f"{label:<25} {v7_val:>15.4f} {lite_val:>15.4f} {delta:>+10.4f}")

    # Save results
    results = {
        'combined_f1': f1_combined,
        'fpr': fpr,
        'apt_recall': recalls['APT'],
        'recon_recall': recalls['RECON'],
        'ts_recall': recalls['TRAFFIC_SPIKE'],
        'nrm_recall': recalls['NR_MALWARE'],
        'zero_day_count': int(n_zero_day),
        'zero_day_pct': float(zero_day_pct),
        'routing': routing_counts,
        'dt_threshold': dt_threshold,
        'ae_threshold': ae_threshold,
        'bram_kb': bram_kb,
        'v7_reference': PRAHARI_V7_REFERENCE,
    }

    results_df = pd.DataFrame([{
        'metric': k, 'prahari_lite': v,
        'prahari_v7': PRAHARI_V7_REFERENCE.get(k, 'N/A')
    } for k, v in results.items() if isinstance(v, (int, float))])
    results_df.to_csv(OUTPUT_DIR / "validation_lite_results.csv", index=False)

    with open(OUTPUT_DIR / "validation_lite_results.json", 'w') as f:
        json.dump(results, f, indent=2)

    print(f"\n[VAL] Results saved to outputs/validation_lite_results.csv")
    return results


if __name__ == '__main__':
    validate()
