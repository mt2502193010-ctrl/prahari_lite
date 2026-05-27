#!/usr/bin/env python3
"""
PRAHARI-Lite Dashboard
Port: 5002
Proxies stats from IDS server at port 5001 (configurable via IDS_LITE_URL env var).
"""
from flask import Flask, render_template, jsonify, request
from markupsafe import escape
import requests as req
import os
from pathlib import Path

BASE_DIR = Path(__file__).parent.parent

app = Flask(__name__,
            template_folder='templates',
            static_folder='static')

IDS_BASE = os.environ.get('IDS_LITE_URL', 'http://localhost:5001')


@app.after_request
def add_security_headers(resp):
    resp.headers['Content-Security-Policy'] = (
        "default-src 'self'; "
        "script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; "
        "style-src 'self' 'unsafe-inline'; "
        "img-src 'self' data:;"
    )
    return resp


@app.route('/')
def index():
    return render_template('dashboard_lite.html')


@app.route('/api/stats')
def stats():
    try:
        r = req.get(f"{IDS_BASE}/stats", timeout=3)
        return jsonify(r.json())
    except Exception as e:
        return jsonify({
            "error": str(e),
            "total_flows": 0,
            "attacks_detected": 0,
            "zero_day_alerts": 0,
            "attack_rate_pct": 0,
            "class_counts": {},
            "routing_counts": {},
            "uptime_human": "N/A",
            "minute_buckets": [],
        })


@app.route('/api/recent_alerts')
def recent_alerts():
    n = int(request.args.get('n', 20))
    try:
        r = req.get(f"{IDS_BASE}/recent_alerts?n={n}", timeout=3)
        return jsonify(r.json())
    except Exception as e:
        return jsonify([])


@app.route('/api/health')
def health():
    try:
        r = req.get(f"{IDS_BASE}/health", timeout=3)
        return jsonify(r.json())
    except Exception as e:
        return jsonify({
            "status": "unreachable",
            "error": str(e),
            "models_loaded": False,
        })


@app.route('/api/loco_results')
def loco_results():
    """Load LOCO experiment results from CSV."""
    loco_path = BASE_DIR / "outputs" / "loco_results.csv"
    if not loco_path.exists():
        return jsonify([])
    try:
        import csv
        results = []
        with open(loco_path) as f:
            reader = csv.DictReader(f)
            for row in reader:
                results.append(row)
        return jsonify(results)
    except Exception as e:
        return jsonify({"error": str(e)})


if __name__ == '__main__':
    print("=" * 50)
    print("PRAHARI-Lite Dashboard")
    print(f"  Port:     5002")
    print(f"  IDS URL:  {IDS_BASE}")
    print(f"  Base dir: {BASE_DIR}")
    print("=" * 50)
    app.run(host='0.0.0.0', port=5002, debug=False)
