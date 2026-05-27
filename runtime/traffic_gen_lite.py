#!/usr/bin/env python3
"""
PRAHARI-Lite traffic generator.
Sends a continuous stream of mixed flows to localhost:5001/detect
at ~2 flows/second so the dashboard has live data to display.

Preferred mode: samples real rows from CICIDS2018 CSVs (auto-discovered).
Fallback mode : generates synthetic flows using calibrated feature ranges
                derived from the scaler statistics (mean ± scale).

Usage:
    python traffic_gen_lite.py [--rate 2.0] [--url http://localhost:5001]
"""
import argparse
import csv
import glob
import math
import os
import random
import sys
import time
from pathlib import Path

try:
    import requests
except ImportError:
    print("requests not installed — run: pip install requests")
    sys.exit(1)

FEATURES = [
    'dst_port', 'fwd_bytes', 'init_win_bwd', 'init_win_fwd', 'bwd_bytes',
    'fwd_seg_min', 'fwd_pkt_mean', 'flow_iat_min', 'duration', 'flow_byts_s',
    'avg_pkt_size', 'bwd_pkt_max', 'bwd_pkts', 'syn_flag', 'pkt_len_mean',
]

# ── CICIDS2018 column → PRAHARI-Lite feature mapping ─────────────────────────
CICIDS2018_MAP = {
    'Dst Port':          'dst_port',
    'TotLen Fwd Pkts':   'fwd_bytes',
    'Init Bwd Win Byts': 'init_win_bwd',
    'Init Fwd Win Byts': 'init_win_fwd',
    'TotLen Bwd Pkts':   'bwd_bytes',
    'Fwd Seg Size Min':  'fwd_seg_min',
    'Fwd Pkt Len Mean':  'fwd_pkt_mean',
    'Flow IAT Min':      'flow_iat_min',
    'Flow Duration':     'duration',
    'Flow Byts/s':       'flow_byts_s',
    'Pkt Size Avg':      'avg_pkt_size',
    'Bwd Pkt Len Max':   'bwd_pkt_max',
    'Tot Bwd Pkts':      'bwd_pkts',
    'SYN Flag Cnt':      'syn_flag',
    'Pkt Len Mean':      'pkt_len_mean',
}

# ── Synthetic fallback: (mean, std) per feature from scaler stats ─────────────
# Values are taken from the actual StandardScaler fitted on training data.
# We add noise around the mean to vary the flows; for attack profiles we
# shift selected features to mimic what the scaler's outlier range covers.
SCALER_MEAN = [6234.24, 4004.60, 3293.05, 6593.25, 15258.71,
               -2920.63, 83.28, 1149956.64, 8473172.65, 646140.88,
               136.47, 386.06, 13.41, 0.028, 80.30]
SCALER_SCALE = [16276.14, 121751.05, 12446.99, 14924.56, 1822821.79,
                1122323.82, 169.27, 9106573.25, 26295131.51, 16298275.25,
                236.50, 1199.46, 840.13, 0.166, 196.68]

# Attack profiles expressed as offsets in units of scaler_scale from scaler_mean.
# These were empirically validated: scaled values in these ranges trigger
# attack predictions from the trained DT model.
SYNTH_PROFILES = {
    # NORMAL: stay close to the mean (scaled ≈ 0)
    'NORMAL': [0.0] * 15,
    # APT: high fwd_bytes, low flow_byts_s, high bwd_bytes, high dst_port
    'APT':    [1.0, 1.5, 0.0, 0.0, 1.0, 0.0, 0.0, -0.5, 0.5, -0.5, 0.0, 0.0, 0.0, 0.0, 0.0],
    # TRAFFIC_SPIKE: negative dst_port scaled, high fwd_bytes, negative bwd_bytes
    'TRAFFIC_SPIKE': [-1.5, 1.5, 0.0, 0.0, -1.5, 0.0, 0.0, 0.0, 0.0, 0.5, 0.0, 0.0, 0.0, 0.0, -1.0],
    # NR_MALWARE: negative dst_port scaled, moderate fwd_bytes, negative bwd_bytes
    'NR_MALWARE': [-1.2, 1.5, 0.0, 0.0, -1.5, 0.0, 0.5, -0.5, 0.0, 0.5, 0.0, 0.5, 0.0, 0.0, 1.5],
    # RECON: small bytes, near-zero everything — relies on AE anomaly path
    'RECON':  [0.0, -0.3, -0.2, 0.0, -0.5, 0.0, -0.3, -0.5, -0.5, 0.0, -0.3, -0.3, -0.2, 0.5, -0.3],
}

# Mix (attack labels purposely over-represented so they show up on dashboard)
WEIGHTS = {'NORMAL': 0.55, 'APT': 0.12, 'RECON': 0.10, 'TRAFFIC_SPIKE': 0.12, 'NR_MALWARE': 0.11}


# ── Load real rows from CICIDS2018 ────────────────────────────────────────────
def load_attack_seeds():
    """Load pre-validated attack-predicting feature vectors."""
    seeds_path = Path(__file__).parent / 'attack_seeds.json'
    if not seeds_path.exists():
        return {}
    try:
        import json
        with open(seeds_path) as f:
            data = json.load(f)
        total = sum(len(v) for v in data.values())
        print(f"[TRAFFIC_GEN] Loaded {total} attack seeds from {seeds_path.name}")
        return data
    except Exception as e:
        print(f"[TRAFFIC_GEN] Could not load attack seeds: {e}")
        return {}


def load_real_rows(max_rows=5000):
    """Search parent directories for CICIDS2018 CSVs and load sample rows."""
    search_roots = [
        Path(__file__).parent.parent.parent,  # ids_project/
        Path.home() / 'ids_project',
    ]
    csv_files = []
    for root in search_roots:
        csv_files.extend(glob.glob(str(root / 'docker_env' / 'CICIDS2018' / '*.csv')))
        if csv_files:
            break

    if not csv_files:
        return []

    rows = []
    per_file = max(1, max_rows // len(csv_files))

    for path in csv_files:
        count = 0
        try:
            with open(path, newline='') as f:
                reader = csv.DictReader(f)
                # Check this file has required columns
                required = set(CICIDS2018_MAP.keys())
                if not required.issubset(set(reader.fieldnames or [])):
                    continue
                for raw in reader:
                    flow = {}
                    ok = True
                    for src_col, dst_feat in CICIDS2018_MAP.items():
                        try:
                            v = float(raw[src_col])
                            if not math.isfinite(v):
                                v = 0.0
                            flow[dst_feat] = max(0.0, v)
                        except (ValueError, TypeError):
                            ok = False
                            break
                    if ok:
                        rows.append(flow)
                        count += 1
                        if count >= per_file:
                            break
        except Exception:
            continue

    random.shuffle(rows)
    print(f"[TRAFFIC_GEN] Loaded {len(rows)} real rows from {len(csv_files)} CICIDS2018 file(s)")
    return rows


# ── Synthetic flow generation ─────────────────────────────────────────────────
def synth_flow(label):
    offsets = SYNTH_PROFILES.get(label, SYNTH_PROFILES['NORMAL'])
    noise_scale = 0.4
    flow = {}
    for i, feat in enumerate(FEATURES):
        scaled_val = offsets[i] + random.gauss(0, noise_scale)
        orig_val = SCALER_MEAN[i] + scaled_val * SCALER_SCALE[i]
        flow[feat] = max(0.0, orig_val)
    flow['dst_port'] = max(1, int(flow['dst_port']))
    flow['syn_flag'] = 1 if flow['syn_flag'] >= 0.5 else 0
    flow['bwd_pkts'] = max(0, int(flow['bwd_pkts']))
    return flow


def pick_label():
    r = random.random()
    cumulative = 0.0
    for label, w in WEIGHTS.items():
        cumulative += w
        if r < cumulative:
            return label
    return 'NORMAL'


# ── Main loop ─────────────────────────────────────────────────────────────────
def run(base_url, rate_hz):
    interval = 1.0 / rate_hz
    url = base_url.rstrip('/') + '/detect'

    real_rows = load_real_rows(max_rows=8000)
    attack_seeds = load_attack_seeds()  # {cls: [flow_dict, ...]}
    attack_pool = []  # flat list of (label, flow_dict)
    for cls, flows in attack_seeds.items():
        for f in flows:
            attack_pool.append((cls, f))
    random.shuffle(attack_pool)
    attack_idx = 0

    print(f"[TRAFFIC_GEN] Real rows: {len(real_rows)} | Attack seeds: {len(attack_pool)}")
    print(f"[TRAFFIC_GEN] Sending to {url} at {rate_hz:.1f} flows/sec (40% attacks injected)")
    print(f"[TRAFFIC_GEN] Ctrl-C to stop\n")

    session = requests.Session()
    sent = errors = 0
    t_start = time.time()

    while True:
        t0 = time.time()

        # 40% chance inject a known attack seed to ensure attacks appear on dashboard
        if attack_pool and random.random() < 0.40:
            _label, flow = attack_pool[attack_idx % len(attack_pool)]
            attack_idx += 1
        elif real_rows:
            flow = real_rows[sent % len(real_rows)]
        else:
            label = pick_label()
            flow = synth_flow(label)

        try:
            resp = session.post(url, json=flow, timeout=2.0)
            sent += 1
            if sent % 100 == 0:
                elapsed = time.time() - t_start
                fps = sent / elapsed
                last = resp.json()
                print(
                    f"[TRAFFIC_GEN] {sent:>6} flows | {fps:.1f} fps | "
                    f"errors={errors} | last={last.get('final_label','?')} "
                    f"routing={last.get('routing','?')}"
                )
        except Exception as e:
            errors += 1
            if errors <= 5 or errors % 100 == 0:
                print(f"[TRAFFIC_GEN] ERROR: {e}")

        elapsed = time.time() - t0
        sleep_time = interval - elapsed
        if sleep_time > 0:
            time.sleep(sleep_time)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='PRAHARI-Lite traffic generator')
    parser.add_argument('--rate', type=float, default=2.0, help='Flows/sec (default: 2.0)')
    parser.add_argument('--url', type=str, default='http://localhost:5001', help='IDS server base URL')
    args = parser.parse_args()
    run(args.url, args.rate)
