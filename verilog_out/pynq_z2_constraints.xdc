# PRAHARI-Lite — Pynq-Z2 Timing Constraints
# AXI clock comes from Zynq PS7 FCLK_CLK0 (100 MHz)
# NOTE (7A): In a Vivado block design, s_axi_aclk is driven by PS7 FCLK_CLK0,
# not a physical board pin. This constraint is used during out-of-context synthesis
# and may generate a WARNING in the block design flow — it is safe to ignore.
# If using purely the block design flow, Vivado auto-generates PS clock constraints.
create_clock -period 10.000 -name s_axi_aclk [get_ports s_axi_aclk]

# False path for AXI reset (async assert, sync de-assert)
set_false_path -from [get_ports s_axi_aresetn]

# Multicycle path — AE forward pass is fully combinational but naturally multicycle.
# ae_error is only captured when dt_done fires, which is:
#   1 (IDLE) + 2*depth (BRAM_WAIT+COMPARE) + 1 (DONE) = 1 + 2*15 + 1 = 32 cycles
# after start is asserted (Fix 1 adds BRAM_WAIT state, doubling DT cycle count).
# Grant 32 cycles setup and 31 cycles hold for the feat_reg → reg_ae_err path.
set_multicycle_path 32 -setup \
    -from [get_cells -hier -filter {NAME =~ *feat_reg*}] \
    -to   [get_cells -hier -filter {NAME =~ *reg_ae_err*}]
set_multicycle_path 31 -hold  \
    -from [get_cells -hier -filter {NAME =~ *feat_reg*}] \
    -to   [get_cells -hier -filter {NAME =~ *reg_ae_err*}]

# DRC waivers — PS7-driven AXI clock, no external IO constraints needed
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
