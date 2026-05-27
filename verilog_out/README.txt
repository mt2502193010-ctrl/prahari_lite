PRAHARI-Lite — Pynq-Z2 FPGA IDS
Synthesis Package
Generated: 2026-05-27
============================================================

VIVADO COMPATIBILITY:  2022.2 and 2023.2

EXPECTED SYNTHESIS TIME:  ~45 minutes (synthesis ~15 min, implementation ~30 min)

FILES IN THIS PACKAGE:
  dt_inference.v          Decision Tree (1533 nodes, depth=15, 5 classes)
  ae_inference.v          Autoencoder anomaly detector (15→8→4→8→15, combinational)
  fusion_logic.v          DT+AE confidence gate (combinational)
  prahari_lite_top.v      Top-level structural module
  prahari_lite_axi.v      AXI4-Lite slave wrapper (0x43C00000, 64K range)
  pynq_z2_constraints.xdc Timing constraints (100 MHz AXI clock)
  create_vivado_project.tcl   Vivado automation script
  test_pynq.py            Board-side Python test (run ON the Pynq-Z2)

STEP-BY-STEP LAB INSTRUCTIONS:
  1. Copy this entire folder to the lab PC (USB drive or network).
  2. Open Vivado, open the Tcl Console, and run:
       cd {/path/to/this/folder}
       source create_vivado_project.tcl
     (Synthesis + implementation run automatically — ~45 min total.)
  3. Outputs land in output_files/prahari_lite.bit and prahari_lite.hwh.
  4. Copy prahari_lite.bit and prahari_lite.hwh to /home/xilinx/prahari_lite/ on the board,
     then run: python3 test_pynq.py

BOARD CONNECTION:
  Connect Pynq-Z2 via USB-UART (115200 baud) and/or Ethernet to the lab PC.
  Power switch to "REG", boot mode jumper to SD card.
  Default board IP: 192.168.2.99 (or check UART for DHCP address).

AXI REGISTER MAP (base 0x43C00000):
  0x00  Control:  write bit[0]=1 to start (auto-clears)
  0x04  Status:   bit[0]=done, bit[1]=zero_day
  0x08..0x44  Features 0..14 (raw Q8.8 values; scaler in hardware)
  0x48  Result:   bits[2:0] = class (0=NORMAL 1=APT 2=RECON 3=TRAFFIC_SPIKE 4=NR_MALWARE 5=ZERO_DAY)
  0x4C  AE Error: 32-bit reconstruction MSE

TARGET RESOURCES (estimated, xc7z020clg400-1):
  BRAM:  ~12 blocks  (of 280 available)
  LUTs:  ~18,000     (of 53,200 available)
  DSPs:  ~30         (of 220 available)
  Timing: 100 MHz    (10.0 ns period)
