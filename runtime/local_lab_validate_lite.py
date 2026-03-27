#!/usr/bin/env python3
"""
PRAHARI-Lite: Local Lab Validation Script
Tests all endpoints of the IDS server running on localhost:5001.
Run AFTER starting ids_lite_server.py.
"""
import requests
import json
import sys
import time

BASE = "http://localhost:5001"

FEATURES_15 = [
    'dst_port', 'fwd_bytes', 'init_win_bwd', 'init_win_fwd', 'bwd_bytes',
    'fwd_seg_min', 'fwd_pkt_mean', 'flow_iat_min', 'duration', 'flow_byts_s',
    'avg_pkt_size', 'bwd_pkt_max', 'bwd_pkts', 'syn_flag', 'pkt_len_mean'
]


def test_health():
    print("\n=== Health Check ===")
    try:
        r = requests.get(f"{BASE}/health", timeout=5)
        print(f"Status: {r.status_code}")
        print(json.dumps(r.json(), indent=2))
        return r.status_code == 200
    except requests.ConnectionError:
        print("ERROR: Cannot connect to server. Is ids_lite_server.py running?")
        return False


def test_normal_flow():
    print("\n=== Normal Flow Detection ===")
    normal_flow = {
        'dst_port':    443.0,
        'fwd_bytes':   5000.0,
        'init_win_bwd': 32768.0,
        'init_win_fwd': 32768.0,
        'bwd_bytes':   2000.0,
        'fwd_seg_min': 32.0,
        'fwd_pkt_mean': 500.0,
        'flow_iat_min': 10000.0,
        'duration':    500000.0,
        'flow_byts_s': 5000.0,
        'avg_pkt_size': 500.0,
        'bwd_pkt_max': 1500.0,
        'bwd_pkts':    4.0,
        'syn_flag':    1.0,
        'pkt_len_mean': 500.0,
    }
    r = requests.post(f"{BASE}/detect", json=normal_flow, timeout=5)
    print(f"Status: {r.status_code}")
    print(json.dumps(r.json(), indent=2))
    return r.status_code == 200


def test_apt_flow():
    print("\n=== APT Flow Detection (SSH brute-force pattern) ===")
    apt_flow = {
        'dst_port':    22.0,
        'fwd_bytes':   100.0,
        'init_win_bwd': 8192.0,
        'init_win_fwd': 8192.0,
        'bwd_bytes':   50.0,
        'fwd_seg_min': 20.0,
        'fwd_pkt_mean': 50.0,
        'flow_iat_min': 500.0,
        'duration':    50000.0,
        'flow_byts_s': 100000.0,
        'avg_pkt_size': 50.0,
        'bwd_pkt_max': 100.0,
        'bwd_pkts':    10.0,
        'syn_flag':    1.0,
        'pkt_len_mean': 50.0,
    }
    r = requests.post(f"{BASE}/detect", json=apt_flow, timeout=5)
    print(f"Status: {r.status_code}")
    print(json.dumps(r.json(), indent=2))
    return r.status_code == 200


def test_recon_flow():
    print("\n=== RECON Flow Detection (port scan pattern) ===")
    recon_flow = {
        'dst_port':    12345.0,
        'fwd_bytes':   0.0,
        'init_win_bwd': 0.0,
        'init_win_fwd': 0.0,
        'bwd_bytes':   0.0,
        'fwd_seg_min': 0.0,
        'fwd_pkt_mean': 0.0,
        'flow_iat_min': 0.0,
        'duration':    100.0,
        'flow_byts_s': 100.0,
        'avg_pkt_size': 0.0,
        'bwd_pkt_max': 0.0,
        'bwd_pkts':    0.0,
        'syn_flag':    1.0,
        'pkt_len_mean': 0.0,
    }
    r = requests.post(f"{BASE}/detect", json=recon_flow, timeout=5)
    print(f"Status: {r.status_code}")
    print(json.dumps(r.json(), indent=2))
    return r.status_code == 200


def test_missing_features():
    print("\n=== Missing Features (expect 400) ===")
    r = requests.post(f"{BASE}/detect", json={"dst_port": 80}, timeout=5)
    print(f"Status: {r.status_code} (expected 400)")
    print(json.dumps(r.json(), indent=2))
    return r.status_code == 400


def test_invalid_json():
    print("\n=== Invalid JSON (expect 400) ===")
    r = requests.post(f"{BASE}/detect", data="not json",
                      headers={"Content-Type": "application/json"}, timeout=5)
    print(f"Status: {r.status_code} (expected 400)")
    return r.status_code == 400


def test_stats():
    print("\n=== Stats ===")
    r = requests.get(f"{BASE}/stats", timeout=5)
    print(f"Status: {r.status_code}")
    print(json.dumps(r.json(), indent=2))
    return r.status_code == 200


def test_recent_alerts():
    print("\n=== Recent Alerts ===")
    r = requests.get(f"{BASE}/recent_alerts?n=5", timeout=5)
    print(f"Status: {r.status_code}")
    alerts = r.json()
    print(f"  Alerts returned: {len(alerts)}")
    if alerts:
        print(f"  Latest: {json.dumps(alerts[0], indent=4)}")
    return r.status_code == 200


def main():
    print("=" * 60)
    print("PRAHARI-Lite: Local Lab Validation")
    print(f"Target: {BASE}")
    print("=" * 60)

    # Check server is up
    if not test_health():
        print("\nServer not reachable. Exiting.")
        sys.exit(1)

    results = {}
    results['health']          = test_health()
    results['normal_detect']   = test_normal_flow()
    results['apt_detect']      = test_apt_flow()
    results['recon_detect']    = test_recon_flow()
    results['missing_features'] = test_missing_features()
    results['stats']           = test_stats()
    results['recent_alerts']   = test_recent_alerts()

    print("\n" + "=" * 60)
    print("Validation Summary")
    print("=" * 60)
    all_pass = True
    for test, passed in results.items():
        status = "PASS" if passed else "FAIL"
        print(f"  {test:<25} {status}")
        if not passed:
            all_pass = False

    print("=" * 60)
    if all_pass:
        print("All tests PASSED!")
        sys.exit(0)
    else:
        print("Some tests FAILED!")
        sys.exit(1)


if __name__ == '__main__':
    main()
