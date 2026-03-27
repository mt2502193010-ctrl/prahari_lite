#!/usr/bin/env python3
"""
PRAHARI-Lite: Decision Tree Trainer
Trains DT at depths [6, 8, 10, 12, 15], selects best under 25KB BRAM.
Computes leaf purity and confidence threshold.
Completely isolated from PRAHARI v7.
"""
import sys
import os
import json
import hashlib
import warnings
from pathlib import Path
import numpy as np
import pandas as pd
import joblib
from sklearn.tree import DecisionTreeClassifier
from sklearn.metrics import f1_score, confusion_matrix, classification_report
from sklearn.model_selection import train_test_split
import datetime

warnings.filterwarnings('ignore')

BASE_DIR   = Path(__file__).parent.parent
MODEL_DIR  = BASE_DIR / "models"
OUTPUT_DIR = BASE_DIR / "outputs"
DOCS_DIR   = BASE_DIR / "docs"
RUNTIME_DIR = BASE_DIR / "runtime"

# Ensure output dirs exist
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
DOCS_DIR.mkdir(parents=True, exist_ok=True)
MODEL_DIR.mkdir(parents=True, exist_ok=True)

# Add runtime to path for logger
sys.path.insert(0, str(RUNTIME_DIR))

FEATURES_15 = [
    'dst_port', 'fwd_bytes', 'init_win_bwd', 'init_win_fwd', 'bwd_bytes',
    'fwd_seg_min', 'fwd_pkt_mean', 'flow_iat_min', 'duration', 'flow_byts_s',
    'avg_pkt_size', 'bwd_pkt_max', 'bwd_pkts', 'syn_flag', 'pkt_len_mean'
]

CLASSES = ['NORMAL', 'APT', 'RECON', 'TRAFFIC_SPIKE', 'NR_MALWARE']

# Column mappings from v7 system (CIC-IDS-2017/2018 format)
CIC_COL_MAP = {
    'dst_port':    'Destination Port',
    'fwd_bytes':   'Total Length of Fwd Packets',
    'init_win_bwd': 'Init_Win_bytes_backward',
    'init_win_fwd': 'Init_Win_bytes_forward',
    'bwd_bytes':   'Total Length of Bwd Packets',
    'fwd_seg_min': 'min_seg_size_forward',
    'fwd_pkt_mean': 'Fwd Packet Length Mean',
    'flow_iat_min': 'Flow IAT Min',
    'duration':    'Flow Duration',
    'flow_byts_s': 'Flow Bytes/s',
    'avg_pkt_size': 'Average Packet Size',
    'bwd_pkt_max': 'Bwd Packet Length Max',
    'bwd_pkts':    'Total Backward Packets',
    'syn_flag':    'SYN Flag Count',
    'pkt_len_mean': 'Packet Length Mean',
}

# v7 also uses "Tot Bwd Pkts" style
CIC_COL_MAP_V2 = {
    'dst_port':    'Dst Port',
    'fwd_bytes':   'TotLen Fwd Pkts',
    'init_win_bwd': 'Init Bwd Win Byts',
    'init_win_fwd': 'Init Fwd Win Byts',
    'bwd_bytes':   'TotLen Bwd Pkts',
    'fwd_seg_min': 'Fwd Seg Size Min',
    'fwd_pkt_mean': 'Fwd Pkt Len Mean',
    'flow_iat_min': 'Flow IAT Min',
    'duration':    'Flow Duration',
    'flow_byts_s': 'Flow Byts/s',
    'avg_pkt_size': 'Pkt Size Avg',
    'bwd_pkt_max': 'Bwd Pkt Len Max',
    'bwd_pkts':    'Tot Bwd Pkts',
    'syn_flag':    'SYN Flag Cnt',
    'pkt_len_mean': 'Pkt Len Mean',
}

LABEL_MAP = {
    'BENIGN': 'NORMAL',
    'benign': 'NORMAL',
    'Normal': 'NORMAL',
    'NORMAL': 'NORMAL',
    'FTP-Patator': 'APT',
    'SSH-Patator': 'APT',
    'Heartbleed': 'APT',
    'Infiltration': 'APT',
    'INFILTRATION': 'APT',
    'APT': 'APT',
    'PortScan': 'RECON',
    'Bot': 'NR_MALWARE',
    'BOT': 'NR_MALWARE',
    'NR_MALWARE': 'NR_MALWARE',
    'DoS Hulk': 'TRAFFIC_SPIKE',
    'DoS GoldenEye': 'TRAFFIC_SPIKE',
    'DoS slowloris': 'TRAFFIC_SPIKE',
    'DoS Slowhttptest': 'TRAFFIC_SPIKE',
    'DDoS': 'TRAFFIC_SPIKE',
    'DDOS': 'TRAFFIC_SPIKE',
    'TRAFFIC_SPIKE': 'TRAFFIC_SPIKE',
    'Web Attack - Brute Force': 'APT',
    'Web Attack - XSS': 'APT',
    'Web Attack - Sql Injection': 'APT',
    'RECON': 'RECON',
}


def generate_synthetic_data(n_per_class=10000, random_state=42):
    """Synthetic fallback when real datasets unavailable."""
    rng = np.random.RandomState(random_state)
    frames = []

    n = n_per_class

    # NORMAL: typical web traffic
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

    # APT: SSH/FTP brute force — small packets, port 22
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

    # RECON: port scan — tiny/zero payloads, many ports
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

    # TRAFFIC_SPIKE: DoS/DDoS — high rate, low window
    ts = pd.DataFrame({
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
    frames.append(ts)

    # NR_MALWARE: malware C2 — beaconing on weird ports
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

    df = pd.concat(frames, ignore_index=True)
    return df


def try_map_columns(df, col_map):
    """Try to rename columns using a mapping; return None if any key missing."""
    rev = {v: k for k, v in col_map.items()}
    available = {c: rev[c] for c in df.columns if c in rev}
    if len(available) >= len(FEATURES_15):
        return df.rename(columns=available)
    return None


def load_real_data():
    """Try to load real CSV data from docker_env/data/ or common paths."""
    data_paths = [
        Path('/Users/deepakkumaryadav/ids_project/docker_env/data/cicids_combined.csv'),
        Path('/Users/deepakkumaryadav/ids_project/docker_env/data/cicids_upload.csv'),
        Path('/app/data/cicids_combined.csv'),
    ]

    for p in data_paths:
        if p.exists():
            print(f"[DT] Loading real data from {p} ...")
            try:
                df = pd.read_csv(p, nrows=200000)
                # Try column mapping
                for cmap in [CIC_COL_MAP, CIC_COL_MAP_V2]:
                    mapped = try_map_columns(df, cmap)
                    if mapped is not None:
                        df = mapped
                        break

                # Map label column
                label_col = None
                for lc in ['label', 'Label', 'Label ', ' Label']:
                    if lc in df.columns:
                        label_col = lc
                        break
                if label_col is None:
                    print(f"[DT] No label column found in {p}, skipping")
                    continue

                df['label'] = df[label_col].map(LABEL_MAP)
                df = df.dropna(subset=['label'])

                # Check we have the features
                missing = [f for f in FEATURES_15 if f not in df.columns]
                if missing:
                    print(f"[DT] Missing features {missing}, skipping {p}")
                    continue

                print(f"[DT] Loaded {len(df)} rows from real data")
                return df[FEATURES_15 + ['label']]
            except Exception as e:
                print(f"[DT] Error loading {p}: {e}")
                continue

    return None


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        h.update(f.read())
    return h.hexdigest()


def estimate_bram_kb(tree):
    """Estimate BRAM usage in KB for a decision tree."""
    n_nodes = tree.node_count
    n_leaves = int(np.sum(tree.children_left == -1))
    bram_kb = (n_nodes * 20 + n_leaves * 80) / 8 / 1024
    return bram_kb


def compute_leaf_purities(tree):
    """Compute purity for each leaf node."""
    leaf_purities = {}
    for i in range(tree.node_count):
        if tree.children_left[i] == -1:  # leaf node
            values = tree.value[i][0]
            total = values.sum()
            if total > 0:
                purity = values.max() / total
            else:
                purity = 0.0
            leaf_purities[i] = float(purity)
    return leaf_purities


def train():
    print("=" * 60)
    print("PRAHARI-Lite: Decision Tree Training")
    print("=" * 60)

    # Try logger
    logger = None
    try:
        from prahari_lite_logger import PrahariLiteLogger
        logger = PrahariLiteLogger(script_name="train_decision_tree", version="v1")
        logger.section("Setup")
        logger.decision("Use prahari_lite isolated training", "Completely separate from v7")
    except ImportError:
        print("[DT] Logger not available, proceeding without it")

    # Load data
    df = load_real_data()
    if df is None:
        print("[DT] No real data found. Using synthetic fallback.")
        df = generate_synthetic_data(n_per_class=10000)
        using_synthetic = True
    else:
        using_synthetic = False

    if logger:
        logger.section("Data")
        logger.param("data_source", "synthetic" if using_synthetic else "real")
        logger.param("total_rows", len(df))
        logger.param("class_distribution", df['label'].value_counts().to_dict())

    print(f"[DT] Dataset: {len(df)} rows, classes: {df['label'].value_counts().to_dict()}")

    # Encode labels
    label_to_idx = {c: i for i, c in enumerate(CLASSES)}
    df['label_idx'] = df['label'].map(label_to_idx)
    df = df.dropna(subset=['label_idx'])
    df['label_idx'] = df['label_idx'].astype(int)

    X = df[FEATURES_15].values.astype(float)
    y = df['label_idx'].values

    # Replace inf/nan
    X = np.nan_to_num(X, nan=0.0, posinf=0.0, neginf=0.0)

    # Load scaler
    scaler_path = MODEL_DIR / "scaler_lite_v1.pkl"
    if scaler_path.exists():
        print(f"[DT] Loading scaler from {scaler_path}")
        scaler = joblib.load(scaler_path)
        try:
            X_scaled = scaler.transform(X)
        except Exception as e:
            print(f"[DT] Scaler transform failed ({e}), fitting new scaler")
            from sklearn.preprocessing import StandardScaler
            scaler = StandardScaler()
            X_scaled = scaler.fit_transform(X)
    else:
        print("[DT] No scaler found, fitting new StandardScaler")
        from sklearn.preprocessing import StandardScaler
        scaler = StandardScaler()
        X_scaled = scaler.fit_transform(X)
        joblib.dump(scaler, scaler_path)

    # Train/val/test split
    X_train, X_test, y_train, y_test = train_test_split(
        X_scaled, y, test_size=0.2, random_state=42, stratify=y)
    X_train, X_val, y_train, y_val = train_test_split(
        X_train, y_train, test_size=0.1, random_state=42, stratify=y_train)

    print(f"[DT] Train: {len(X_train)}, Val: {len(X_val)}, Test: {len(X_test)}")

    # Train at multiple depths
    depths = [6, 8, 10, 12, 15]
    results = []

    if logger:
        logger.section("Training")

    for depth in depths:
        print(f"\n[DT] Training depth={depth}...")
        dt = DecisionTreeClassifier(
            max_depth=depth,
            min_samples_leaf=5,
            random_state=42,
            class_weight='balanced'
        )
        dt.fit(X_train, y_train)

        y_pred_val = dt.predict(X_val)
        f1_val = f1_score(y_val, y_pred_val, average='macro', zero_division=0)

        # FPR: use val set, treat NORMAL as negative
        cm = confusion_matrix(y_val, y_pred_val, labels=list(range(len(CLASSES))))
        # NORMAL is index 0
        normal_idx = CLASSES.index('NORMAL')
        tn = cm[normal_idx, normal_idx]
        fp = cm[normal_idx, :].sum() - tn  # NORMAL misclassified as attack
        # Actually FPR = attacks predicted as attacks when they are normal
        fp_real = cm[:, normal_idx].sum() - tn  # predicted normal col, not normal row
        # Correct FPR: FP = normal samples predicted as attack
        normal_mask = y_val == normal_idx
        fp_count = np.sum(y_pred_val[normal_mask] != normal_idx)
        tn_count = np.sum(y_pred_val[normal_mask] == normal_idx)
        fpr = fp_count / (fp_count + tn_count) if (fp_count + tn_count) > 0 else 0.0

        bram_kb = estimate_bram_kb(dt.tree_)
        n_nodes = dt.tree_.node_count
        n_leaves = int(np.sum(dt.tree_.children_left == -1))

        print(f"[DT]   depth={depth}: F1={f1_val:.4f}, FPR={fpr:.4f}, BRAM={bram_kb:.2f}KB, nodes={n_nodes}, leaves={n_leaves}")

        results.append({
            'depth': depth,
            'f1_val': f1_val,
            'fpr': fpr,
            'bram_kb': bram_kb,
            'n_nodes': n_nodes,
            'n_leaves': n_leaves,
            'model': dt,
        })

        if logger:
            logger.param(f"depth_{depth}_f1", round(f1_val, 4))
            logger.param(f"depth_{depth}_bram_kb", round(bram_kb, 2))

    # Save comparison CSV
    results_df = pd.DataFrame([{
        'depth': r['depth'], 'f1_val': r['f1_val'],
        'fpr': r['fpr'], 'bram_kb': r['bram_kb'],
        'n_nodes': r['n_nodes'], 'n_leaves': r['n_leaves']
    } for r in results])
    results_df.to_csv(OUTPUT_DIR / "dt_depth_comparison.csv", index=False)
    print(f"\n[DT] Saved depth comparison to outputs/dt_depth_comparison.csv")

    # Select best model: highest F1 with BRAM < 25KB
    under_budget = [r for r in results if r['bram_kb'] < 25.0]
    if under_budget:
        best = max(under_budget, key=lambda r: r['f1_val'])
        print(f"[DT] Best model (BRAM < 25KB): depth={best['depth']}, F1={best['f1_val']:.4f}, BRAM={best['bram_kb']:.2f}KB")
    else:
        best = min(results, key=lambda r: r['bram_kb'])
        print(f"[DT] No model under 25KB budget! Selecting smallest: depth={best['depth']}, BRAM={best['bram_kb']:.2f}KB")

    best_dt = best['model']
    best_depth = best['depth']

    # Final evaluation on test set
    y_pred_test = best_dt.predict(X_test)
    f1_test = f1_score(y_test, y_pred_test, average='macro', zero_division=0)
    normal_mask_test = y_test == CLASSES.index('NORMAL')
    fp_test = np.sum(y_pred_test[normal_mask_test] != CLASSES.index('NORMAL'))
    tn_test = np.sum(y_pred_test[normal_mask_test] == CLASSES.index('NORMAL'))
    fpr_test = fp_test / (fp_test + tn_test) if (fp_test + tn_test) > 0 else 0.0

    print(f"\n[DT] Test set results: F1={f1_test:.4f}, FPR={fpr_test:.4f}")
    print(classification_report(y_test, y_pred_test,
                                target_names=CLASSES, zero_division=0))

    # Compute leaf purities
    print("[DT] Computing leaf purities...")
    tree_ = best_dt.tree_
    leaf_purities = compute_leaf_purities(tree_)

    # Save leaf purity distribution
    purity_records = []
    for leaf_id, purity in leaf_purities.items():
        n_samples = tree_.n_node_samples[leaf_id]
        dominant_class = CLASSES[int(tree_.value[leaf_id][0].argmax())]
        purity_records.append({
            'leaf_id': leaf_id,
            'purity': purity,
            'n_samples': n_samples,
            'dominant_class': dominant_class,
        })

    purity_df = pd.DataFrame(purity_records)
    purity_df.to_csv(OUTPUT_DIR / "leaf_purity_distribution.csv", index=False)
    print(f"[DT] Saved leaf purity distribution ({len(purity_df)} leaves)")

    # Compute confidence threshold from val set
    # For each correctly classified val sample, get its leaf's purity
    val_leaves = best_dt.apply(X_val)
    correctly_classified = y_pred_val_best = best_dt.predict(X_val)
    correct_mask = (correctly_classified == y_val)
    correct_purities = [leaf_purities.get(leaf_id, 0.0) for leaf_id in val_leaves[correct_mask]]

    if correct_purities:
        confidence_threshold = float(np.mean(correct_purities))
    else:
        confidence_threshold = 0.7

    print(f"[DT] Confidence threshold (mean purity of correct val samples): {confidence_threshold:.4f}")

    # Save confidence threshold
    threshold_data = {
        'confidence_threshold': confidence_threshold,
        'n_leaves': len(leaf_purities),
        'mean_leaf_purity': float(np.mean(list(leaf_purities.values()))),
        'min_leaf_purity': float(np.min(list(leaf_purities.values()))),
        'max_leaf_purity': float(np.max(list(leaf_purities.values()))),
        'best_depth': best_depth,
        'f1_test': f1_test,
        'fpr_test': fpr_test,
        'bram_kb': best['bram_kb'],
        'timestamp': datetime.datetime.now().isoformat(),
    }

    with open(OUTPUT_DIR / "dt_confidence_threshold.json", 'w') as f:
        json.dump(threshold_data, f, indent=2)

    # Save model
    model_path = MODEL_DIR / "dt_lite_v1.pkl"
    joblib.dump(best_dt, model_path)
    sha = sha256_file(model_path)
    print(f"\n[DT] Saved model to {model_path}")
    print(f"[DT] SHA256: {sha}")

    # Update model registry
    registry_path = MODEL_DIR / "model_registry_lite.csv"
    ts = datetime.datetime.now().isoformat()
    with open(registry_path, 'a') as f:
        f.write(f"{ts},dt_lite_v1,DecisionTree,{f1_test:.4f},{fpr_test:.4f},"
                f"{best['bram_kb']:.2f},{sha[:16]},depth={best_depth}\n")

    if logger:
        logger.section("Results")
        logger.param("best_depth", best_depth)
        logger.param("f1_test", round(f1_test, 4))
        logger.param("fpr_test", round(fpr_test, 4))
        logger.param("bram_kb", round(best['bram_kb'], 2))
        logger.param("confidence_threshold", round(confidence_threshold, 4))
        logger.param("n_leaves", len(leaf_purities))
        logger.check("F1 >= 0.80", f1_test >= 0.80, f1_test)
        logger.check("BRAM < 25KB", best['bram_kb'] < 25.0, best['bram_kb'])
        logger.artifact(str(model_path), notes=f"DT depth={best_depth}")
        logger.artifact(str(OUTPUT_DIR / "dt_depth_comparison.csv"))
        logger.artifact(str(OUTPUT_DIR / "leaf_purity_distribution.csv"))
        logger.artifact(str(OUTPUT_DIR / "dt_confidence_threshold.json"))
        logger.save()

    print("\n[DT] Training complete!")
    print(f"  Model:  {model_path}")
    print(f"  F1:     {f1_test:.4f}")
    print(f"  FPR:    {fpr_test:.4f}")
    print(f"  BRAM:   {best['bram_kb']:.2f}KB")
    print(f"  Depth:  {best_depth}")
    print(f"  Leaves: {len(leaf_purities)}")
    print(f"  Threshold: {confidence_threshold:.4f}")

    return best_dt, scaler, confidence_threshold


if __name__ == '__main__':
    train()
