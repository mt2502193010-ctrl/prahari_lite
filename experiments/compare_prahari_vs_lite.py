#!/usr/bin/env python3
"""
PRAHARI-Lite: Side-by-side comparison with PRAHARI v7.
Loads outputs/validation_lite_results.csv and prints comparison table.
"""
import sys
import json
from pathlib import Path
import pandas as pd

BASE_DIR   = Path(__file__).parent.parent
OUTPUT_DIR = BASE_DIR / "outputs"

PRAHARI_V7_REFERENCE = {
    'combined_f1':  0.855,
    'cic2017_f1':   0.992,
    'cic2017_fpr':  0.0042,
    'apt_recall':   0.881,
    'recon_recall': 0.840,
    'ts_recall':    0.817,
    'nrm_recall':   0.936,
    'latency_ms':   2.06,
    'bram_kb':      640,
}

METRIC_LABELS = {
    'combined_f1':  ('Combined F1',    'higher=better'),
    'cic2017_f1':   ('CIC2017 F1',     'higher=better'),
    'cic2017_fpr':  ('CIC2017 FPR',    'lower=better'),
    'apt_recall':   ('APT Recall',     'higher=better'),
    'recon_recall': ('RECON Recall',   'higher=better'),
    'ts_recall':    ('TS Recall',      'higher=better'),
    'nrm_recall':   ('NRM Recall',     'higher=better'),
    'latency_ms':   ('Latency (ms)',   'lower=better'),
    'bram_kb':      ('BRAM (KB)',      'lower=better'),
}


def compare():
    print("=" * 70)
    print("PRAHARI-Lite vs PRAHARI v7: Comparison")
    print("=" * 70)

    # Load lite results
    results_json = OUTPUT_DIR / "validation_lite_results.json"
    results_csv  = OUTPUT_DIR / "validation_lite_results.csv"

    lite_vals = {}

    if results_json.exists():
        with open(results_json) as f:
            data = json.load(f)
        # Map to standard metric names
        lite_vals = {
            'combined_f1':  data.get('combined_f1', 0.0),
            'cic2017_fpr':  data.get('fpr', 0.0),
            'apt_recall':   data.get('apt_recall', 0.0),
            'recon_recall': data.get('recon_recall', 0.0),
            'ts_recall':    data.get('ts_recall', 0.0),
            'nrm_recall':   data.get('nrm_recall', 0.0),
            'bram_kb':      data.get('bram_kb', 0.0),
        }
        print(f"[CMP] Loaded Lite results from {results_json}")
    elif results_csv.exists():
        df = pd.read_csv(results_csv)
        for _, row in df.iterrows():
            metric = row.get('metric', '')
            if metric in PRAHARI_V7_REFERENCE:
                lite_vals[metric] = float(row.get('prahari_lite', 0.0))
        print(f"[CMP] Loaded Lite results from {results_csv}")
    else:
        print(f"[CMP] No validation results found. Run validate_lite.py first.")
        print(f"[CMP] Showing PRAHARI v7 reference only.\n")

    print(f"\n{'Metric':<20} {'Description':<20} {'PRAHARI v7':>12} {'Lite':>10} {'Delta':>10} {'Status':<15}")
    print("-" * 90)

    for key in PRAHARI_V7_REFERENCE:
        label, direction = METRIC_LABELS.get(key, (key, ''))
        v7_val = PRAHARI_V7_REFERENCE[key]
        lite_val = lite_vals.get(key, None)

        if lite_val is None:
            print(f"{label:<20} {direction:<20} {v7_val:>12.4f} {'N/A':>10} {'N/A':>10} {'N/A':<15}")
            continue

        delta = lite_val - v7_val
        if 'lower=better' in direction:
            status = 'BETTER' if delta < 0 else ('WORSE' if delta > 0 else 'SAME')
        else:
            status = 'BETTER' if delta > 0 else ('WORSE' if delta < 0 else 'SAME')

        status_marker = '+' if status == 'BETTER' else ('-' if status == 'WORSE' else '=')
        print(f"{label:<20} {direction:<20} {v7_val:>12.4f} {lite_val:>10.4f} "
              f"{delta:>+10.4f} {status_marker} {status:<13}")

    print("\n" + "=" * 70)
    print("Architecture Notes:")
    print("-" * 70)
    print(f"  PRAHARI v7:      GBM (500 trees) + IsolationForest")
    print(f"                   31 features, ~640KB BRAM, latency=2.06ms")
    print(f"                   Docker containerised, not FPGA-native")
    print(f"")
    print(f"  PRAHARI-Lite:    DecisionTree (d=12) + Autoencoder (15-8-4-8-15)")
    print(f"                   15 features, <25KB BRAM, FPGA-implementable")
    print(f"                   Novel: DT leaf purity as zero-day confidence gate")
    print(f"")
    print(f"  Key trade-off:   Lite sacrifices some F1 for 25x BRAM reduction")
    print(f"                   Gains: FPGA-native, lower latency, zero-day detection")
    print("=" * 70)


if __name__ == '__main__':
    compare()
