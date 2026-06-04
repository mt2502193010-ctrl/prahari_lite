`timescale 1ns/1ps
// PRAHARI-Lite — AXI4-Lite Slave Wrapper
// Register map (word-addressed, byte offset):
//   0x00 Control  [0]=start (auto-clear)
//   0x04 Status   [0]=done  [1]=zero_day
//   0x08..0x40  feat[0..14] (16-bit raw, scaler applied in hardware)
//   0x48 Result  [2:0]=final_class
//   0x4C AE Error (32-bit)
module prahari_lite_axi #(
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 7
)(
    input  wire                             s_axi_aclk,
    input  wire                             s_axi_aresetn,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]   s_axi_awaddr,
    input  wire [2:0]                       s_axi_awprot,
    input  wire                             s_axi_awvalid,
    output wire                             s_axi_awready,
    input  wire [C_S_AXI_DATA_WIDTH-1:0]   s_axi_wdata,
    input  wire [C_S_AXI_DATA_WIDTH/8-1:0] s_axi_wstrb,
    input  wire                             s_axi_wvalid,
    output wire                             s_axi_wready,
    output wire [1:0]                       s_axi_bresp,
    output wire                             s_axi_bvalid,
    input  wire                             s_axi_bready,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]   s_axi_araddr,
    input  wire [2:0]                       s_axi_arprot,
    input  wire                             s_axi_arvalid,
    output wire                             s_axi_arready,
    output wire [C_S_AXI_DATA_WIDTH-1:0]   s_axi_rdata,
    output wire [1:0]                       s_axi_rresp,
    output wire                             s_axi_rvalid,
    input  wire                             s_axi_rready
);

// ── Feature registers (Q8.8 pre-scaled by software) ──────────────────────────
// Hardware scaler removed (Fix 2): 11 of 15 INV_SCALE values rounded to zero
// in Q8.8 representation, zeroing those features.  Software now applies:
//   q = round((raw - mean) / std * 256), clamped to signed 16-bit.
// See test_pynq.py: to_q88() and SCALER_MEAN / SCALER_SCALE constants.
    reg signed [15:0] feat_reg_0;
    reg signed [15:0] feat_reg_1;
    reg signed [15:0] feat_reg_2;
    reg signed [15:0] feat_reg_3;
    reg signed [15:0] feat_reg_4;
    reg signed [15:0] feat_reg_5;
    reg signed [15:0] feat_reg_6;
    reg signed [15:0] feat_reg_7;
    reg signed [15:0] feat_reg_8;
    reg signed [15:0] feat_reg_9;
    reg signed [15:0] feat_reg_10;
    reg signed [15:0] feat_reg_11;
    reg signed [15:0] feat_reg_12;
    reg signed [15:0] feat_reg_13;
    reg signed [15:0] feat_reg_14;

// ── prahari_lite_top instance ─────────────────────────────────────────────────
reg  start_r;
wire [2:0]  final_class;
wire        zero_day;
wire        valid;
wire [31:0] ae_error;

prahari_lite_top u_top (
    .clk      (s_axi_aclk),    .rst    (~s_axi_aresetn),
    .start    (start_r),
    .feat0    (feat_reg_0),    .feat1  (feat_reg_1),
    .feat2    (feat_reg_2),    .feat3  (feat_reg_3),
    .feat4    (feat_reg_4),    .feat5  (feat_reg_5),
    .feat6    (feat_reg_6),    .feat7  (feat_reg_7),
    .feat8    (feat_reg_8),    .feat9  (feat_reg_9),
    .feat10   (feat_reg_10),   .feat11 (feat_reg_11),
    .feat12   (feat_reg_12),   .feat13 (feat_reg_13),
    .feat14   (feat_reg_14),
    .final_class(final_class),  .zero_day(zero_day),
    .valid    (valid),          .ae_error(ae_error)
);

// ── AXI Write channel ──────────────────────────────────────────────────────────
reg       awready_r, wready_r, bvalid_r;
reg [6:0] awaddr_r;
reg [31:0] wdata_r;

assign s_axi_awready = awready_r;
assign s_axi_wready  = wready_r;
assign s_axi_bresp   = 2'b00;
assign s_axi_bvalid  = bvalid_r;

always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
        awready_r <= 1'b0; wready_r <= 1'b0; bvalid_r <= 1'b0;
        awaddr_r  <= 7'd0; wdata_r  <= 32'd0;
        start_r   <= 1'b0;
    end else begin
        start_r <= 1'b0;   // auto-clear
        if (!awready_r && s_axi_awvalid && s_axi_wvalid) begin
            awready_r <= 1'b1;
            awaddr_r  <= s_axi_awaddr;
        end else awready_r <= 1'b0;
        if (!wready_r && s_axi_wvalid && s_axi_awvalid) begin
            wready_r <= 1'b1;
            wdata_r  <= s_axi_wdata;
        end else wready_r <= 1'b0;
        if (awready_r && s_axi_awvalid && wready_r && s_axi_wvalid) begin
            case (awaddr_r[6:2])
                5'd0: start_r <= wdata_r[0];   // Control
                    5'd2: feat_reg_0 <= wdata_r[15:0];
                    5'd3: feat_reg_1 <= wdata_r[15:0];
                    5'd4: feat_reg_2 <= wdata_r[15:0];
                    5'd5: feat_reg_3 <= wdata_r[15:0];
                    5'd6: feat_reg_4 <= wdata_r[15:0];
                    5'd7: feat_reg_5 <= wdata_r[15:0];
                    5'd8: feat_reg_6 <= wdata_r[15:0];
                    5'd9: feat_reg_7 <= wdata_r[15:0];
                    5'd10: feat_reg_8 <= wdata_r[15:0];
                    5'd11: feat_reg_9 <= wdata_r[15:0];
                    5'd12: feat_reg_10 <= wdata_r[15:0];
                    5'd13: feat_reg_11 <= wdata_r[15:0];
                    5'd14: feat_reg_12 <= wdata_r[15:0];
                    5'd15: feat_reg_13 <= wdata_r[15:0];
                    5'd16: feat_reg_14 <= wdata_r[15:0];
                default: ;
            endcase
            bvalid_r <= 1'b1;
        end
        if (bvalid_r && s_axi_bready) bvalid_r <= 1'b0;
    end
end

// ── AXI Read channel ───────────────────────────────────────────────────────────
reg        arready_r, rvalid_r;
reg [31:0] rdata_r;
reg [6:0]  araddr_r;

assign s_axi_arready = arready_r;
assign s_axi_rdata   = rdata_r;
assign s_axi_rresp   = 2'b00;
assign s_axi_rvalid  = rvalid_r;

always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
        arready_r <= 1'b0; rvalid_r <= 1'b0;
        rdata_r   <= 32'd0; araddr_r <= 7'd0;
    end else begin
        if (!arready_r && s_axi_arvalid) begin
            arready_r <= 1'b1;
            araddr_r  <= s_axi_araddr;
        end else arready_r <= 1'b0;
        if (arready_r && s_axi_arvalid && !rvalid_r) begin
            rvalid_r <= 1'b1;
            case (araddr_r[6:2])
                5'd0: rdata_r <= {31'd0, start_r};
                5'd1: rdata_r <= {30'd0, zero_day, valid};
                5'd2: rdata_r <= {16'd0, feat_reg_0};
                5'd3: rdata_r <= {16'd0, feat_reg_1};
                5'd4: rdata_r <= {16'd0, feat_reg_2};
                5'd5: rdata_r <= {16'd0, feat_reg_3};
                5'd6: rdata_r <= {16'd0, feat_reg_4};
                5'd7: rdata_r <= {16'd0, feat_reg_5};
                5'd8: rdata_r <= {16'd0, feat_reg_6};
                5'd9: rdata_r <= {16'd0, feat_reg_7};
                5'd10: rdata_r <= {16'd0, feat_reg_8};
                5'd11: rdata_r <= {16'd0, feat_reg_9};
                5'd12: rdata_r <= {16'd0, feat_reg_10};
                5'd13: rdata_r <= {16'd0, feat_reg_11};
                5'd14: rdata_r <= {16'd0, feat_reg_12};
                5'd15: rdata_r <= {16'd0, feat_reg_13};
                5'd16: rdata_r <= {16'd0, feat_reg_14};
                5'd18: rdata_r <= {29'd0, final_class};
                5'd19: rdata_r <= ae_error;
                default: rdata_r <= 32'd0;
            endcase
        end
        if (rvalid_r && s_axi_rready) rvalid_r <= 1'b0;
    end
end

endmodule
