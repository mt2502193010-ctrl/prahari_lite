# PRAHARI-Lite — Future Work and Research Directions
**Last updated:** 2026-06-08  
**Context:** Edge deployment at signal centres, traffic flowing toward datacentre

Each item is tagged: **[HW]** hardware/RTL, **[ML]** model/algorithm, **[SYS]** system/deployment, **[SEC]** security.  
Priority: **P1** = immediate gap, **P2** = medium-term, **P3** = long-term/research

---

## P1 — Immediate Gaps (blocks production deployment)

### [SYS] C/embedded AXI driver
**What:** Replace Python `/dev/mem` calls with a kernel module or bare-metal C function for AXI register access.  
**Why:** Python `/dev/mem` costs ~25 µs per register write on the Cortex-A9 (kernel TLB + cache miss). 15 writes = ~375 µs overhead that dwarfs the 320 ns FPGA computation. A C driver reduces this to ~2 µs total.  
**Impact:** Per-flow system latency drops from ~410 µs to ~12 µs. The 73× hardware speedup becomes observable in system measurements.  
**Effort:** ~1 week. No re-synthesis.

### [HW] Wire-speed feature extraction in FPGA
**What:** Move the 15-feature flow statistics extractor from ARM software into FPGA programmable logic.  
**Why:** Currently the Cortex-A9 parses raw packets and computes features in software (~50 µs). This is the largest remaining latency after the C driver fix and limits throughput to a few thousand flows per second.  
**Impact:** End-to-end latency drops from ~53 µs to sub-microsecond. Enables true line-rate classification at 1 Gbps. This is the most significant architectural extension.  
**Effort:** ~4–6 weeks. Requires re-synthesis. High-value hardware contribution.

### [HW] AXI-Stream input interface
**What:** Replace the AXI4-Lite register-by-register feature input with an AXI-Stream burst interface.  
**Why:** Current design requires 15 individual 32-bit writes over AXI4-Lite. AXI-Stream accepts all 15 features as a single 480-bit burst transaction.  
**Impact:** Feature input time drops 15×. Pairs with the wire-speed extractor above.  
**Effort:** ~1–2 weeks. Requires re-synthesis.

---

## P2 — Medium-Term Improvements

### [HW] Hardware normalization in Q16.16
**What:** Restore the AXI scaler that was removed in Fix 2, implemented in Q16.16 fixed-point instead of the broken Q8.8.  
**Why:** The original Q8.8 scaler zeroed out 11 of 15 features (1/std too small to represent). Q16.16 provides sufficient precision for all 15 features. This removes the Python pre-processing step entirely.  
**Impact:** Full hardware pipeline from raw features to classification result. No CPU preprocessing.  
**Effort:** ~1 week. Requires re-synthesis.

### [HW] Pipeline the Autoencoder
**What:** Add pipeline registers at the encoder bottleneck (enc2) to break the fully combinational AE path.  
**Why:** The AE forward pass (enc1→enc2→dec1→dec2→MSE) is a single unbroken combinational cone estimated at 15–22 ns, which violates timing at 100 MHz. A multicycle path constraint was added as a workaround (commit ce653f2), but this prevents the design from running at higher clock frequencies.  
**Impact:** Enables closing timing at 150–200 MHz, doubling classification throughput. The multicycle constraint can be removed.  
**Effort:** ~1 week. Requires re-synthesis.

### [HW] Parallel inference units
**What:** Replicate the DT+AE+fusion pipeline in multiple FPGA regions.  
**Why:** Current fabric usage is 15–22% LUTs and 14% DSPs. The remaining fabric supports 3–4 additional copies. Four parallel pipelines would classify 4 flows simultaneously.  
**Impact:** 4× throughput with no clock frequency change.  
**Effort:** ~2 weeks. Requires re-synthesis and AXI arbitration logic.

### [SYS] Model update at field (partial reconfiguration)
**What:** DT thresholds and AE weights are frozen in the bitstream. Partial reconfiguration allows updating only the weight region of the FPGA without taking the full inference engine offline.  
**Why:** When new attack variants emerge, the signal centre needs a new bitstream. A full bitstream reload takes ~1–2 seconds and interrupts classification. Partial reconfiguration takes ~100 ms and only reloads the model weights.  
**Impact:** Enables live model updates from the datacentre SOC without classification downtime.  
**Effort:** ~6–8 weeks. Requires Vivado PR flow.

---

## P3 — Research Contributions

### [ML] RECON zero-day detection
**What:** The current autoencoder cannot detect RECON attacks. Measured RECON MSE = 0.36× NORMAL mean — RECON traffic looks more normal than normal traffic to the AE.  
**Why:** RECON is low-volume, low-rate scanning traffic that closely resembles normal idle flows in the 15-feature space. The AE latent space geometry does not separate RECON from NORMAL.  
**Research direction:** Contrastive autoencoders, normalising flows, or energy-based models that learn tight NORMAL manifold boundaries. The FPGA implementation of a flow-based anomaly model is an open hardware ML research problem.  
**Significance:** RECON is the precursor phase of every multi-stage attack. Detecting it is the highest-value unsolved problem in the system.

### [ML+SYS] Federated learning at edge signal centres
**What:** Each signal centre sees a different traffic profile (geographic, ISP, operator, time-of-day). A central model trained on CIC-IDS-2017/2018 may not generalise to all deployment sites.  
**Research direction:** Federated learning protocol where each edge node contributes gradient updates from its local traffic to a central model in the datacentre SOC, without raw traffic leaving the signal centre. The updated bitstream is then pushed back via OTA.  
**Why it matters at the edge:** Privacy requirement — raw traffic at a signal centre may contain sensitive data that cannot leave the facility. Federated learning enables model improvement without data centralisation.

### [ML] Zero-day detection with flow-level evidence accumulation
**What:** Current zero-day gate fires on a single flow (purity < 0.75 AND AE anomaly). A single anomalous flow may be noise.  
**Research direction:** A sliding-window counter in hardware that requires K consecutive anomalous flows from the same source prefix before raising a zero-day alert. Implementable as a hash table + counter in BRAM (BRAM is only 1.5% used). No model retraining required.  
**Impact:** Reduces zero-day false positives at edge nodes where noisy links produce occasional anomalous measurements.

### [HW+ML] On-chip few-shot adaptation
**What:** DT thresholds are fixed. Traffic patterns at different signal centres vary.  
**Research direction:** A small online decision stump layer added above the DT output that can be retrained locally on the Cortex-A9 using a handful of labelled flows from the local environment, without modifying the main DT bitstream. The stump weights are stored in programmable registers, not re-synthesised.

### [SEC] Encrypted bitstream and hardware attestation
**What:** The FPGA bitstream encodes the full decision tree — all 767 thresholds. An adversary with physical access to a signal centre device could read the bitstream and craft flows that evade classification.  
**Research direction:** Zynq supports AES-256 encrypted bitstream loading from BBRAM/eFUSE. Key management architecture for field-deployed IDS nodes where physical security cannot be guaranteed. Includes remote attestation protocol to verify the correct bitstream is loaded before the SOC trusts the node's classifications.

### [SYS] Traffic replay and forensic buffer
**What:** When a zero-day alert fires, the raw flow that triggered it is discarded. The SOC receives only the classification result, not the evidence.  
**Research direction:** On-chip BRAM ring buffer storing the last N flow feature vectors preceding a zero-day alert, forwarded to the SOC as forensic payload. The Pynq-Z2 BRAM is 630 KB, currently only 9 KB used — enough for ~800 flow records at 15 × 4 bytes each.  
**Significance:** Enables post-incident analysis and model retraining from real adversarial examples observed at the edge.

### [SYS] Power and thermal management for field conditions
**What:** Signal centres in the field may have unreliable power (voltage sags, brownouts) and no active cooling (ambient temperature variation).  
**Research direction:** Dynamic clock gating of the FPGA PL when no traffic is present (idle power ~100 mW vs active ~500 mW). Thermal monitoring using the Zynq's on-chip temperature sensor to throttle PL clock frequency under high ambient temperature. The Pynq-Z2's INA219 power sensors provide the measurement baseline.

### [HW] Multi-protocol feature extraction
**What:** The current 15 features are derived from TCP/IP flow statistics (CIC-IDS standard). Signal centres handling 5G backhaul, industrial SCADA, or enterprise VPN traffic require different feature sets.  
**Research direction:** Parameterised feature extraction hardware where the protocol parser is a reconfigurable module (configured via AXI registers without bitstream reload), while the DT and AE classification core remains fixed. The DT and AE are retrained on the new feature set, a new model bitstream is synthesised, and only the classification region is partially reconfigured.

---

## Summary Table

| Item | Type | Priority | Re-synthesis? | Estimated effort |
|---|---|---|---|---|
| C AXI driver | SYS | P1 | No | 1 week |
| Wire-speed feature extractor | HW | P1 | Yes | 4–6 weeks |
| AXI-Stream input | HW | P1 | Yes | 1–2 weeks |
| Hardware scaler Q16.16 | HW | P2 | Yes | 1 week |
| Pipeline AE | HW | P2 | Yes | 1 week |
| Parallel inference units | HW | P2 | Yes | 2 weeks |
| Partial reconfiguration OTA | SYS | P2 | Yes | 6–8 weeks |
| RECON zero-day detection | ML | P3 | Yes | Research |
| Federated learning | ML+SYS | P3 | No (model only) | Research |
| Flow-level evidence accumulation | HW+ML | P3 | No | 2 weeks |
| Encrypted bitstream + attestation | SEC | P3 | No | Research |
| Forensic BRAM buffer | HW | P3 | Yes | 1 week |
| Power/thermal management | SYS | P3 | No | 2 weeks |
| Multi-protocol feature extraction | HW | P3 | Yes | Research |
