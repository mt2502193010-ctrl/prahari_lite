#!/usr/bin/env python3
"""
PRAHARI-Lite: Leaf Purity Analysis
Analyses DT leaf purity distribution and generates plots.
"""
import sys
import warnings
from pathlib import Path
import numpy as np
import pandas as pd
import joblib

warnings.filterwarnings('ignore')

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

BASE_DIR    = Path(__file__).parent.parent
MODEL_DIR   = BASE_DIR / "models"
OUTPUT_DIR  = BASE_DIR / "outputs"
RUNTIME_DIR = BASE_DIR / "runtime"

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

CLASSES = ['NORMAL', 'APT', 'RECON', 'TRAFFIC_SPIKE', 'NR_MALWARE']
AMBER = '#F59E0B'
DARK_BG = '#0f172a'
SURFACE = '#1e293b'


def compute_leaf_depth(tree, node_id):
    """Compute depth of a node by traversing from root."""
    depth = 0
    current = 0  # root
    while current != node_id:
        left  = tree.children_left[current]
        right = tree.children_right[current]
        if left == node_id or (left != -1 and _is_ancestor(tree, left, node_id)):
            current = left
        else:
            current = right
        depth += 1
        if depth > tree.max_depth + 1:
            break  # safety
    return depth


def _is_ancestor(tree, node, target):
    """Check if node is ancestor of target."""
    if node == target:
        return True
    if tree.children_left[node] == -1:
        return False
    return (_is_ancestor(tree, tree.children_left[node], target) or
            _is_ancestor(tree, tree.children_right[node], target))


def compute_depths_iterative(tree):
    """Compute depth for all nodes iteratively (fast)."""
    depths = np.zeros(tree.node_count, dtype=int)
    stack = [(0, 0)]  # (node_id, depth)
    while stack:
        node_id, depth = stack.pop()
        depths[node_id] = depth
        left  = tree.children_left[node_id]
        right = tree.children_right[node_id]
        if left != -1:
            stack.append((left, depth + 1))
        if right != -1:
            stack.append((right, depth + 1))
    return depths


def analyse():
    print("=" * 60)
    print("PRAHARI-Lite: Leaf Purity Analysis")
    print("=" * 60)

    dt_path = MODEL_DIR / "dt_lite_v1.pkl"
    if not dt_path.exists():
        print(f"[LPA] ERROR: {dt_path} not found. Run train_decision_tree.py first.")
        sys.exit(1)

    dt = joblib.load(dt_path)
    tree_ = dt.tree_

    print(f"[LPA] Loaded DT: {tree_.node_count} nodes, depth={dt.get_depth()}")

    # Compute depths
    depths = compute_depths_iterative(tree_)

    # Analyse each leaf
    records = []
    for i in range(tree_.node_count):
        if tree_.children_left[i] == -1:  # leaf
            values = tree_.value[i][0]
            total = values.sum()
            purity = float(values.max() / total) if total > 0 else 0.0
            dominant_idx = int(values.argmax())
            dominant_class = CLASSES[dominant_idx] if dominant_idx < len(CLASSES) else 'UNKNOWN'
            depth = int(depths[i])
            n_samples = int(tree_.n_node_samples[i])

            records.append({
                'leaf_id':        i,
                'depth':          depth,
                'purity':         purity,
                'n_samples':      n_samples,
                'dominant_class': dominant_class,
                'dominant_count': int(values.max()),
                'total_count':    int(total),
            })

    purity_df = pd.DataFrame(records)
    purity_df.to_csv(OUTPUT_DIR / "leaf_purity_analysis.csv", index=False)
    print(f"[LPA] Saved leaf purity analysis: {len(purity_df)} leaves")

    # Statistics
    print(f"\n[LPA] Leaf Purity Statistics:")
    print(f"  Mean purity:   {purity_df['purity'].mean():.4f}")
    print(f"  Median purity: {purity_df['purity'].median():.4f}")
    print(f"  Std purity:    {purity_df['purity'].std():.4f}")
    print(f"  Min purity:    {purity_df['purity'].min():.4f}")
    print(f"  Max purity:    {purity_df['purity'].max():.4f}")
    print(f"  Leaves >= 0.9: {(purity_df['purity'] >= 0.9).sum()}")
    print(f"  Leaves >= 0.7: {(purity_df['purity'] >= 0.7).sum()}")

    # Threshold sweep
    thresholds = np.arange(0.5, 1.01, 0.01)
    sweep_records = []
    for thresh in thresholds:
        high_purity = purity_df[purity_df['purity'] >= thresh]
        low_purity  = purity_df[purity_df['purity'] < thresh]
        n_high = len(high_purity)
        n_low  = len(low_purity)
        pct_high = 100 * n_high / len(purity_df) if len(purity_df) > 0 else 0
        mean_high_purity = high_purity['purity'].mean() if len(high_purity) > 0 else 0
        sweep_records.append({
            'threshold':        round(thresh, 2),
            'n_high_purity':    n_high,
            'n_low_purity':     n_low,
            'pct_high_purity':  round(pct_high, 2),
            'mean_high_purity': round(mean_high_purity, 4),
        })

    sweep_df = pd.DataFrame(sweep_records)
    sweep_df.to_csv(OUTPUT_DIR / "purity_threshold_sweep.csv", index=False)
    print(f"\n[LPA] Saved purity threshold sweep to outputs/purity_threshold_sweep.csv")

    # Plots
    print("\n[LPA] Generating plots...")

    # --- Plot 1: Leaf Purity Histogram ---
    fig, ax = plt.subplots(figsize=(10, 6))
    fig.patch.set_facecolor(DARK_BG)
    ax.set_facecolor(SURFACE)

    colors = [AMBER if c == 'NORMAL' else '#ef4444' if c == 'APT'
              else '#22c55e' if c == 'RECON' else '#3b82f6'
              if c == 'TRAFFIC_SPIKE' else '#a78bfa'
              for c in purity_df['dominant_class']]

    ax.hist(purity_df['purity'], bins=50, color=AMBER, edgecolor='#334155',
            alpha=0.8)
    ax.axvline(purity_df['purity'].mean(), color='#ef4444', linestyle='--',
               linewidth=2, label=f"Mean={purity_df['purity'].mean():.3f}")
    ax.axvline(0.7, color='#22c55e', linestyle=':', linewidth=2,
               label="Threshold=0.70")
    ax.set_xlabel('Leaf Purity', color='#94a3b8')
    ax.set_ylabel('Count', color='#94a3b8')
    ax.set_title('PRAHARI-Lite: Leaf Purity Distribution', color=AMBER, fontsize=14)
    ax.legend(facecolor=SURFACE, edgecolor='#334155', labelcolor='#f1f5f9')
    ax.tick_params(colors='#94a3b8')
    for spine in ax.spines.values():
        spine.set_edgecolor('#334155')

    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / "leaf_purity_histogram.png", dpi=150, bbox_inches='tight',
                facecolor=DARK_BG)
    plt.close()
    print("[LPA] Saved leaf_purity_histogram.png")

    # --- Plot 2: Purity vs Depth ---
    fig, ax = plt.subplots(figsize=(10, 6))
    fig.patch.set_facecolor(DARK_BG)
    ax.set_facecolor(SURFACE)

    scatter = ax.scatter(purity_df['depth'], purity_df['purity'],
                         c=purity_df['purity'], cmap='RdYlGn',
                         alpha=0.6, s=30, edgecolors='none')
    plt.colorbar(scatter, ax=ax, label='Purity').set_label('Purity', color='#94a3b8')
    ax.axhline(0.7, color='#22c55e', linestyle='--', linewidth=2, label='Threshold=0.70')
    ax.set_xlabel('Leaf Depth', color='#94a3b8')
    ax.set_ylabel('Leaf Purity', color='#94a3b8')
    ax.set_title('PRAHARI-Lite: Purity vs Tree Depth', color=AMBER, fontsize=14)
    ax.legend(facecolor=SURFACE, edgecolor='#334155', labelcolor='#f1f5f9')
    ax.tick_params(colors='#94a3b8')
    for spine in ax.spines.values():
        spine.set_edgecolor('#334155')

    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / "purity_vs_depth.png", dpi=150, bbox_inches='tight',
                facecolor=DARK_BG)
    plt.close()
    print("[LPA] Saved purity_vs_depth.png")

    # --- Plot 3: Purity Threshold vs Coverage ---
    fig, ax1 = plt.subplots(figsize=(10, 6))
    fig.patch.set_facecolor(DARK_BG)
    ax1.set_facecolor(SURFACE)

    ax1.plot(sweep_df['threshold'], sweep_df['pct_high_purity'],
             color=AMBER, linewidth=2, label='% Leaves above threshold')
    ax1.set_xlabel('Purity Threshold', color='#94a3b8')
    ax1.set_ylabel('% Leaves above threshold', color=AMBER)
    ax1.tick_params(colors='#94a3b8')

    ax2 = ax1.twinx()
    ax2.set_facecolor(SURFACE)
    ax2.plot(sweep_df['threshold'], sweep_df['mean_high_purity'],
             color='#22c55e', linewidth=2, linestyle='--',
             label='Mean purity of high-purity leaves')
    ax2.set_ylabel('Mean purity of high-purity leaves', color='#22c55e')
    ax2.tick_params(colors='#94a3b8')

    ax1.set_title('PRAHARI-Lite: Purity Threshold Sweep', color=AMBER, fontsize=14)

    lines1, labels1 = ax1.get_legend_handles_labels()
    lines2, labels2 = ax2.get_legend_handles_labels()
    ax1.legend(lines1 + lines2, labels1 + labels2,
               facecolor=SURFACE, edgecolor='#334155', labelcolor='#f1f5f9')
    for spine in ax1.spines.values():
        spine.set_edgecolor('#334155')
    for spine in ax2.spines.values():
        spine.set_edgecolor('#334155')

    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / "purity_threshold_roc.png", dpi=150, bbox_inches='tight',
                facecolor=DARK_BG)
    plt.close()
    print("[LPA] Saved purity_threshold_roc.png")

    print("\n[LPA] Analysis complete!")
    return purity_df, sweep_df


if __name__ == '__main__':
    analyse()
