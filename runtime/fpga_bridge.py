#!/usr/bin/env python3
"""
FPGABridge — routes inference to Pynq-Z2 hardware over SSH.

Architecture:
  connect()  — opens persistent SSH channel, starts a board-side server loop
               (one-time Python startup + /dev/mem mmap, ~3 s first call)
  classify() — sends 15 Q8.8 ints over the open channel stdin, reads JSON back
               (~1 ms per call after connection, no per-call Python startup)
  fallback_classify() — sklearn DT on this machine if board unreachable
"""
import base64
import json
import logging
import threading
import time
from pathlib import Path
from typing import Optional

log = logging.getLogger(__name__)

# ── Transport mode ─────────────────────────────────────────────────────────────
# "http"  — POST to board_fpga_server.py running on the board (recommended)
#           No SSH overhead. Deploy board_fpga_server.py to board first.
# "ssh"   — persistent SSH stdin/stdout channel (original mode, higher latency)
TRANSPORT = "http"
BOARD_HTTP_PORT = 5003

# ── Constants ──────────────────────────────────────────────────────────────────
CLASS_NAMES = {
    0: "NORMAL", 1: "APT", 2: "RECON",
    3: "TRAFFIC_SPIKE", 4: "NR_MALWARE", 5: "ZERO_DAY",
}

MEANS = [
    6234.239404, 4004.604810, 3293.047072, 6593.248217, 15258.713687,
    -2920.625510, 83.280455, 1149956.643832, 8473172.648206, 646140.882899,
    136.469279, 386.059913, 13.406653, 0.028309, 80.296013,
]
STDS = [
    16276.139768, 121751.053505, 12446.986388, 14924.562945, 1822821.794656,
    1122323.823913, 169.272069, 9106573.249593, 26295131.513161, 16298275.252851,
    236.502914, 1199.464211, 840.129983, 0.165854, 196.683321,
]

AXI_BASE   = 0x43C00000
AE_THRESH  = 158206       # Q16.16 threshold (= 2.414035 float × 65536)
DT_PURITY_THRESH = 0.75   # mirrors fusion_logic.v PURITY_THRESH/256

# ── Board-side server loop ─────────────────────────────────────────────────────
# Runs on the Pynq-Z2 as root (via sudo -S).
# Reads feature JSON lines from stdin, writes result JSON lines to stdout.
# Uses /dev/mem directly — no pynq import per-call overhead.
_BOARD_SCRIPT = b"""\
import sys, time, json, mmap, os, struct

BASE = 0x43C00000
fd   = os.open('/dev/mem', os.O_RDWR | os.O_SYNC)
mem  = mmap.mmap(fd, 4096, mmap.MAP_SHARED,
                 mmap.PROT_READ | mmap.PROT_WRITE, offset=BASE)

def rd(off):      return struct.unpack_from('<I', mem, off)[0]
def wr(off, val): struct.pack_into('<I', mem, off, int(val) & 0xFFFFFFFF)

sys.stdout.write('READY\\n')
sys.stdout.flush()

for raw in sys.stdin:
    raw = raw.strip()
    if not raw:
        continue
    if raw == 'EXIT':
        break
    try:
        feats = json.loads(raw)
        for i, v in enumerate(feats):
            wr(0x08 + i * 4, int(v) & 0xFFFF)
        wr(0x00, 1)
        time.sleep(100e-6)
        for _ in range(2000):
            if rd(0x04) & 0x1:
                break
            time.sleep(1e-6)
        cls = rd(0x48) & 0x7
        ae  = rd(0x4C)
        zd  = bool(rd(0x04) & 0x2)
        sys.stdout.write(json.dumps({'class_id': cls, 'ae_error': ae, 'zero_day': zd}) + '\\n')
    except Exception as exc:
        sys.stdout.write(json.dumps({'error': str(exc)}) + '\\n')
    sys.stdout.flush()

mem.close()
os.close(fd)
"""

# Module-level cache for software-fallback models (loaded once, reused)
_sw_model_cache: dict = {}


def _load_sw_models() -> dict:
    if _sw_model_cache:
        return _sw_model_cache
    import joblib
    base = Path(__file__).parent.parent / "models"
    _sw_model_cache["scaler"] = joblib.load(base / "scaler_lite_v1.pkl")
    _sw_model_cache["dt"]     = joblib.load(base / "dt_lite_v2.pkl")
    return _sw_model_cache


# ── FPGABridge ─────────────────────────────────────────────────────────────────
class FPGABridge:
    """
    Persistent SSH bridge to the Pynq-Z2 for low-latency FPGA inference.

    Usage:
        bridge = FPGABridge()
        bridge.connect()           # ~3 s first call (Python/mmap startup on board)
        result = bridge.classify([raw_feat0, ..., raw_feat14])
    """

    def __init__(
        self,
        board_ip: str = "192.168.2.99",
        user: str = "xilinx",
        password: str = "xilinx",
    ):
        self._board_ip = board_ip
        self._user     = user
        self._password = password

        self._ssh:     Optional[object] = None   # paramiko.SSHClient
        self._channel: Optional[object] = None   # paramiko channel (kept open)
        self._lock     = threading.Lock()
        self._connected = False

        # Telemetry
        self._total_hw:     int   = 0
        self._total_sw:     int   = 0
        self._lat_sum:      float = 0.0
        self._lat_count:    int   = 0

    # ── Connection management ──────────────────────────────────────────────────

    def connect(self) -> bool:
        """
        HTTP mode:  verify board_fpga_server.py is reachable on port 5003.
        SSH mode:   open persistent SSH channel + start board server loop.
        Returns True on success.
        """
        if TRANSPORT == "http":
            return self._connect_http()
        return self._connect_ssh()

    def _connect_http(self) -> bool:
        """Probe the board HTTP server — no long setup needed."""
        import urllib.request
        url = f"http://{self._board_ip}:{BOARD_HTTP_PORT}/health"
        try:
            with urllib.request.urlopen(url, timeout=5) as r:
                data = json.loads(r.read())
            if data.get("status") == "ok":
                self._connected = True
                log.info(f"[FPGABridge] HTTP board server reachable at {url}")
                return True
        except Exception as exc:
            log.error(f"[FPGABridge] HTTP connect failed: {exc}")
        self._connected = False
        return False

    def _connect_ssh(self) -> bool:
        """Legacy SSH persistent channel (fallback if HTTP server not deployed)."""
        try:
            import paramiko
        except ImportError:
            log.error("[FPGABridge] paramiko not installed — pip install paramiko")
            return False
        try:
            client = paramiko.SSHClient()
            client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            client.connect(self._board_ip, username=self._user,
                           password=self._password, timeout=10,
                           allow_agent=False, look_for_keys=False)
            self._ssh = client

            script_b64 = base64.b64encode(_BOARD_SCRIPT).decode()
            cmd = ("sudo -S python3 -c \""
                   f"import base64,sys; exec(base64.b64decode('{script_b64}').decode())"
                   "\"")
            channel = client.get_transport().open_session()
            channel.exec_command(cmd)
            time.sleep(0.15)
            channel.sendall(f"{self._password}\n".encode())

            deadline = time.time() + 15.0
            buf = b""
            while time.time() < deadline:
                if channel.recv_ready():
                    buf += channel.recv(256)
                    if b"READY" in buf:
                        break
                elif channel.exit_status_ready():
                    log.error("[FPGABridge] Board process exited early")
                    channel.close()
                    return False
                time.sleep(0.05)
            else:
                log.error("[FPGABridge] Board did not send READY within 15 s")
                channel.close()
                return False

            self._channel   = channel
            self._connected = True
            log.info(f"[FPGABridge] SSH connected to {self._board_ip} — READY")
            return True
        except Exception as exc:
            log.error(f"[FPGABridge] SSH connect failed: {exc}")
            self._connected = False
            return False

    def disconnect(self):
        if TRANSPORT == "ssh":
            if self._channel:
                try:
                    self._channel.sendall(b"EXIT\n")
                except Exception:
                    pass
                self._channel.close()
            if self._ssh:
                self._ssh.close()
        self._connected = False
        log.info("[FPGABridge] Disconnected")

    def is_connected(self) -> bool:
        if not self._connected:
            return False
        if TRANSPORT == "ssh":
            if self._channel is None or self._channel.closed or self._channel.exit_status_ready():
                self._connected = False
                return False
        return True

    # ── Feature scaling ────────────────────────────────────────────────────────

    @staticmethod
    def scale_to_q88(raw_features: list) -> list:
        """Raw physical values → z-scores → signed Q8.8 integers."""
        q88 = []
        for i, v in enumerate(raw_features):
            z = (float(v) - MEANS[i]) / STDS[i]
            q = int(round(z * 256))
            q88.append(max(-32768, min(32767, q)))
        return q88

    # ── Hardware inference ─────────────────────────────────────────────────────

    def classify(self, raw_features: list) -> dict:
        """
        Scale raw features, send to FPGA, return result dict.
        Uses HTTP (board_fpga_server) or SSH depending on TRANSPORT setting.
        Falls back to software automatically on any error.
        Thread-safe.
        """
        if TRANSPORT == "http":
            return self._classify_http(raw_features)
        return self._classify_ssh(raw_features)

    def _classify_http(self, raw_features: list) -> dict:
        import urllib.request
        t0 = time.perf_counter()
        if not self.is_connected():
            return self._sw_result(raw_features, "not_connected")
        try:
            body = json.dumps({"features": raw_features}).encode()
            req  = urllib.request.Request(
                f"http://{self._board_ip}:{BOARD_HTTP_PORT}/detect",
                data=body,
                headers={"Content-Type": "application/json"},
            )
            with urllib.request.urlopen(req, timeout=2) as r:
                hw = json.loads(r.read())
            if "error" in hw:
                raise RuntimeError(hw["error"])
        except Exception as exc:
            log.warning(f"[FPGABridge] HTTP classify error — SW fallback: {exc}")
            self._connected = False
            return self._sw_result(raw_features, str(exc))

        latency_us = (time.perf_counter() - t0) * 1e6
        self._total_hw  += 1
        self._lat_sum   += latency_us
        self._lat_count += 1

        result = {
            "final_label":   hw.get("class_name", "UNKNOWN"),
            "dt_label":      hw.get("class_name", "UNKNOWN"),
            "dt_purity":     None,
            "dt_confident":  not hw.get("zero_day", False),
            "ae_error":      hw.get("ae_error"),
            "ae_anomaly":    (hw.get("ae_error", 0) or 0) > (AE_THRESH / 65536.0),
            "routing":       "AE_FLAGGED" if hw.get("zero_day") else "DT_CONFIDENT",
            "is_attack":     hw.get("is_attack", False),
            "is_zero_day":   hw.get("zero_day", False),
            "latency_us":    round(latency_us, 1),
            "source":        "hardware",
        }
        return result

    def _classify_ssh(self, raw_features: list) -> dict:
        t0 = time.perf_counter()
        q88 = self.scale_to_q88(raw_features)

        with self._lock:
            if not self.is_connected():
                return self._sw_result(raw_features, "not_connected")
            try:
                self._channel.sendall((json.dumps(q88) + "\n").encode())

                deadline = time.perf_counter() + 0.5
                buf = b""
                while time.perf_counter() < deadline:
                    if self._channel.recv_ready():
                        buf += self._channel.recv(512)
                        if b"\n" in buf:
                            break
                    time.sleep(0.0002)
                else:
                    raise TimeoutError("board timeout after 500 ms")

                line = buf.split(b"\n")[0].decode().strip()
                hw = json.loads(line)
                if "error" in hw:
                    raise RuntimeError(hw["error"])

            except Exception as exc:
                log.warning(f"[FPGABridge] SSH classify error — SW fallback: {exc}")
                self._connected = False
                return self._sw_result(raw_features, str(exc))

        latency_us = (time.perf_counter() - t0) * 1e6
        self._total_hw  += 1
        self._lat_sum   += latency_us
        self._lat_count += 1

        class_id      = int(hw["class_id"])
        ae_error_q    = int(hw["ae_error"])
        zero_day      = bool(hw.get("zero_day", class_id == 5))
        ae_error_f    = ae_error_q / 65536.0
        ae_anomaly    = ae_error_q > AE_THRESH
        class_name    = CLASS_NAMES.get(class_id, f"UNKNOWN({class_id})")
        is_attack     = class_id not in (0,)
        is_zero_day   = (class_id == 5) or zero_day

        routing = "AE_FLAGGED" if is_zero_day else "DT_CONFIDENT"

        return {
            "final_label":   class_name,
            "dt_label":      class_name,
            "dt_purity":     None,          # not exposed in AXI register map
            "dt_confident":  not is_zero_day,
            "ae_error":      round(ae_error_f, 6),
            "ae_anomaly":    ae_anomaly,
            "routing":       routing,
            "is_attack":     is_attack,
            "is_zero_day":   is_zero_day,
            "latency_us":    round(latency_us, 1),
            "source":        "hardware",
        }

    # ── Software fallback ──────────────────────────────────────────────────────

    def fallback_classify(self, raw_features: list) -> dict:
        """Explicitly invoke software fallback (for testing or forced SW mode)."""
        return self._sw_result(raw_features, "manual")

    def _sw_result(self, raw_features: list, reason: str) -> dict:
        self._total_sw += 1
        t0 = time.perf_counter()
        try:
            import numpy as np
            models = _load_sw_models()
            x = np.nan_to_num(np.array(raw_features, dtype=float)).reshape(1, -1)
            x_s = models["scaler"].transform(x)
            pred   = int(models["dt"].predict(x_s)[0])
            proba  = models["dt"].predict_proba(x_s)[0]
            purity = float(proba.max())

            class_name  = CLASS_NAMES.get(pred, "UNKNOWN")
            is_attack   = pred != 0
            dt_confident = purity >= DT_PURITY_THRESH
            routing = "DT_CONFIDENT" if dt_confident else "DT_LOW_CONF_AE_NORMAL"

            return {
                "final_label":   class_name,
                "dt_label":      class_name,
                "dt_purity":     round(purity, 4),
                "dt_confident":  dt_confident,
                "ae_error":      None,
                "ae_anomaly":    False,
                "routing":       routing,
                "is_attack":     is_attack,
                "is_zero_day":   False,
                "latency_us":    round((time.perf_counter() - t0) * 1e6, 1),
                "source":        "software",
            }
        except Exception as exc:
            log.error(f"[FPGABridge] SW fallback failed: {exc}")
            return {
                "final_label": "NORMAL", "dt_label": "NORMAL",
                "dt_purity": None, "dt_confident": False,
                "ae_error": None, "ae_anomaly": False,
                "routing": "DT_CONFIDENT",
                "is_attack": False, "is_zero_day": False,
                "latency_us": 0.0,
                "source": "software",
                "error": str(exc),
            }

    # ── Telemetry ──────────────────────────────────────────────────────────────

    def status(self) -> dict:
        avg = self._lat_sum / self._lat_count if self._lat_count > 0 else 0.0
        return {
            "connected":            self.is_connected(),
            "board_ip":             self._board_ip,
            "avg_latency_us":       round(avg, 1),
            "total_hw_inferences":  self._total_hw,
            "total_sw_fallbacks":   self._total_sw,
        }
