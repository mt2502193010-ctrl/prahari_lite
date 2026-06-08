#!/usr/bin/env python3
"""
PRAHARI-Lite IDS Server
Port: 5001 (PRAHARI v7 is on 5000 — no conflict)
Architecture: DecisionTree (d=12) + Autoencoder (15-8-4-8-15)
Novel contribution: DT leaf purity as confidence gate for zero-day routing
"""
import sys
import os
import json
import threading
import time
import datetime
import logging
from pathlib import Path
from collections import deque

BASE_DIR = Path(__file__).parent.parent
sys.path.insert(0, str(BASE_DIR / "runtime"))

from flask import Flask, request, jsonify
import numpy as np
import joblib

from fpga_bridge import FPGABridge

logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')

try:
    import torch
    import torch.nn as nn
    TORCH_AVAILABLE = True
except ImportError:
    TORCH_AVAILABLE = False


# ── TinyAutoencoder (defined here to avoid import from training/) ──────────────
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
        pass


FEATURES_15 = [
    'dst_port', 'fwd_bytes', 'init_win_bwd', 'init_win_fwd', 'bwd_bytes',
    'fwd_seg_min', 'fwd_pkt_mean', 'flow_iat_min', 'duration', 'flow_byts_s',
    'avg_pkt_size', 'bwd_pkt_max', 'bwd_pkts', 'syn_flag', 'pkt_len_mean'
]

CLASSES = ['NORMAL', 'APT', 'RECON', 'TRAFFIC_SPIKE', 'NR_MALWARE']

app = Flask(__name__)

# ── Global state ────────────────────────────────────────────────────────────────
_lock = threading.Lock()
_state = {
    'total_flows':      0,
    'attacks_detected': 0,
    'zero_day_alerts':  0,
    'class_counts':     {c: 0 for c in CLASSES + ['ZERO_DAY']},
    'routing_counts':   {
        'DT_CONFIDENT':          0,
        'AE_FLAGGED':            0,
        'DT_LOW_CONF_AE_NORMAL': 0,
    },
    'alert_history':    deque(maxlen=1000),
    'start_time':       time.time(),
    # Rolling 10-minute per-minute buckets for the live traffic chart.
    # Each entry: {'ts': epoch_minute, 'flows': int, 'attacks': int}
    'minute_buckets':   deque(maxlen=10),
    '_current_minute':  int(time.time() // 60),
    '_minute_flows':    0,
    '_minute_attacks':  0,
}

# ── FPGA bridge (global, initialised in __main__) ───────────────────────────────
# Board IP/credentials read from env so Docker and raw-Python modes share one config
_BOARD_IP   = os.environ.get("FPGA_BOARD_IP",   "192.168.2.99")
_BOARD_USER = os.environ.get("FPGA_BOARD_USER",  "xilinx")
_BOARD_PASS = os.environ.get("FPGA_BOARD_PASS",  "xilinx")
FPGA_BRIDGE = FPGABridge(board_ip=_BOARD_IP, user=_BOARD_USER, password=_BOARD_PASS)

# ── Model globals ───────────────────────────────────────────────────────────────
DT_MODEL      = None
AE_MODEL      = None
SCALER        = None
LEAF_PURITIES = {}
DT_THRESHOLD  = 0.7
AE_THRESHOLD  = 0.05
MODELS_LOADED = False
LOAD_ERROR    = None


# ── Model loading ───────────────────────────────────────────────────────────────
def load_models():
    global DT_MODEL, AE_MODEL, SCALER, LEAF_PURITIES, DT_THRESHOLD, AE_THRESHOLD
    global MODELS_LOADED, LOAD_ERROR

    try:
        model_dir  = BASE_DIR / "models"
        output_dir = BASE_DIR / "outputs"

        # Scaler
        scaler_path = model_dir / "scaler_lite_v1.pkl"
        if not scaler_path.exists():
            LOAD_ERROR = f"Scaler not found: {scaler_path}"
            print(f"[SERVER] WARNING: {LOAD_ERROR}")
            return

        SCALER = joblib.load(scaler_path)
        print(f"[SERVER] Loaded scaler from {scaler_path}")

        # Decision Tree
        dt_path = model_dir / "dt_lite_v1.pkl"
        if not dt_path.exists():
            LOAD_ERROR = f"DT model not found: {dt_path}. Run training/train_decision_tree.py first."
            print(f"[SERVER] WARNING: {LOAD_ERROR}")
            return

        DT_MODEL = joblib.load(dt_path)
        print(f"[SERVER] Loaded DT model from {dt_path}")

        # Precompute leaf purities
        tree_ = DT_MODEL.tree_
        for i in range(tree_.node_count):
            if tree_.children_left[i] == -1:
                values = tree_.value[i][0]
                total = values.sum()
                purity = float(values.max() / total) if total > 0 else 0.0
                LEAF_PURITIES[i] = purity
        print(f"[SERVER] Precomputed {len(LEAF_PURITIES)} leaf purities")

        # DT confidence threshold
        thresh_path = output_dir / "dt_confidence_threshold.json"
        if thresh_path.exists():
            with open(thresh_path) as f:
                td = json.load(f)
            DT_THRESHOLD = td.get('confidence_threshold', 0.7)
        print(f"[SERVER] DT confidence threshold: {DT_THRESHOLD:.4f}")

        # AE threshold
        ae_thresh_path = output_dir / "ae_threshold.json"
        if ae_thresh_path.exists():
            with open(ae_thresh_path) as f:
                atd = json.load(f)
            AE_THRESHOLD = atd.get('threshold', 0.05)

        # Autoencoder (optional)
        ae_path = model_dir / "ae_lite_v1.pkl"
        if TORCH_AVAILABLE and ae_path.exists():
            try:
                checkpoint = torch.load(ae_path, map_location='cpu', weights_only=False)
                AE_MODEL = TinyAutoencoder()
                AE_MODEL.load_state_dict(checkpoint['state_dict'])
                AE_MODEL.eval()
                AE_THRESHOLD = checkpoint.get('threshold', AE_THRESHOLD)
                print(f"[SERVER] Loaded AE model, threshold={AE_THRESHOLD:.6f}")
            except Exception as e:
                print(f"[SERVER] AE load failed: {e} — continuing without AE")
                AE_MODEL = None
        else:
            print(f"[SERVER] AE not available (torch={TORCH_AVAILABLE}, file={ae_path.exists()})")

        MODELS_LOADED = True
        print(f"[SERVER] All models loaded successfully")

    except Exception as e:
        LOAD_ERROR = str(e)
        print(f"[SERVER] ERROR loading models: {e}")
        import traceback
        traceback.print_exc()


# ── Inference ───────────────────────────────────────────────────────────────────
def infer(features_dict):
    """Run DT + AE fusion on a single flow."""
    # Extract features in order
    x = np.array([features_dict[f] for f in FEATURES_15], dtype=float)
    # Sanitize non-finite
    x = np.nan_to_num(x, nan=0.0, posinf=0.0, neginf=0.0)

    # Scale
    x_scaled = SCALER.transform(x.reshape(1, -1))[0]

    # DT prediction
    dt_pred_idx = int(DT_MODEL.predict(x_scaled.reshape(1, -1))[0])
    dt_leaf = int(DT_MODEL.apply(x_scaled.reshape(1, -1))[0])
    dt_purity = LEAF_PURITIES.get(dt_leaf, 0.0)
    dt_confident = dt_purity >= DT_THRESHOLD

    dt_label = CLASSES[dt_pred_idx] if dt_pred_idx < len(CLASSES) else 'UNKNOWN'

    # AE error
    ae_error = None
    ae_anomaly = False
    if AE_MODEL is not None:
        x_t = torch.FloatTensor(x_scaled.reshape(1, -1))
        ae_error = float(AE_MODEL.reconstruction_error(x_t).item())
        ae_anomaly = ae_error > AE_THRESHOLD

    # Fusion logic
    if dt_confident:
        final_label = dt_label
        routing = 'DT_CONFIDENT'
    elif ae_anomaly:
        final_label = 'ZERO_DAY'
        routing = 'AE_FLAGGED'
    else:
        final_label = dt_label
        routing = 'DT_LOW_CONF_AE_NORMAL'

    is_attack = final_label not in ('NORMAL',)
    is_zero_day = final_label == 'ZERO_DAY'

    return {
        'final_label':  final_label,
        'dt_label':     dt_label,
        'dt_purity':    round(dt_purity, 4),
        'dt_confident': dt_confident,
        'ae_error':     round(ae_error, 6) if ae_error is not None else None,
        'ae_anomaly':   ae_anomaly,
        'routing':      routing,
        'is_attack':    is_attack,
        'is_zero_day':  is_zero_day,
    }


# ── Routes ───────────────────────────────────────────────────────────────────────
@app.route('/health', methods=['GET'])
def health():
    uptime = time.time() - _state['start_time']
    if not MODELS_LOADED:
        return jsonify({
            'status': 'degraded',
            'models_loaded': False,
            'error': LOAD_ERROR or 'Models not yet loaded',
            'uptime_s': round(uptime, 1),
            'port': 5001,
        }), 200  # still 200 so clients can retry

    return jsonify({
        'status':           'ok',
        'models_loaded':    True,
        'dt_model':         'dt_lite_v1',
        'ae_model':         'ae_lite_v1' if AE_MODEL is not None else 'unavailable',
        'dt_threshold':     DT_THRESHOLD,
        'ae_threshold':     AE_THRESHOLD,
        'n_leaf_purities':  len(LEAF_PURITIES),
        'uptime_s':         round(uptime, 1),
        'port':             5001,
        'torch_available':  TORCH_AVAILABLE,
    })


@app.route('/detect', methods=['POST'])
def detect():
    # Allow inference if either FPGA is up OR software models are loaded
    if not MODELS_LOADED and not FPGA_BRIDGE.is_connected():
        return jsonify({
            'error':  'Inference unavailable',
            'detail': 'No FPGA connection and models not loaded',
        }), 503

    data = request.get_json(silent=True)
    if data is None:
        return jsonify({'error': 'Invalid JSON'}), 400

    # Accept {"features": [v0..v14]} list form OR {"feat_name": value, ...} dict form
    raw_list = []
    features = {}
    if 'features' in data and isinstance(data['features'], list):
        if len(data['features']) != 15:
            return jsonify({'error': 'features list must contain exactly 15 values'}), 400
        for i, v in enumerate(data['features']):
            try:
                val = float(v)
            except (TypeError, ValueError):
                val = 0.0
            raw_list.append(val)
            features[FEATURES_15[i]] = val
    else:
        missing = [f for f in FEATURES_15 if f not in data]
        if missing:
            return jsonify({
                'error':    'Missing required features',
                'missing':  missing,
                'required': FEATURES_15,
            }), 400
        for f in FEATURES_15:
            try:
                val = float(data[f])
            except (TypeError, ValueError):
                val = 0.0
            features[f] = val
            raw_list.append(val)

    # ── Route to hardware or software ─────────────────────────────────────────
    try:
        if FPGA_BRIDGE.is_connected():
            result = FPGA_BRIDGE.classify(raw_list)
        elif MODELS_LOADED:
            result = infer(features)
            result['source'] = 'software'
        else:
            return jsonify({'error': 'Inference unavailable'}), 503
    except Exception as e:
        return jsonify({'error': f'Inference failed: {e}'}), 500

    # ── Update state ──────────────────────────────────────────────────────────
    ts = datetime.datetime.now().isoformat()
    alert = {
        'timestamp':   ts,
        'final_label': result['final_label'],
        'dt_label':    result['dt_label'],
        'routing':     result.get('routing', 'DT_CONFIDENT'),
        'dt_purity':   result.get('dt_purity'),
        'ae_error':    result.get('ae_error'),
        'is_attack':   result['is_attack'],
        'source':      result.get('source', 'software'),
    }

    with _lock:
        _state['total_flows'] += 1
        if result['is_attack']:
            _state['attacks_detected'] += 1
        if result['is_zero_day']:
            _state['zero_day_alerts'] += 1
        label = result['final_label']
        if label in _state['class_counts']:
            _state['class_counts'][label] += 1
        routing_key = result.get('routing', 'DT_CONFIDENT')
        _state['routing_counts'][routing_key] = (
            _state['routing_counts'].get(routing_key, 0) + 1
        )
        if result['is_attack']:
            _state['alert_history'].append(alert)

        cur_min = int(time.time() // 60)
        if cur_min != _state['_current_minute']:
            _state['minute_buckets'].append({
                'ts':      _state['_current_minute'] * 60,
                'flows':   _state['_minute_flows'],
                'attacks': _state['_minute_attacks'],
            })
            _state['_current_minute'] = cur_min
            _state['_minute_flows']   = 0
            _state['_minute_attacks'] = 0
        _state['_minute_flows'] += 1
        if result['is_attack']:
            _state['_minute_attacks'] += 1

    return jsonify({
        'timestamp':    ts,
        'final_label':  result['final_label'],
        'dt_label':     result['dt_label'],
        'dt_purity':    result.get('dt_purity'),
        'dt_confident': result.get('dt_confident', True),
        'ae_error':     result.get('ae_error'),
        'ae_anomaly':   result.get('ae_anomaly', False),
        'routing':      result.get('routing', 'DT_CONFIDENT'),
        'is_attack':    result['is_attack'],
        'is_zero_day':  result['is_zero_day'],
        'source':       result.get('source', 'software'),
        'latency_us':   result.get('latency_us'),
    })


@app.route('/stats', methods=['GET'])
def stats():
    with _lock:
        uptime = time.time() - _state['start_time']
        total = _state['total_flows']
        attacks = _state['attacks_detected']
        attack_rate = round(100 * attacks / total, 2) if total > 0 else 0.0

        return jsonify({
            'total_flows':      total,
            'attacks_detected': attacks,
            'zero_day_alerts':  _state['zero_day_alerts'],
            'attack_rate_pct':  attack_rate,
            'class_counts':     dict(_state['class_counts']),
            'routing_counts':   dict(_state['routing_counts']),
            'uptime_s':         round(uptime, 1),
            'uptime_human':     _fmt_uptime(uptime),
            'models': {
                'dt':    'dt_lite_v1',
                'ae':    'ae_lite_v1' if AE_MODEL is not None else 'unavailable',
                'scaler': 'scaler_lite_v1',
            },
            'thresholds': {
                'dt_confidence': DT_THRESHOLD,
                'ae_anomaly':    AE_THRESHOLD,
            },
            # Include the in-progress current minute so chart updates immediately
            'minute_buckets': list(_state['minute_buckets']) + [{
                'ts':      _state['_current_minute'] * 60,
                'flows':   _state['_minute_flows'],
                'attacks': _state['_minute_attacks'],
            }],
        })


@app.route('/recent_alerts', methods=['GET'])
def recent_alerts():
    n = min(int(request.args.get('n', 50)), 200)
    with _lock:
        alerts = list(_state['alert_history'])[-n:]
    return jsonify(alerts[::-1])  # newest first


@app.route('/reset', methods=['POST'])
def reset():
    with _lock:
        _state['total_flows'] = 0
        _state['attacks_detected'] = 0
        _state['zero_day_alerts'] = 0
        _state['class_counts'] = {c: 0 for c in CLASSES + ['ZERO_DAY']}
        _state['routing_counts'] = {
            'DT_CONFIDENT': 0,
            'AE_FLAGGED': 0,
            'DT_LOW_CONF_AE_NORMAL': 0,
        }
        _state['alert_history'].clear()
        _state['start_time'] = time.time()
    return jsonify({'status': 'reset', 'message': 'Stats cleared'})


@app.route('/fpga_status', methods=['GET'])
def fpga_status():
    return jsonify(FPGA_BRIDGE.status())


def _fmt_uptime(seconds):
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    return f"{h}h {m}m {s}s"


# ── Entry point ─────────────────────────────────────────────────────────────────
if __name__ == '__main__':
    print("=" * 60)
    print("PRAHARI-Lite IDS Server")
    print("=" * 60)
    print(f"  Port:     5001")
    print(f"  Base dir: {BASE_DIR}")
    print(f"  Torch:    {TORCH_AVAILABLE}")
    print(f"  Note:     PRAHARI v7 runs on port 5000 — no conflict")
    print("=" * 60)

    load_models()

    if MODELS_LOADED:
        print("\n[SERVER] Models loaded. Starting server on port 5001...")
    else:
        print(f"\n[SERVER] WARNING: {LOAD_ERROR}")
        print("[SERVER] Server starting in degraded mode — /health returns error info")

    # ── Try FPGA bridge (non-blocking — server starts regardless) ────────────
    def _try_fpga():
        print("[FPGA] Attempting to connect to board...")
        ok = FPGA_BRIDGE.connect()
        if ok:
            print(f"[FPGA] Connected — hardware inference active")
        else:
            print("[FPGA] Board unreachable — using software fallback")

    import threading as _th
    _th.Thread(target=_try_fpga, daemon=True).start()

    app.run(host='0.0.0.0', port=5001, debug=False, threaded=True)
