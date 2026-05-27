`timescale 1ns/1ps
// PRAHARI-Lite — Autoencoder Anomaly Detector (fully combinational)
// Architecture: 15→8→4→8→15, all weights Q4.4 (scale=16)
// AE threshold (Q8.8²): 157811
module ae_inference (
    input  wire signed [15:0] feat0,  feat1,  feat2,  feat3,  feat4,
    input  wire signed [15:0] feat5,  feat6,  feat7,  feat8,  feat9,
    input  wire signed [15:0] feat10, feat11, feat12, feat13, feat14,
    output wire               anomaly,
    output wire [31:0]        ae_error
);

localparam signed [31:0] AE_THRESH = 32'sd157811;

// ── ENCODER LAYER 1 (15→8, ReLU) ──────────────────────────────────────────
    wire signed [31:0] enc1_acc_0 = ((-$signed(feat0)) + (5 * $signed(feat1)) + (5 * $signed(feat3)) + (-2 * $signed(feat4)) + (3 * $signed(feat5)) + (-3 * $signed(feat7)) + (-3 * $signed(feat8)) + (-6 * $signed(feat9)) + (2 * $signed(feat10)) + (6 * $signed(feat11)) + (-7 * $signed(feat12)) + (-2 * $signed(feat13)) + (-$signed(feat14)) + 32'sd5) >>> 4;
    wire signed [31:0] enc1_0 = ($signed(enc1_acc_0)[31]) ? 32'sd0 : enc1_acc_0;
    wire signed [31:0] enc1_acc_1 = ((-5 * $signed(feat0)) + (4 * $signed(feat1)) + (-$signed(feat2)) + (4 * $signed(feat3)) + (-3 * $signed(feat4)) + (2 * $signed(feat5)) + (-$signed(feat6)) + (-6 * $signed(feat7)) + (-6 * $signed(feat8)) + (-$signed(feat9)) + (7 * $signed(feat11)) + $signed(feat12) + (2 * $signed(feat13)) + (6 * $signed(feat14)) - 32'sd1) >>> 4;
    wire signed [31:0] enc1_1 = ($signed(enc1_acc_1)[31]) ? 32'sd0 : enc1_acc_1;
    wire signed [31:0] enc1_acc_2 = ((-4 * $signed(feat0)) + $signed(feat1) + (-$signed(feat2)) + (3 * $signed(feat3)) + (2 * $signed(feat4)) + (2 * $signed(feat6)) + (-4 * $signed(feat7)) + (-4 * $signed(feat8)) + $signed(feat9) + (2 * $signed(feat10)) + (7 * $signed(feat11)) + (-4 * $signed(feat12)) + (3 * $signed(feat13)) + $signed(feat14) + 32'sd1) >>> 4;
    wire signed [31:0] enc1_2 = ($signed(enc1_acc_2)[31]) ? 32'sd0 : enc1_acc_2;
    wire signed [31:0] enc1_acc_3 = ((-6 * $signed(feat0)) + (7 * $signed(feat1)) + (6 * $signed(feat2)) + (5 * $signed(feat3)) + (-2 * $signed(feat4)) + (4 * $signed(feat5)) + (8 * $signed(feat6)) + (-11 * $signed(feat7)) + (-8 * $signed(feat8)) + (-3 * $signed(feat9)) + (8 * $signed(feat10)) + (-2 * $signed(feat11)) + (-8 * $signed(feat12)) + (11 * $signed(feat13)) + (9 * $signed(feat14)) + 32'sd7) >>> 4;
    wire signed [31:0] enc1_3 = ($signed(enc1_acc_3)[31]) ? 32'sd0 : enc1_acc_3;
    wire signed [31:0] enc1_acc_4 = ((-$signed(feat0)) + (6 * $signed(feat1)) + (3 * $signed(feat2)) + (-$signed(feat3)) + (-5 * $signed(feat4)) + (-$signed(feat5)) + (4 * $signed(feat6)) + (-2 * $signed(feat8)) + (-7 * $signed(feat9)) + (-$signed(feat10)) + (9 * $signed(feat11)) + (-4 * $signed(feat12)) + (2 * $signed(feat13)) + (3 * $signed(feat14)) + 32'sd1) >>> 4;
    wire signed [31:0] enc1_4 = ($signed(enc1_acc_4)[31]) ? 32'sd0 : enc1_acc_4;
    wire signed [31:0] enc1_acc_5 = ((-4 * $signed(feat0)) + (-$signed(feat1)) + (6 * $signed(feat2)) + (-$signed(feat4)) + (2 * $signed(feat5)) + $signed(feat6) + (-6 * $signed(feat7)) + (-2 * $signed(feat8)) + (-2 * $signed(feat9)) + (4 * $signed(feat10)) + (6 * $signed(feat11)) + (-4 * $signed(feat12)) + (2 * $signed(feat13)) + (-2 * $signed(feat14)) + 32'sd0) >>> 4;
    wire signed [31:0] enc1_5 = ($signed(enc1_acc_5)[31]) ? 32'sd0 : enc1_acc_5;
    wire signed [31:0] enc1_acc_6 = ((-5 * $signed(feat0)) + $signed(feat2) + $signed(feat3) + (-$signed(feat4)) + (-$signed(feat5)) + (4 * $signed(feat6)) + (-$signed(feat7)) + (-5 * $signed(feat8)) + (-5 * $signed(feat9)) + $signed(feat10) + (8 * $signed(feat11)) + (-$signed(feat12)) + (5 * $signed(feat13)) + (5 * $signed(feat14)) + 32'sd2) >>> 4;
    wire signed [31:0] enc1_6 = ($signed(enc1_acc_6)[31]) ? 32'sd0 : enc1_acc_6;
    wire signed [31:0] enc1_acc_7 = ((2 * $signed(feat1)) + (5 * $signed(feat2)) + (-$signed(feat3)) + (-$signed(feat5)) + (3 * $signed(feat6)) + (2 * $signed(feat7)) + (-2 * $signed(feat8)) + (-2 * $signed(feat9)) + (5 * $signed(feat10)) + (5 * $signed(feat11)) + (4 * $signed(feat13)) + (3 * $signed(feat14)) + 32'sd4) >>> 4;
    wire signed [31:0] enc1_7 = ($signed(enc1_acc_7)[31]) ? 32'sd0 : enc1_acc_7;

// ── ENCODER LAYER 2 (8→4, ReLU / bottleneck) ─────────────────────────────
    wire signed [31:0] enc2_acc_0 = ((9 * $signed(enc1_0)) + (8 * $signed(enc1_1)) + (2 * $signed(enc1_2)) + (-16 * $signed(enc1_3)) + (4 * $signed(enc1_4)) + (7 * $signed(enc1_5)) + (5 * $signed(enc1_6)) + (6 * $signed(enc1_7)) - 32'sd3) >>> 4;
    wire signed [31:0] enc2_0 = ($signed(enc2_acc_0)[31]) ? 32'sd0 : enc2_acc_0;
    wire signed [31:0] enc2_acc_1 = ((-5 * $signed(enc1_0)) + (-3 * $signed(enc1_1)) + (-3 * $signed(enc1_2)) + (-7 * $signed(enc1_3)) + (-$signed(enc1_4)) + (3 * $signed(enc1_5)) + $signed(enc1_6) + (4 * $signed(enc1_7)) - 32'sd5) >>> 4;
    wire signed [31:0] enc2_1 = ($signed(enc2_acc_1)[31]) ? 32'sd0 : enc2_acc_1;
    wire signed [31:0] enc2_acc_2 = ((6 * $signed(enc1_0)) + (6 * $signed(enc1_1)) + (6 * $signed(enc1_2)) + (-12 * $signed(enc1_3)) + (6 * $signed(enc1_4)) + (7 * $signed(enc1_5)) + (9 * $signed(enc1_6)) + (9 * $signed(enc1_7)) + 32'sd1) >>> 4;
    wire signed [31:0] enc2_2 = ($signed(enc2_acc_2)[31]) ? 32'sd0 : enc2_acc_2;
    wire signed [31:0] enc2_acc_3 = ((4 * $signed(enc1_1)) + (7 * $signed(enc1_2)) + (13 * $signed(enc1_3)) + $signed(enc1_4) + (-2 * $signed(enc1_5)) + (5 * $signed(enc1_6)) + (7 * $signed(enc1_7)) - 32'sd1) >>> 4;
    wire signed [31:0] enc2_3 = ($signed(enc2_acc_3)[31]) ? 32'sd0 : enc2_acc_3;

// ── DECODER LAYER 1 (4→8, ReLU) ──────────────────────────────────────────
    wire signed [31:0] dec1_acc_0 = ((-$signed(enc2_0)) + $signed(enc2_1) + (-4 * $signed(enc2_2)) + (-4 * $signed(enc2_3)) + 32'sd1) >>> 4;
    wire signed [31:0] dec1_0 = ($signed(dec1_acc_0)[31]) ? 32'sd0 : dec1_acc_0;
    wire signed [31:0] dec1_acc_1 = ((-3 * $signed(enc2_0)) + (2 * $signed(enc2_1)) + (2 * $signed(enc2_2)) + (9 * $signed(enc2_3)) + 32'sd4) >>> 4;
    wire signed [31:0] dec1_1 = ($signed(dec1_acc_1)[31]) ? 32'sd0 : dec1_acc_1;
    wire signed [31:0] dec1_acc_2 = ((7 * $signed(enc2_0)) + (3 * $signed(enc2_1)) + (-3 * $signed(enc2_2)) + (-8 * $signed(enc2_3)) - 32'sd1) >>> 4;
    wire signed [31:0] dec1_2 = ($signed(dec1_acc_2)[31]) ? 32'sd0 : dec1_acc_2;
    wire signed [31:0] dec1_acc_3 = ((-5 * $signed(enc2_0)) + (-5 * $signed(enc2_1)) + (-2 * $signed(enc2_2)) + (-3 * $signed(enc2_3)) - 32'sd4) >>> 4;
    wire signed [31:0] dec1_3 = ($signed(dec1_acc_3)[31]) ? 32'sd0 : dec1_acc_3;
    wire signed [31:0] dec1_acc_4 = ($signed(enc2_0) + (-2 * $signed(enc2_1)) + (-7 * $signed(enc2_2)) + (-7 * $signed(enc2_3)) + 32'sd5) >>> 4;
    wire signed [31:0] dec1_4 = ($signed(dec1_acc_4)[31]) ? 32'sd0 : dec1_acc_4;
    wire signed [31:0] dec1_acc_5 = ((6 * $signed(enc2_0)) + (-5 * $signed(enc2_1)) + (-5 * $signed(enc2_2)) + (-3 * $signed(enc2_3)) - 32'sd4) >>> 4;
    wire signed [31:0] dec1_5 = ($signed(dec1_acc_5)[31]) ? 32'sd0 : dec1_acc_5;
    wire signed [31:0] dec1_acc_6 = ((10 * $signed(enc2_0)) + (7 * $signed(enc2_1)) + (5 * $signed(enc2_2)) + (-2 * $signed(enc2_3)) + 32'sd6) >>> 4;
    wire signed [31:0] dec1_6 = ($signed(dec1_acc_6)[31]) ? 32'sd0 : dec1_acc_6;
    wire signed [31:0] dec1_acc_7 = ((7 * $signed(enc2_0)) + (-5 * $signed(enc2_1)) + (7 * $signed(enc2_2)) + (7 * $signed(enc2_3)) - 32'sd1) >>> 4;
    wire signed [31:0] dec1_7 = ($signed(dec1_acc_7)[31]) ? 32'sd0 : dec1_acc_7;

// ── DECODER LAYER 2 (8→15, clamp ±256 Q8.8) ─────────────────────────────
    wire signed [31:0] dec2_acc_0 = ($signed(dec1_0) + $signed(dec1_1) + (-$signed(dec1_2)) + (-$signed(dec1_3)) + (2 * $signed(dec1_4)) + (3 * $signed(dec1_5)) + (2 * $signed(dec1_6)) + (-2 * $signed(dec1_7)) + 32'sd2) >>> 4;
    wire signed [31:0] recon_0 = (dec2_acc_0 > 32'sd65536) ? 32'sd65536 : ((dec2_acc_0 < -32'sd65536) ? -32'sd65536 : dec2_acc_0);
    wire signed [31:0] dec2_acc_1 = ((-$signed(dec1_1)) + $signed(dec1_2) + (3 * $signed(dec1_3)) + (3 * $signed(dec1_4)) + (-3 * $signed(dec1_5)) + (-$signed(dec1_6)) + $signed(dec1_7) + 32'sd2) >>> 4;
    wire signed [31:0] recon_1 = (dec2_acc_1 > 32'sd65536) ? 32'sd65536 : ((dec2_acc_1 < -32'sd65536) ? -32'sd65536 : dec2_acc_1);
    wire signed [31:0] dec2_acc_2 = ((-5 * $signed(dec1_0)) + (2 * $signed(dec1_1)) + (-5 * $signed(dec1_2)) + $signed(dec1_3) + (-4 * $signed(dec1_4)) + (-2 * $signed(dec1_6)) + (2 * $signed(dec1_7)) + 32'sd4) >>> 4;
    wire signed [31:0] recon_2 = (dec2_acc_2 > 32'sd65536) ? 32'sd65536 : ((dec2_acc_2 < -32'sd65536) ? -32'sd65536 : dec2_acc_2);
    wire signed [31:0] dec2_acc_3 = ((-4 * $signed(dec1_0)) + (3 * $signed(dec1_1)) + (5 * $signed(dec1_2)) + (-5 * $signed(dec1_3)) + (-2 * $signed(dec1_4)) + (-2 * $signed(dec1_5)) + 32'sd8) >>> 4;
    wire signed [31:0] recon_3 = (dec2_acc_3 > 32'sd65536) ? 32'sd65536 : ((dec2_acc_3 < -32'sd65536) ? -32'sd65536 : dec2_acc_3);
    wire signed [31:0] dec2_acc_4 = ((-2 * $signed(dec1_0)) + $signed(dec1_1) + (2 * $signed(dec1_2)) + (-5 * $signed(dec1_3)) + (2 * $signed(dec1_4)) + (-3 * $signed(dec1_5)) + $signed(dec1_6) + (-$signed(dec1_7)) - 32'sd3) >>> 4;
    wire signed [31:0] recon_4 = (dec2_acc_4 > 32'sd65536) ? 32'sd65536 : ((dec2_acc_4 < -32'sd65536) ? -32'sd65536 : dec2_acc_4);
    wire signed [31:0] dec2_acc_5 = ((-5 * $signed(dec1_0)) + $signed(dec1_1) + $signed(dec1_2) + (-$signed(dec1_3)) + (-3 * $signed(dec1_4)) + (-3 * $signed(dec1_5)) + (2 * $signed(dec1_6)) + (-2 * $signed(dec1_7)) + 32'sd6) >>> 4;
    wire signed [31:0] recon_5 = (dec2_acc_5 > 32'sd65536) ? 32'sd65536 : ((dec2_acc_5 < -32'sd65536) ? -32'sd65536 : dec2_acc_5);
    wire signed [31:0] dec2_acc_6 = ((3 * $signed(dec1_0)) + (6 * $signed(dec1_1)) + (4 * $signed(dec1_2)) + (-5 * $signed(dec1_3)) + (3 * $signed(dec1_4)) + (5 * $signed(dec1_5)) + (-2 * $signed(dec1_6)) + $signed(dec1_7) + 32'sd12) >>> 4;
    wire signed [31:0] recon_6 = (dec2_acc_6 > 32'sd65536) ? 32'sd65536 : ((dec2_acc_6 < -32'sd65536) ? -32'sd65536 : dec2_acc_6);
    wire signed [31:0] dec2_acc_7 = ((5 * $signed(dec1_0)) + (2 * $signed(dec1_1)) + (-4 * $signed(dec1_2)) + (-$signed(dec1_3)) + (-4 * $signed(dec1_4)) + (-2 * $signed(dec1_5)) + (2 * $signed(dec1_6)) + (-2 * $signed(dec1_7)) - 32'sd1) >>> 4;
    wire signed [31:0] recon_7 = (dec2_acc_7 > 32'sd65536) ? 32'sd65536 : ((dec2_acc_7 < -32'sd65536) ? -32'sd65536 : dec2_acc_7);
    wire signed [31:0] dec2_acc_8 = ((-2 * $signed(dec1_0)) + $signed(dec1_1) + (6 * $signed(dec1_2)) + (4 * $signed(dec1_3)) + (-5 * $signed(dec1_4)) + (-4 * $signed(dec1_5)) + $signed(dec1_6) + (-$signed(dec1_7)) - 32'sd3) >>> 4;
    wire signed [31:0] recon_8 = (dec2_acc_8 > 32'sd65536) ? 32'sd65536 : ((dec2_acc_8 < -32'sd65536) ? -32'sd65536 : dec2_acc_8);
    wire signed [31:0] dec2_acc_9 = ((-4 * $signed(dec1_0)) + $signed(dec1_1) + (3 * $signed(dec1_2)) + (-4 * $signed(dec1_3)) + (4 * $signed(dec1_4)) + (3 * $signed(dec1_5)) + $signed(dec1_6) + (-$signed(dec1_7)) - 32'sd2) >>> 4;
    wire signed [31:0] recon_9 = (dec2_acc_9 > 32'sd65536) ? 32'sd65536 : ((dec2_acc_9 < -32'sd65536) ? -32'sd65536 : dec2_acc_9);
    wire signed [31:0] dec2_acc_10 = ($signed(dec1_0) + $signed(dec1_2) + $signed(dec1_3) + (-2 * $signed(dec1_4)) + (2 * $signed(dec1_5)) + (-5 * $signed(dec1_6)) + (4 * $signed(dec1_7)) + 32'sd5) >>> 4;
    wire signed [31:0] recon_10 = (dec2_acc_10 > 32'sd65536) ? 32'sd65536 : ((dec2_acc_10 < -32'sd65536) ? -32'sd65536 : dec2_acc_10);
    wire signed [31:0] dec2_acc_11 = ((-5 * $signed(dec1_0)) + (-4 * $signed(dec1_2)) + (5 * $signed(dec1_3)) + $signed(dec1_4) + (6 * $signed(dec1_6)) + (7 * $signed(dec1_7)) - 32'sd2) >>> 4;
    wire signed [31:0] recon_11 = (dec2_acc_11 > 32'sd65536) ? 32'sd65536 : ((dec2_acc_11 < -32'sd65536) ? -32'sd65536 : dec2_acc_11);
    wire signed [31:0] dec2_acc_12 = ((-3 * $signed(dec1_0)) + $signed(dec1_1) + (-3 * $signed(dec1_2)) + (-3 * $signed(dec1_3)) + (2 * $signed(dec1_5)) - 32'sd2) >>> 4;
    wire signed [31:0] recon_12 = (dec2_acc_12 > 32'sd65536) ? 32'sd65536 : ((dec2_acc_12 < -32'sd65536) ? -32'sd65536 : dec2_acc_12);
    wire signed [31:0] dec2_acc_13 = ((6 * $signed(dec1_0)) + (6 * $signed(dec1_1)) + (-2 * $signed(dec1_2)) + (-2 * $signed(dec1_3)) + (-2 * $signed(dec1_4)) + (-$signed(dec1_5)) + (-4 * $signed(dec1_6)) + (2 * $signed(dec1_7)) - 32'sd2) >>> 4;
    wire signed [31:0] recon_13 = (dec2_acc_13 > 32'sd65536) ? 32'sd65536 : ((dec2_acc_13 < -32'sd65536) ? -32'sd65536 : dec2_acc_13);
    wire signed [31:0] dec2_acc_14 = ($signed(dec1_0) + (2 * $signed(dec1_1)) + (-5 * $signed(dec1_2)) + (-3 * $signed(dec1_3)) + (6 * $signed(dec1_5)) + (-6 * $signed(dec1_6)) + (5 * $signed(dec1_7)) + 32'sd3) >>> 4;
    wire signed [31:0] recon_14 = (dec2_acc_14 > 32'sd65536) ? 32'sd65536 : ((dec2_acc_14 < -32'sd65536) ? -32'sd65536 : dec2_acc_14);

// ── MSE Reconstruction Error ──────────────────────────────────────────────
    wire signed [31:0] diff_0 = $signed(feat0) - $signed(recon_0);
    wire signed [31:0] diff_1 = $signed(feat1) - $signed(recon_1);
    wire signed [31:0] diff_2 = $signed(feat2) - $signed(recon_2);
    wire signed [31:0] diff_3 = $signed(feat3) - $signed(recon_3);
    wire signed [31:0] diff_4 = $signed(feat4) - $signed(recon_4);
    wire signed [31:0] diff_5 = $signed(feat5) - $signed(recon_5);
    wire signed [31:0] diff_6 = $signed(feat6) - $signed(recon_6);
    wire signed [31:0] diff_7 = $signed(feat7) - $signed(recon_7);
    wire signed [31:0] diff_8 = $signed(feat8) - $signed(recon_8);
    wire signed [31:0] diff_9 = $signed(feat9) - $signed(recon_9);
    wire signed [31:0] diff_10 = $signed(feat10) - $signed(recon_10);
    wire signed [31:0] diff_11 = $signed(feat11) - $signed(recon_11);
    wire signed [31:0] diff_12 = $signed(feat12) - $signed(recon_12);
    wire signed [31:0] diff_13 = $signed(feat13) - $signed(recon_13);
    wire signed [31:0] diff_14 = $signed(feat14) - $signed(recon_14);

    wire signed [63:0] sq_0 = diff_0 * diff_0;
    wire signed [63:0] sq_1 = diff_1 * diff_1;
    wire signed [63:0] sq_2 = diff_2 * diff_2;
    wire signed [63:0] sq_3 = diff_3 * diff_3;
    wire signed [63:0] sq_4 = diff_4 * diff_4;
    wire signed [63:0] sq_5 = diff_5 * diff_5;
    wire signed [63:0] sq_6 = diff_6 * diff_6;
    wire signed [63:0] sq_7 = diff_7 * diff_7;
    wire signed [63:0] sq_8 = diff_8 * diff_8;
    wire signed [63:0] sq_9 = diff_9 * diff_9;
    wire signed [63:0] sq_10 = diff_10 * diff_10;
    wire signed [63:0] sq_11 = diff_11 * diff_11;
    wire signed [63:0] sq_12 = diff_12 * diff_12;
    wire signed [63:0] sq_13 = diff_13 * diff_13;
    wire signed [63:0] sq_14 = diff_14 * diff_14;

    wire signed [63:0] mse_sum =
        sq_0 +
        sq_1 +
        sq_2 +
        sq_3 +
        sq_4 +
        sq_5 +
        sq_6 +
        sq_7 +
        sq_8 +
        sq_9 +
        sq_10 +
        sq_11 +
        sq_12 +
        sq_13 +
        sq_14;

    // Divide by 15 (shift approximation: /15 ≈ *17>>8)
    assign ae_error = mse_sum[47:16];  // take bits [47:16] = /65536 keeps Q8.8² range

    assign anomaly = (ae_error > AE_THRESH) ? 1'b1 : 1'b0;

endmodule