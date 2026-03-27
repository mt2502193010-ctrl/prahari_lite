#!/usr/bin/env python3
"""
PRAHARI-Lite: Autoencoder Trainer
Architecture: 15 -> 8 -> 4 -> 8 -> 15
Trained on NORMAL traffic only (anomaly detection philosophy).
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

warnings.filterwarnings('ignore')

BASE_DIR    = Path(__file__).parent.parent
MODEL_DIR   = BASE_DIR / "models"
OUTPUT_DIR  = BASE_DIR / "outputs"
RUNTIME_DIR = BASE_DIR / "runtime"

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
MODEL_DIR.mkdir(parents=True, exist_ok=True)

sys.path.insert(0, str(RUNTIME_DIR))

FEATURES_15 = [
    'dst_port', 'fwd_bytes', 'init_win_bwd', 'init_win_fwd', 'bwd_bytes',
    'fwd_seg_min', 'fwd_pkt_mean', 'flow_iat_min', 'duration', 'flow_byts_s',
    'avg_pkt_size', 'bwd_pkt_max', 'bwd_pkts', 'syn_flag', 'pkt_len_mean'
]

CLASSES = ['NORMAL', 'APT', 'RECON', 'TRAFFIC_SPIKE', 'NR_MALWARE']

# Import torch — handle gracefully if not available
try:
    import torch
    import torch.nn as nn
    from torch.utils.data import DataLoader, TensorDataset
    TORCH_AVAILABLE = True
except ImportError:
    TORCH_AVAILABLE = False
    print("[AE] WARNING: torch not available. Autoencoder training will be skipped.")
    print("[AE] Install with: pip install torch>=2.0.0")


def generate_synthetic_data(n_per_class=10000, random_state=42):
    """Synthetic fallback when real datasets unavailable."""
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


if TORCH_AVAILABLE:
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
else:
    class TinyAutoencoder:  # type: ignore
        """Placeholder when torch is unavailable."""
        pass


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        h.update(f.read())
    return h.hexdigest()


def train():
    if not TORCH_AVAILABLE:
        print("[AE] torch not available. Creating placeholder outputs.")
        _create_placeholder_outputs()
        return None, None

    print("=" * 60)
    print("PRAHARI-Lite: Autoencoder Training")
    print("=" * 60)

    # Try logger
    logger = None
    try:
        from prahari_lite_logger import PrahariLiteLogger
        logger = PrahariLiteLogger(script_name="train_autoencoder", version="v1")
        logger.section("Setup")
        logger.decision("Train AE on NORMAL only", "Anomaly detection philosophy")
    except ImportError:
        pass

    # Load data (synthetic)
    df = generate_synthetic_data(n_per_class=10000)
    print(f"[AE] Dataset: {len(df)} rows")

    # Load scaler
    scaler_path = MODEL_DIR / "scaler_lite_v1.pkl"
    if scaler_path.exists():
        scaler = joblib.load(scaler_path)
        print(f"[AE] Loaded scaler from {scaler_path}")
    else:
        from sklearn.preprocessing import StandardScaler
        scaler = StandardScaler()
        X_all = df[FEATURES_15].values.astype(float)
        X_all = np.nan_to_num(X_all)
        scaler.fit(X_all)
        joblib.dump(scaler, scaler_path)
        print("[AE] Fitted new scaler")

    # Get NORMAL data only for training
    normal_df = df[df['label'] == 'NORMAL'].copy()
    X_normal = normal_df[FEATURES_15].values.astype(float)
    X_normal = np.nan_to_num(X_normal)

    try:
        X_normal_scaled = scaler.transform(X_normal)
    except Exception:
        from sklearn.preprocessing import StandardScaler
        sc2 = StandardScaler()
        X_normal_scaled = sc2.fit_transform(X_normal)

    # Split NORMAL into train/val
    n_normal = len(X_normal_scaled)
    n_train = int(0.8 * n_normal)
    idx = np.random.RandomState(42).permutation(n_normal)
    X_train_np = X_normal_scaled[idx[:n_train]]
    X_val_np   = X_normal_scaled[idx[n_train:]]

    print(f"[AE] NORMAL train: {len(X_train_np)}, val: {len(X_val_np)}")

    # Torch tensors
    X_train_t = torch.FloatTensor(X_train_np)
    X_val_t   = torch.FloatTensor(X_val_np)

    train_ds = TensorDataset(X_train_t, X_train_t)
    train_dl = DataLoader(train_ds, batch_size=512, shuffle=True)

    # Model
    model = TinyAutoencoder()
    optimizer = torch.optim.Adam(model.parameters(), lr=0.001)
    criterion = nn.MSELoss()

    # Training loop with early stopping
    best_val_loss = float('inf')
    patience = 10
    patience_counter = 0
    best_state = None
    epochs = 100

    print("[AE] Training...")
    for epoch in range(1, epochs + 1):
        model.train()
        train_loss = 0.0
        for x_batch, _ in train_dl:
            optimizer.zero_grad()
            recon = model(x_batch)
            loss = criterion(recon, x_batch)
            loss.backward()
            optimizer.step()
            train_loss += loss.item() * len(x_batch)
        train_loss /= len(X_train_t)

        model.eval()
        with torch.no_grad():
            val_recon = model(X_val_t)
            val_loss = criterion(val_recon, X_val_t).item()

        if epoch % 10 == 0:
            print(f"[AE] Epoch {epoch:3d}/{epochs}: train_loss={train_loss:.6f}, val_loss={val_loss:.6f}")

        if val_loss < best_val_loss:
            best_val_loss = val_loss
            best_state = {k: v.clone() for k, v in model.state_dict().items()}
            patience_counter = 0
        else:
            patience_counter += 1
            if patience_counter >= patience:
                print(f"[AE] Early stopping at epoch {epoch}")
                break

    # Restore best
    if best_state:
        model.load_state_dict(best_state)
    model.eval()

    # Compute threshold: 95th percentile of NORMAL val errors
    with torch.no_grad():
        normal_errors = model.reconstruction_error(X_val_t).numpy()

    threshold = float(np.percentile(normal_errors, 95))
    print(f"[AE] Threshold (95th pct of NORMAL val errors): {threshold:.6f}")

    # Save model
    model_path = MODEL_DIR / "ae_lite_v1.pkl"
    torch.save({
        'state_dict': model.state_dict(),
        'threshold': threshold,
    }, model_path)
    print(f"[AE] Saved model to {model_path}")

    # Save quantised version
    quant_path = MODEL_DIR / "ae_lite_v1_quantised.pkl"
    torch.save({
        'state_dict_fp16': {k: v.half() for k, v in model.state_dict().items()},
        'threshold': threshold,
    }, quant_path)
    print(f"[AE] Saved quantised model to {quant_path}")

    # Save threshold JSON
    threshold_data = {
        'threshold': threshold,
        'percentile': 95,
        'n_normal_val': len(X_val_np),
        'mean_normal_error': float(np.mean(normal_errors)),
        'std_normal_error': float(np.std(normal_errors)),
    }
    with open(OUTPUT_DIR / "ae_threshold.json", 'w') as f:
        json.dump(threshold_data, f, indent=2)

    # Compute error distributions for all classes
    print("[AE] Computing error distributions for all classes...")
    error_dist = {}
    for cls in CLASSES:
        cls_df = df[df['label'] == cls]
        if len(cls_df) == 0:
            continue
        X_cls = cls_df[FEATURES_15].values.astype(float)
        X_cls = np.nan_to_num(X_cls)
        try:
            X_cls_scaled = scaler.transform(X_cls)
        except Exception:
            X_cls_scaled = X_cls
        X_cls_t = torch.FloatTensor(X_cls_scaled)
        with torch.no_grad():
            errors = model.reconstruction_error(X_cls_t).numpy()
        error_dist[cls] = errors
        detected = np.sum(errors > threshold)
        print(f"[AE]   {cls}: mean_error={np.mean(errors):.4f}, detected={detected}/{len(errors)} ({100*detected/len(errors):.1f}%)")

    # Align lengths for CSV
    max_len = max(len(v) for v in error_dist.values())
    error_df_data = {}
    for cls in CLASSES:
        if cls in error_dist:
            arr = error_dist[cls]
            if len(arr) < max_len:
                arr = np.pad(arr, (0, max_len - len(arr)), constant_values=np.nan)
            error_df_data[cls] = arr
        else:
            error_df_data[cls] = np.full(max_len, np.nan)

    error_df = pd.DataFrame(error_df_data)
    error_df.to_csv(OUTPUT_DIR / "ae_error_distributions.csv", index=False)
    print(f"[AE] Saved error distributions to outputs/ae_error_distributions.csv")

    # Update model registry
    sha = sha256_file(model_path)
    import datetime
    registry_path = MODEL_DIR / "model_registry_lite.csv"
    ts = datetime.datetime.now().isoformat()
    with open(registry_path, 'a') as f:
        f.write(f"{ts},ae_lite_v1,Autoencoder,,,,{sha[:16]},threshold={threshold:.6f}\n")

    if logger:
        logger.section("Results")
        logger.param("threshold", round(threshold, 6))
        logger.param("best_val_loss", round(best_val_loss, 6))
        logger.artifact(str(model_path), notes="AE 15-8-4-8-15 fp32")
        logger.artifact(str(quant_path), notes="AE fp16 quantised")
        logger.save()

    print(f"\n[AE] Training complete!")
    print(f"  Model: {model_path}")
    print(f"  Threshold: {threshold:.6f}")
    print(f"  Best val loss: {best_val_loss:.6f}")

    return model, threshold


def _create_placeholder_outputs():
    """Create placeholder outputs when torch is not available."""
    import datetime

    placeholder_threshold = {
        'threshold': 0.05,
        'percentile': 95,
        'n_normal_val': 0,
        'mean_normal_error': 0.0,
        'std_normal_error': 0.0,
        'note': 'PLACEHOLDER - torch not available'
    }
    with open(OUTPUT_DIR / "ae_threshold.json", 'w') as f:
        json.dump(placeholder_threshold, f, indent=2)

    # Placeholder error distributions
    df = pd.DataFrame({cls: [0.0] for cls in CLASSES})
    df.to_csv(OUTPUT_DIR / "ae_error_distributions.csv", index=False)

    print("[AE] Placeholder outputs created in outputs/")
    print("[AE] Install torch and re-run to get real autoencoder model")


if __name__ == '__main__':
    train()
