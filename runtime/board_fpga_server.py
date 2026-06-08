#!/usr/bin/env python3
"""
board_fpga_server.py — lightweight HTTP inference server for Pynq-Z2.

Deploy this file to the board and run as root:
  sudo python3 /home/xilinx/board_fpga_server.py

Accepts POST /detect  {"features": [15 raw floats]}
Returns  JSON         {"class_id", "class_name", "ae_error", "zero_day",
                        "latency_us", "source": "hardware"}

No pynq import. No sklearn. Uses /dev/mem directly.
Scaler parameters hardcoded — no pkl files needed on board.
"""
import json
import mmap
import os
import struct
import sys
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from socketserver import ThreadingMixIn

PORT = 5003

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

AXI_BASE  = 0x43C00000
AE_THRESH = 158206        # Q16.16 threshold


def open_mmio():
    fd  = os.open('/dev/mem', os.O_RDWR | os.O_SYNC)
    mem = mmap.mmap(fd, 4096, mmap.MAP_SHARED,
                    mmap.PROT_READ | mmap.PROT_WRITE, offset=AXI_BASE)
    return fd, mem


def wr(mem, off, val):
    struct.pack_into('<I', mem, off, int(val) & 0xFFFFFFFF)


def rd(mem, off):
    return struct.unpack_from('<I', mem, off)[0]


def scale_to_q88(raw):
    q = []
    for i, v in enumerate(raw):
        z = (float(v) - MEANS[i]) / STDS[i]
        q.append(max(-32768, min(32767, int(round(z * 256)))))
    return q


def fpga_infer(mem, q88):
    t0 = time.perf_counter()

    for i, v in enumerate(q88):
        wr(mem, 0x08 + i * 4, v & 0xFFFF)
    wr(mem, 0x00, 1)                      # pulse start

    # Poll done — no sleep, FPGA finishes in 320 ns (32 cycles × 10 ns)
    for _ in range(10000):
        if rd(mem, 0x04) & 0x1:
            break

    class_id   = rd(mem, 0x48) & 0x7
    ae_error_q = rd(mem, 0x4C)
    zero_day   = bool(rd(mem, 0x04) & 0x2)

    latency_us = (time.perf_counter() - t0) * 1e6
    return {
        "class_id":   class_id,
        "class_name": CLASS_NAMES.get(class_id, f"UNKNOWN({class_id})"),
        "ae_error":   round(ae_error_q / 65536.0, 6),
        "zero_day":   zero_day,
        "is_attack":  class_id != 0,
        "latency_us": round(latency_us, 2),
        "source":     "hardware",
    }


class InferenceHandler(BaseHTTPRequestHandler):
    # Shared mmio — opened once at server start
    _mem = None

    def log_message(self, fmt, *args):
        pass   # silence per-request access logs

    def do_GET(self):
        if self.path == '/health':
            self._respond({"status": "ok", "port": PORT})
        else:
            self._respond({"error": "not found"}, 404)

    def do_POST(self):
        try:
            length = int(self.headers.get('Content-Length', 0))
            body   = json.loads(self.rfile.read(length))
        except Exception as exc:
            self._respond({"error": str(exc)}, 400)
            return

        if self.path == '/detect':
            # Single flow: {"features": [15 values]}
            raw = body.get('features', [])
            if len(raw) != 15:
                self._respond({"error": "need exactly 15 features"}, 400)
                return
            self._respond(fpga_infer(self.__class__._mem, scale_to_q88(raw)))

        elif self.path == '/detect_batch':
            # Batch: {"batch": [[15 values], [15 values], ...]}
            batch = body.get('batch', [])
            if not batch:
                self._respond({"error": "empty batch"}, 400)
                return
            results = []
            t_batch = time.perf_counter()
            for raw in batch:
                results.append(fpga_infer(self.__class__._mem, scale_to_q88(raw)))
            total_us = (time.perf_counter() - t_batch) * 1e6
            self._respond({
                "results":        results,
                "batch_size":     len(results),
                "total_us":       round(total_us, 1),
                "per_flow_us":    round(total_us / len(results), 2),
            })

        else:
            self._respond({"error": "not found"}, 404)

    def _respond(self, data, code=200):
        body = json.dumps(data).encode()
        self.send_response(code)
        self.send_header('Content-Type',   'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)


class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True


if __name__ == '__main__':
    print(f"[board_fpga_server] Opening /dev/mem at 0x{AXI_BASE:08X}...")
    fd, mem = open_mmio()
    InferenceHandler._mem = mem
    print(f"[board_fpga_server] MMIO ready. Starting HTTP server on port {PORT}...")

    server = ThreadedHTTPServer(('0.0.0.0', PORT), InferenceHandler)
    print(f"[board_fpga_server] Listening on 0.0.0.0:{PORT}")
    try:
        server.serve_forever()
    finally:
        mem.close()
        os.close(fd)
