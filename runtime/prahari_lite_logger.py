"""
prahari_lite_logger.py — Auto-documentation module for PRAHARI-Lite experiments.

Usage:
    from prahari_lite_logger import PrahariLiteLogger
    log = PrahariLiteLogger(script_name="train_decision_tree", version="v1")

    log.section("Data Loading")
    log.param("Synthetic rows", 50000)
    log.decision("Use synthetic fallback", "No real CSVs available in this env")
    log.artifact("models/dt_lite_v1.pkl", notes="DT trained on synthetic data")
    log.save()

Produces (append-only):
    docs/experiment_log_lite.md
    docs/experiment_log_lite.json
"""

import os
import sys
import json
import socket
import hashlib
import platform
import subprocess
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR  = Path(__file__).parent.parent
DOCS      = BASE_DIR / "docs"
MD_PATH   = DOCS / "experiment_log_lite.md"
JSON_PATH = DOCS / "experiment_log_lite.json"
CSV_PATH  = BASE_DIR / "models" / "model_registry_lite.csv"


class _NumpyEncoder(json.JSONEncoder):
    """Handles numpy scalar types that the default encoder rejects."""
    def default(self, obj):
        try:
            import numpy as np
            if isinstance(obj, np.bool_):
                return bool(obj)
            if isinstance(obj, np.integer):
                return int(obj)
            if isinstance(obj, np.floating):
                return float(obj)
            if isinstance(obj, np.ndarray):
                return obj.tolist()
        except ImportError:
            pass
        return super().default(obj)


_pd = None
def _pandas():
    global _pd
    if _pd is None:
        import pandas as pd
        _pd = pd
    return _pd


def _sha256(path):
    """Return hex SHA256 of a file, or 'FILE_NOT_FOUND' if missing."""
    try:
        h = hashlib.sha256()
        with open(path, 'rb') as f:
            for block in iter(lambda: f.read(65536), b''):
                h.update(block)
        return h.hexdigest()
    except FileNotFoundError:
        return 'FILE_NOT_FOUND'
    except Exception as e:
        return f'ERROR:{e}'


def _git_hash():
    """Return short git commit hash, or 'no-git'."""
    try:
        result = subprocess.run(
            ['git', '-C', str(BASE_DIR), 'rev-parse', '--short', 'HEAD'],
            capture_output=True, text=True, timeout=3)
        return result.stdout.strip() if result.returncode == 0 else 'no-git'
    except Exception:
        return 'no-git'


def _env_name():
    """Return conda/venv environment name, or 'system'."""
    conda = os.environ.get('CONDA_DEFAULT_ENV')
    if conda:
        return f'conda:{conda}'
    venv = os.environ.get('VIRTUAL_ENV')
    if venv:
        return f'venv:{os.path.basename(venv)}'
    return 'system'


def _df_to_markdown(df):
    """Convert a pandas DataFrame to a Markdown table string."""
    lines = []
    cols = list(df.columns)
    lines.append('| ' + ' | '.join(str(c) for c in cols) + ' |')
    lines.append('|' + '|'.join('---' for _ in cols) + '|')
    for _, row in df.iterrows():
        cells = []
        for c in cols:
            v = row[c]
            if isinstance(v, float):
                cells.append(f'{v:.4f}' if not (v != v) else 'N/A')
            else:
                cells.append(str(v) if v is not None else 'N/A')
        lines.append('| ' + ' | '.join(cells) + ' |')
    return '\n'.join(lines)


def _df_to_records(df):
    """Convert DataFrame to list of dicts (JSON-serialisable)."""
    records = []
    for _, row in df.iterrows():
        rec = {}
        for c in df.columns:
            v = row[c]
            if hasattr(v, 'item'):
                v = v.item()
            if v != v:
                v = None
            rec[c] = v
        records.append(rec)
    return records


class PrahariLiteLogger:
    """
    Append-only experiment logger for PRAHARI-Lite runs.
    Completely isolated from PRAHARI v7 logger.
    Writes to prahari_lite/docs/experiment_log_lite.md and .json
    """

    def __init__(self, script_name: str, version: str):
        DOCS.mkdir(parents=True, exist_ok=True)

        self.script_name = script_name
        self.version = version
        self.ts = datetime.now(timezone.utc).isoformat(timespec='seconds')

        self.meta = {
            'timestamp':   self.ts,
            'script_name': script_name,
            'version':     version,
            'system':      'prahari_lite',
            'git_hash':    _git_hash(),
            'python':      sys.version.split()[0],
            'os':          platform.platform(),
            'hostname':    socket.gethostname(),
            'env':         _env_name(),
        }

        self._sections  = []
        self._cur_sec   = None
        self._artifacts = []
        self._f1_combined = None

    def section(self, name: str):
        sec = {'name': name, 'entries': []}
        self._sections.append(sec)
        self._cur_sec = sec

    def _entry(self, entry: dict):
        if self._cur_sec is None:
            self.section('General')
        self._cur_sec['entries'].append(entry)

    def param(self, key: str, value):
        if hasattr(value, 'item'):
            value = value.item()
        self._entry({'type': 'param', 'key': key, 'value': value})

    def decision(self, what: str, why: str):
        self._entry({'type': 'decision', 'what': what, 'why': why})

    def finding(self, title: str, detail: str):
        self._entry({'type': 'finding', 'title': title, 'detail': detail})

    def table(self, name: str, df):
        self._entry({'type': 'table', 'name': name, 'data': _df_to_records(df),
                     '_df': df})

    def check(self, name: str, passed: bool, value: float, note: str = ''):
        if 'combined f1' in name.lower() or 'f1 >=' in name.lower():
            if passed:
                self._f1_combined = round(float(value), 4)
        self._entry({'type': 'check', 'name': name, 'passed': passed,
                     'value': float(value), 'note': note})

    def artifact(self, path: str, notes: str = ''):
        full_path = path if os.path.isabs(path) else str(BASE_DIR / path)
        sha = _sha256(full_path)
        size = os.path.getsize(full_path) if os.path.exists(full_path) else -1
        rec = {
            'path':     full_path,
            'relpath':  os.path.relpath(full_path, str(BASE_DIR)),
            'sha256':   sha,
            'size_kb':  round(size / 1024, 1),
            'notes':    notes,
            'is_model': any(full_path.endswith(ext)
                            for ext in ('.pkl', '.h5', '.pt', '.onnx')),
        }
        self._artifacts.append(rec)
        self._entry({'type': 'artifact',
                     'path': rec['relpath'], 'sha256': sha, 'notes': notes})

    def save(self):
        """Write/append to experiment_log_lite.md and experiment_log_lite.json."""
        run_record = self._build_run_record()
        self._write_markdown(run_record)
        prev_run = self._load_last_json()
        self._write_json(run_record)
        self._write_model_registry(run_record)
        self._print_diff(run_record, prev_run)
        print(f"\n[PrahariLiteLogger] Run documented → {DOCS}", flush=True)

    def _build_run_record(self):
        sections_out = []
        for sec in self._sections:
            entries_out = []
            for e in sec['entries']:
                entry = {k: v for k, v in e.items() if k != '_df'}
                entries_out.append(entry)
            sections_out.append({'name': sec['name'], 'entries': entries_out})

        return {
            'meta':      self.meta,
            'sections':  sections_out,
            'artifacts': [
                {k: v for k, v in a.items() if k != '_df'}
                for a in self._artifacts
            ],
        }

    def _write_markdown(self, record):
        m = record['meta']
        ts = m['timestamp'].replace('T', ' ').replace('+00:00', ' UTC')

        lines = [
            '\n---\n',
            f"## prahari_lite Run: {m['script_name']} ({m['version']}) — {ts}",
            f"**Git:** `{m['git_hash']}` | "
            f"**Python:** {m['python']} | "
            f"**Host:** {m['hostname']} | "
            f"**Env:** {m['env']}",
            '',
        ]

        for sec in self._sections:
            lines.append(f"### {sec['name']}")
            for e in sec['entries']:
                t = e['type']
                if t == 'param':
                    v = e['value']
                    if isinstance(v, dict):
                        v = json.dumps(v, separators=(', ', ': '), cls=_NumpyEncoder)
                    lines.append(f"- **{e['key']}:** {v}")
                elif t == 'decision':
                    lines.append(f"- **Decision:** {e['what']} — _{e['why']}_")
                elif t == 'finding':
                    lines.append(f"\n**Finding:** {e['title']}  ")
                    lines.append(f"_{e['detail']}_")
                elif t == 'check':
                    flag = 'PASS' if e['passed'] else 'FAIL'
                    note = f" — {e['note']}" if e.get('note') else ''
                    lines.append(
                        f"- [{flag}] {e['name']} ({e['value']:.4f}){note}")
                elif t == 'table':
                    df = next((s['_df'] for s in sec['entries'] if '_df' in s), None)
                    if df is None:
                        pd = _pandas()
                        df = pd.DataFrame(e['data'])
                    lines.append(f"\n**Table: {e['name']}**")
                    lines.append(_df_to_markdown(df))
                elif t == 'artifact':
                    sha_short = e['sha256'][:12] + '...' if len(e['sha256']) > 12 else e['sha256']
                    lines.append(f"- `{e['path']}` (SHA256: `{sha_short}`)"
                                 + (f" — {e['notes']}" if e.get('notes') else ''))
            lines.append('')

        if self._artifacts:
            lines.append('### Artifacts')
            for a in self._artifacts:
                sha_short = a['sha256'][:12] + '...'
                lines.append(
                    f"- `{a['relpath']}` ({a['size_kb']} KB) SHA256: `{sha_short}`"
                    + (f" — {a['notes']}" if a.get('notes') else ''))
            lines.append('')

        md_block = '\n'.join(lines)

        if not MD_PATH.exists():
            with open(MD_PATH, 'w', encoding='utf-8') as f:
                f.write('# PRAHARI-Lite Experiment Log\n\n'
                        '*Append-only. Each run adds a new section.*\n'
                        '*Isolated from PRAHARI v7 at ../docker_env/*\n')

        with open(MD_PATH, 'a', encoding='utf-8') as f:
            f.write(md_block)

    def _write_json(self, record):
        runs = []
        if JSON_PATH.exists():
            try:
                with open(JSON_PATH, 'r', encoding='utf-8') as f:
                    runs = json.load(f)
                if not isinstance(runs, list):
                    runs = [runs]
            except (json.JSONDecodeError, IOError):
                runs = []

        runs.append(record)

        with open(JSON_PATH, 'w', encoding='utf-8') as f:
            json.dump(runs, f, indent=2, cls=_NumpyEncoder)

    def _write_model_registry(self, record):
        if not CSV_PATH.exists():
            with open(CSV_PATH, 'w', encoding='utf-8') as f:
                f.write('timestamp,model_name,model_type,f1_score,fpr,bram_kb,sha256,notes\n')

        ts = record['meta']['timestamp']
        ver = record['meta']['version']
        f1 = self._f1_combined if self._f1_combined is not None else ''

        rows = []
        for a in self._artifacts:
            if a.get('is_model'):
                filename = os.path.basename(a['relpath'])
                rows.append(
                    f"{ts},{filename},{ver},{f1},,,"
                    f"{a['sha256'][:16]},{a.get('notes','')}\n"
                )

        if rows:
            with open(CSV_PATH, 'a', encoding='utf-8') as f:
                f.writelines(rows)

    def _load_last_json(self):
        if not JSON_PATH.exists():
            return None
        try:
            with open(JSON_PATH, 'r', encoding='utf-8') as f:
                runs = json.load(f)
            if isinstance(runs, list) and runs:
                return runs[-1]
        except Exception:
            pass
        return None

    def _print_diff(self, current, previous):
        if previous is None:
            print("\n[PrahariLiteLogger] First prahari_lite run — no previous run to diff against.")
            return

        prev_ts = previous.get('meta', {}).get('timestamp', 'unknown')
        print(f"\n[PrahariLiteLogger] DELTA vs previous run ({prev_ts})")
        print("─" * 60)
        changed = False

        cur_checks = self._extract_checks(current)
        prev_checks = self._extract_checks(previous)
        all_names = sorted(set(cur_checks) | set(prev_checks))
        for name in all_names:
            cv = cur_checks.get(name)
            pv = prev_checks.get(name)
            if cv is None:
                print(f"  [CHECK removed] {name}")
                changed = True
            elif pv is None:
                stat = 'PASS' if cv['passed'] else 'FAIL'
                print(f"  [NEW] [{stat}] {name} = {cv['value']:.4f}")
                changed = True
            else:
                if cv['passed'] != pv['passed']:
                    old_s = 'PASS' if pv['passed'] else 'FAIL'
                    new_s = 'PASS' if cv['passed'] else 'FAIL'
                    print(f"  {old_s}→{new_s} {name}: {pv['value']:.4f} → {cv['value']:.4f}")
                    changed = True
                elif abs(cv['value'] - pv['value']) > 0.01:
                    delta = cv['value'] - pv['value']
                    arrow = '↑' if delta > 0 else '↓'
                    print(f"  {arrow} {name}: {pv['value']:.4f} → {cv['value']:.4f} "
                          f"({delta:+.4f})")
                    changed = True

        cur_arts = {a['relpath'] for a in current.get('artifacts', [])}
        prev_arts = {a['relpath'] for a in previous.get('artifacts', [])}
        for a in sorted(cur_arts - prev_arts):
            print(f"  [+artifact] {a}")
            changed = True
        for a in sorted(prev_arts - cur_arts):
            print(f"  [-artifact] {a}")
            changed = True

        if not changed:
            print("  No significant changes (all metrics within 0.01).")
        print("─" * 60)

    @staticmethod
    def _extract_checks(record):
        result = {}
        for sec in record.get('sections', []):
            for e in sec.get('entries', []):
                if e.get('type') == 'check':
                    result[e['name']] = {'passed': e['passed'], 'value': e['value']}
        return result

    @staticmethod
    def _extract_decisions(record):
        result = []
        for sec in record.get('sections', []):
            for e in sec.get('entries', []):
                if e.get('type') == 'decision':
                    result.append(e['what'])
        return result
