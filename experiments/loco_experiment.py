#!/usr/bin/env python3
"""
PRAHARI-Lite: LOCO (Leave-One-Class-Out) Experiment
Tests zero-day detection capability when a class is withheld from DT training.
Key insight: AE is always trained on NORMAL only — it never changes.
             Only the DT changes. The AE is the zero-day safety net.
"""
import sys
import json
import warnings
from pathlib import Path
import numpy as np
import pandas as pd
import joblib
from sklearn.tree import DecisionTreeClassifier

warnings.filterwarnings('ignore')

BASE_DIR    = Path(__file__).parent.parent
MODEL_DIR   = BASE_DIR / "models"
OUTPUT_DIR  = BASE_DIR / "outputs"
RUNTIME_DIR = BASE_DIR / "runtime"
sys.path.insert(0, str(RUNTIME_DIR))

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

FEATURES_15 = [
    'dst_port', 'fwd_bytes', 'init_win_bwd', 'init_win_fwd', 'bwd_bytes',
    'fwd_seg_min', 'fwd_pkt_mean', 'flow_iat_min', 'duration', 'flow_byts_s',
    'avg_pkt_size', 'bwd_pkt_max', 'bwd_pkts', 'syn_flag', 'pkt_len_mean'
]

CLASSES = ['NORMAL', 'APT', 'RECON', 'TRAFFIC_SPIKE', 'NR_MALWARE']
ATTACK_CLASSES = ['APT', 'RECON', 'TRAFFIC_SPIKE', 'NR_MALWARE']

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


def generate_synthetic_data(n_per_class=8000, random_state=42):
    """Generate synthetic data for LOCO experiment."""
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


def run_loco():
    print("=" * 60)
    print("PRAHARI-Lite: LOCO Experiment")
    print("=" * 60)

    # Load scaler
    scaler_path = MODEL_DIR / "scaler_lite_v1.pkl"
    scaler = joblib.load(scaler_path)

    # Load AE model (unchanged across all LOCO runs)
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
            print(f"[LOCO] AE loaded, threshold={ae_threshold:.6f}")
        except Exception as e:
            print(f"[LOCO] AE load failed: {e}")
    else:
        print(f"[LOCO] AE not available (torch={TORCH_AVAILABLE})")

    # Generate full dataset
    df = generate_synthetic_data(n_per_class=8000)

    # Split: 80% train, 20% test (held-out)
    from sklearn.model_selection import train_test_split
    train_df, test_df = train_test_split(df, test_size=0.2, random_state=42,
                                          stratify=df['label'])

    results = []

    for excluded_class in ATTACK_CLASSES:
        print(f"\n[LOCO] Excluding class: {excluded_class}")

        # Training data WITHOUT the excluded class
        train_reduced = train_df[train_df['label'] != excluded_class].copy()
        remaining_classes = [c for c in CLASSES if c != excluded_class]
        label_map = {c: i for i, c in enumerate(remaining_classes)}

        X_train = train_reduced[FEATURES_15].values.astype(float)
        X_train = np.nan_to_num(X_train)
        try:
            X_train_scaled = scaler.transform(X_train)
        except Exception:
            X_train_scaled = X_train

        y_train = train_reduced['label'].map(label_map).values

        # Retrain DT (d=12) without excluded class
        dt_loco = DecisionTreeClassifier(
            max_depth=12,
            min_samples_leaf=5,
            random_state=42,
            class_weight='balanced'
        )
        dt_loco.fit(X_train_scaled, y_train)

        # Test on held-out samples of the EXCLUDED class only
        test_excluded = test_df[test_df['label'] == excluded_class].copy()
        X_test_ex = test_excluded[FEATURES_15].values.astype(float)
        X_test_ex = np.nan_to_num(X_test_ex)
        try:
            X_test_ex_scaled = scaler.transform(X_test_ex)
        except Exception:
            X_test_ex_scaled = X_test_ex

        n_excluded = len(X_test_ex_scaled)

        # DT recall: fraction DT predicts as excluded class
        # Since DT never saw it, it predicts something else → recall ≈ 0
        # But we need the excluded class idx in original CLASSES mapping
        # DT doesn't know this class at all → recall = 0
        dt_preds = dt_loco.predict(X_test_ex_scaled)
        # How many did DT NOT classify as excluded_class's placeholder?
        # Since DT doesn't have this class, all predictions are "wrong" for this class
        dt_recall = 0.0  # DT never saw the class

        # AE recall: fraction with ae_error > ae_threshold
        if ae_model is not None:
            X_t = torch.FloatTensor(X_test_ex_scaled)
            with torch.no_grad():
                ae_errors = ae_model.reconstruction_error(X_t).numpy()
            ae_detected = int(np.sum(ae_errors > ae_threshold))
            ae_recall = ae_detected / n_excluded if n_excluded > 0 else 0.0
        else:
            ae_errors = np.zeros(n_excluded)
            ae_detected = 0
            ae_recall = 0.0

        # Fusion recall: detected by DT (as any attack) OR AE
        # DT might still catch some as "wrong" attack type — count as detected
        # More fairly: DT catches it if predicted != NORMAL
        normal_idx_reduced = label_map.get('NORMAL', 0)
        dt_detected_as_attack = int(np.sum(dt_preds != normal_idx_reduced))
        fusion_detected = int(np.sum(
            (dt_preds != normal_idx_reduced) | (ae_errors > ae_threshold)
        ))
        fusion_recall = fusion_detected / n_excluded if n_excluded > 0 else 0.0
        dt_as_attack_recall = dt_detected_as_attack / n_excluded if n_excluded > 0 else 0.0

        print(f"[LOCO]   n_excluded_test={n_excluded}")
        print(f"[LOCO]   DT recall (exact class): {dt_recall:.4f}")
        print(f"[LOCO]   DT detected as any attack: {dt_as_attack_recall:.4f}")
        print(f"[LOCO]   AE recall: {ae_recall:.4f} ({ae_detected}/{n_excluded})")
        print(f"[LOCO]   Fusion recall: {fusion_recall:.4f} ({fusion_detected}/{n_excluded})")

        results.append({
            'excluded_class': excluded_class,
            'n_test_samples': n_excluded,
            'dt_exact_recall': round(dt_recall, 4),
            'dt_as_attack_recall': round(dt_as_attack_recall, 4),
            'ae_recall': round(ae_recall, 4),
            'ae_detected': ae_detected,
            'fusion_recall': round(fusion_recall, 4),
            'fusion_detected': fusion_detected,
            'ae_threshold': round(ae_threshold, 6),
        })

    # Print summary table
    print(f"\n{'='*70}")
    print("LOCO Experiment Summary")
    print(f"{'='*70}")
    print(f"{'Excluded Class':<20} {'DT(exact)':>10} {'DT(attack)':>12} {'AE':>8} {'Fusion':>10}")
    print("-" * 70)
    for r in results:
        print(f"{r['excluded_class']:<20} {r['dt_exact_recall']:>10.4f} "
              f"{r['dt_as_attack_recall']:>12.4f} {r['ae_recall']:>8.4f} "
              f"{r['fusion_recall']:>10.4f}")

    print(f"\n[LOCO] Key insight: AE never changes (trained on NORMAL only).")
    print(f"[LOCO] Even without seeing a class, the fusion (DT+AE) can detect anomalies.")

    # Save results
    results_df = pd.DataFrame(results)
    results_df.to_csv(OUTPUT_DIR / "loco_results.csv", index=False)
    print(f"\n[LOCO] Saved results to outputs/loco_results.csv")

    return results


if __name__ == '__main__':
    run_loco()
