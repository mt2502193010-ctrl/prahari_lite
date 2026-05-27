# PRAHARI-Lite — Pynq-Z2 Timing Constraints
# AXI clock comes from Zynq PS7 FCLK_CLK0 (100 MHz)
create_clock -period 10.000 -name s_axi_aclk [get_ports s_axi_aclk]

# False paths for AXI reset (async assert, sync de-assert)
set_false_path -from [get_ports s_axi_aresetn]

# False paths: input features are written via AXI before start is asserted
set_false_path -through [get_nets -hierarchical -filter {NAME =~ *feat_reg*}]
