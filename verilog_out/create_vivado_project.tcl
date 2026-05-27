# ============================================================
# PRAHARI-Lite — Vivado Automation Script
# Compatible: Vivado 2022.2 and 2023.2
# Target:     xc7z020clg400-1 (Pynq-Z2)
# Usage:      vivado -mode batch -source create_vivado_project.tcl
# ============================================================

set script_dir [file dirname [info script]]
set proj_name  "prahari_lite"
set proj_dir   [file join $script_dir "vivado_proj"]
set src_dir    $script_dir
set out_dir    [file join $script_dir "output_files"]

file mkdir $out_dir

puts "============================================================"
puts "PRAHARI-Lite Vivado Project Builder"
puts "Script dir: $script_dir"
puts "Project:    $proj_dir/$proj_name"
puts "============================================================"

# ── Create project ────────────────────────────────────────────
set board_part "tul.com.tw:pynq-z2:part0:1.0"
set device_part "xc7z020clg400-1"

if {[catch {create_project $proj_name $proj_dir -part $device_part -force} err]} {
    puts "ERROR creating project: $err"; exit 1
}

# Try to set board part (skip gracefully if not installed)
if {[catch {set_property BOARD_PART $board_part [current_project]}]} {
    puts "WARNING: Pynq-Z2 board part not found — using device part only ($device_part)"
    puts "         Install board files from: https://github.com/Xilinx/XilinxBoardStore"
}

set_property target_language Verilog [current_project]
set_property default_lib work        [current_project]

puts "Project created."

# ── Add Verilog sources ───────────────────────────────────────
set v_files [list \
    [file join $src_dir "dt_inference.v"] \
    [file join $src_dir "ae_inference.v"] \
    [file join $src_dir "fusion_logic.v"] \
    [file join $src_dir "prahari_lite_top.v"] \
    [file join $src_dir "prahari_lite_axi.v"] \
]

foreach f $v_files {
    if {![file exists $f]} {
        puts "ERROR: Source file not found: $f"; exit 1
    }
}

add_files -norecurse $v_files
puts "Added [llength $v_files] Verilog source files."

# Add constraints
set xdc_file [file join $src_dir "pynq_z2_constraints.xdc"]
if {[file exists $xdc_file]} {
    add_files -fileset constrs_1 -norecurse $xdc_file
    puts "Added constraints: $xdc_file"
}

# ── Create block design ───────────────────────────────────────
create_bd_design "prahari_system"
puts "Block design created: prahari_system"

# Add Zynq PS7
set zynq [create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0]
if {[catch {apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
        -config {make_external "FIXED_IO, DDR" apply_board_preset "1"} $zynq}]} {
    puts "WARNING: Board automation failed (board part missing?) — configuring PS7 manually"
    set_property -dict [list \
        CONFIG.PCW_USE_M_AXI_GP0 {1} \
        CONFIG.PCW_M_AXI_GP0_ENABLE_STATIC_REMAP {1} \
        CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
        CONFIG.PCW_EN_CLK0_PORT {1} \
        CONFIG.PCW_EN_RST0_PORT {1} \
    ] $zynq
}

# Enable M_AXI_GP0
set_property CONFIG.PCW_USE_M_AXI_GP0 {1} $zynq
puts "PS7 configured."

# Add AXI Interconnect
set axi_ic [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0]
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1}] $axi_ic

# Add PRAHARI-Lite AXI module reference
set prahari [create_bd_cell -type module -reference prahari_lite_axi prahari_lite_0]
puts "Module reference prahari_lite_0 added."

# ── Connect clocks ────────────────────────────────────────────
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
    [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] \
    [get_bd_pins axi_interconnect_0/ACLK] \
    [get_bd_pins axi_interconnect_0/S00_ACLK] \
    [get_bd_pins axi_interconnect_0/M00_ACLK] \
    [get_bd_pins prahari_lite_0/s_axi_aclk]
puts "Clocks connected."

# ── Connect resets ────────────────────────────────────────────
connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] \
    [get_bd_pins axi_interconnect_0/ARESETN] \
    [get_bd_pins axi_interconnect_0/S00_ARESETN] \
    [get_bd_pins axi_interconnect_0/M00_ARESETN] \
    [get_bd_pins prahari_lite_0/s_axi_aresetn]
puts "Resets connected."

# ── Connect AXI data paths ────────────────────────────────────
connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP0] \
    [get_bd_intf_pins axi_interconnect_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M00_AXI] \
    [get_bd_intf_pins prahari_lite_0/S_AXI]
puts "AXI paths connected."

# ── Assign address ────────────────────────────────────────────
assign_bd_address [get_bd_addr_segs {prahari_lite_0/S_AXI/reg0}]
set_property offset 0x43C00000 [get_bd_addr_segs \
    {processing_system7_0/Data/SEG_prahari_lite_0_reg0}]
set_property range  64K         [get_bd_addr_segs \
    {processing_system7_0/Data/SEG_prahari_lite_0_reg0}]
puts "Address assigned: 0x43C00000, range 64K"

# ── Validate and wrap ─────────────────────────────────────────
if {[catch {validate_bd_design} err]} {
    puts "WARNING: BD validation: $err"
} else {
    puts "Block design validated."
}

set wrapper [make_wrapper -files [get_files prahari_system.bd] -top]
add_files -norecurse $wrapper
set_property top prahari_system_wrapper [current_fileset]
update_compile_order -fileset sources_1
puts "HDL wrapper created and set as top."

# ── Synthesis ─────────────────────────────────────────────────
puts "Starting synthesis (~15 min)..."
if {[catch {launch_runs synth_1 -jobs 4} err]} {
    puts "ERROR launching synthesis: $err"; exit 1
}
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis failed."; exit 1
}
puts "Synthesis complete."

# ── Implementation + Bitstream ────────────────────────────────
puts "Starting implementation + bitstream (~30 min)..."
if {[catch {launch_runs impl_1 -to_step write_bitstream -jobs 4} err]} {
    puts "ERROR launching implementation: $err"; exit 1
}
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Implementation failed."; exit 1
}
puts "Implementation and bitstream complete."

# ── Copy outputs ──────────────────────────────────────────────
set bit_file [glob -nocomplain "$proj_dir/${proj_name}.runs/impl_1/*.bit"]
set hwh_file [glob -nocomplain "$proj_dir/${proj_name}.gen/sources_1/bd/prahari_system/hw_handoff/*.hwh"]

if {[llength $bit_file] > 0} {
    file copy -force [lindex $bit_file 0] [file join $out_dir "prahari_lite.bit"]
    puts "Bitstream copied to: $out_dir/prahari_lite.bit"
} else { puts "WARNING: .bit file not found" }

if {[llength $hwh_file] > 0} {
    file copy -force [lindex $hwh_file 0] [file join $out_dir "prahari_lite.hwh"]
    puts "HWH copied to:       $out_dir/prahari_lite.hwh"
} else { puts "WARNING: .hwh file not found" }

puts "============================================================"
puts "PRAHARI-Lite build COMPLETE"
puts "Outputs in: $out_dir"
puts "============================================================"
