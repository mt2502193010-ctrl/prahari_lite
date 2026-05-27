`timescale 1ns/1ps
// PRAHARI-Lite — Top Level
// Connects: dt_inference + ae_inference + fusion_logic
module prahari_lite_top (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire signed [15:0] feat0,  feat1,  feat2,  feat3,  feat4,
    input  wire signed [15:0] feat5,  feat6,  feat7,  feat8,  feat9,
    input  wire signed [15:0] feat10, feat11, feat12, feat13, feat14,
    output wire [2:0]  final_class,
    output wire        zero_day,
    output wire        valid,
    output wire [31:0] ae_error
);

wire [2:0] dt_class;
wire [7:0] dt_purity;
wire       dt_done;
wire       ae_anomaly;

dt_inference u_dt (
    .clk     (clk),      .rst    (rst),      .start  (start),
    .feat0   (feat0),    .feat1  (feat1),    .feat2  (feat2),
    .feat3   (feat3),    .feat4  (feat4),    .feat5  (feat5),
    .feat6   (feat6),    .feat7  (feat7),    .feat8  (feat8),
    .feat9   (feat9),    .feat10 (feat10),   .feat11 (feat11),
    .feat12  (feat12),   .feat13 (feat13),   .feat14 (feat14),
    .class_out  (dt_class),
    .purity_out (dt_purity),
    .done       (dt_done)
);

ae_inference u_ae (
    .feat0  (feat0),  .feat1  (feat1),  .feat2  (feat2),
    .feat3  (feat3),  .feat4  (feat4),  .feat5  (feat5),
    .feat6  (feat6),  .feat7  (feat7),  .feat8  (feat8),
    .feat9  (feat9),  .feat10 (feat10), .feat11 (feat11),
    .feat12 (feat12), .feat13 (feat13), .feat14 (feat14),
    .anomaly  (ae_anomaly),
    .ae_error (ae_error)
);

fusion_logic u_fusion (
    .dt_class   (dt_class),
    .dt_purity  (dt_purity),
    .ae_anomaly (ae_anomaly),
    .dt_done    (dt_done),
    .final_class(final_class),
    .zero_day   (zero_day),
    .valid      (valid)
);

endmodule
