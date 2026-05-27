`timescale 1ns/1ps
// PRAHARI-Lite — Fusion Logic (fully combinational)
// Confidence gate: if purity < 0.75 AND ae_anomaly → ZERO_DAY (class=5)
module fusion_logic (
    input  wire [2:0] dt_class,
    input  wire [7:0] dt_purity,    // Q0.8: 192 = 0.75
    input  wire       ae_anomaly,
    input  wire       dt_done,
    output reg  [2:0] final_class,
    output wire       zero_day,
    output wire       valid
);
// Purity threshold: 0.75 × 256 = 192
localparam [7:0] PURITY_THRESH = 8'd192;

assign valid    = dt_done;
assign zero_day = (dt_purity < PURITY_THRESH) && ae_anomaly;

always @(*) begin
    if (zero_day)
        final_class = 3'd5;   // ZERO_DAY
    else
        final_class = dt_class;
end

endmodule
