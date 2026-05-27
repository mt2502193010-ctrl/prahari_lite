`timescale 1ns/1ps
// PRAHARI-Lite — AXI4-Lite Slave Wrapper
// Register map (word-addressed, byte offset):
//   0x00 Control  [0]=start (auto-clear)
//   0x04 Status   [0]=done  [1]=zero_day
//   0x08..0x44  feat[0..14] (16-bit raw, scaler applied in hardware)
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

// ── Scaler constants (MEAN in Q8.8, INV_SCALE in Q8.8) ───────────────────────
    localparam signed [31:0] MEAN_ 0     = 32'sd     1595965;  // 6234.2394
    localparam signed [31:0] MEAN_ 1     = 32'sd     1025179;  // 4004.6048
    localparam signed [31:0] MEAN_ 2     = 32'sd      843020;  // 3293.0471
    localparam signed [31:0] MEAN_ 3     = 32'sd     1687872;  // 6593.2482
    localparam signed [31:0] MEAN_ 4     = 32'sd     3906231;  // 15258.7137
    localparam signed [31:0] MEAN_ 5     = 32'sd     -747680;  // -2920.6255
    localparam signed [31:0] MEAN_ 6     = 32'sd       21320;  // 83.2805
    localparam signed [31:0] MEAN_ 7     = 32'sd   294388901;  // 1149956.6438
    localparam signed [31:0] MEAN_ 8     = 32'sd  2147483647;  // 8473172.6482
    localparam signed [31:0] MEAN_ 9     = 32'sd   165412066;  // 646140.8829
    localparam signed [31:0] MEAN_10     = 32'sd       34936;  // 136.4693
    localparam signed [31:0] MEAN_11     = 32'sd       98831;  // 386.0599
    localparam signed [31:0] MEAN_12     = 32'sd        3432;  // 13.4067
    localparam signed [31:0] MEAN_13     = 32'sd           7;  // 0.0283
    localparam signed [31:0] MEAN_14     = 32'sd       20556;  // 80.2960
    localparam        [31:0] INV_SCALE_ 0 = 32'd           0;  // 1/16276.1398
    localparam        [31:0] INV_SCALE_ 1 = 32'd           0;  // 1/121751.0535
    localparam        [31:0] INV_SCALE_ 2 = 32'd           0;  // 1/12446.9864
    localparam        [31:0] INV_SCALE_ 3 = 32'd           0;  // 1/14924.5629
    localparam        [31:0] INV_SCALE_ 4 = 32'd           0;  // 1/1822821.7947
    localparam        [31:0] INV_SCALE_ 5 = 32'd           0;  // 1/1122323.8239
    localparam        [31:0] INV_SCALE_ 6 = 32'd           2;  // 1/169.2721
    localparam        [31:0] INV_SCALE_ 7 = 32'd           0;  // 1/9106573.2496
    localparam        [31:0] INV_SCALE_ 8 = 32'd           0;  // 1/26295131.5132
    localparam        [31:0] INV_SCALE_ 9 = 32'd           0;  // 1/16298275.2529
    localparam        [31:0] INV_SCALE_10 = 32'd           1;  // 1/236.5029
    localparam        [31:0] INV_SCALE_11 = 32'd           0;  // 1/1199.4642
    localparam        [31:0] INV_SCALE_12 = 32'd           0;  // 1/840.1300
    localparam        [31:0] INV_SCALE_13 = 32'd        1544;  // 1/0.1659
    localparam        [31:0] INV_SCALE_14 = 32'd           1;  // 1/196.6833

// ── Feature registers (raw Q8.8 from CPU) ─────────────────────────────────────
    reg [15:0] feat_reg_ 0;
    reg [15:0] feat_reg_ 1;
    reg [15:0] feat_reg_ 2;
    reg [15:0] feat_reg_ 3;
    reg [15:0] feat_reg_ 4;
    reg [15:0] feat_reg_ 5;
    reg [15:0] feat_reg_ 6;
    reg [15:0] feat_reg_ 7;
    reg [15:0] feat_reg_ 8;
    reg [15:0] feat_reg_ 9;
    reg [15:0] feat_reg_10;
    reg [15:0] feat_reg_11;
    reg [15:0] feat_reg_12;
    reg [15:0] feat_reg_13;
    reg [15:0] feat_reg_14;

// ── Normalised features (hardware scaler) ─────────────────────────────────────
    wire signed [15:0] feat_ 0_norm = $signed((($signed({16'd0, feat_reg_ 0}) - MEAN_ 0) * $signed(INV_SCALE_ 0)) >>> 8);
    wire signed [15:0] feat_ 1_norm = $signed((($signed({16'd0, feat_reg_ 1}) - MEAN_ 1) * $signed(INV_SCALE_ 1)) >>> 8);
    wire signed [15:0] feat_ 2_norm = $signed((($signed({16'd0, feat_reg_ 2}) - MEAN_ 2) * $signed(INV_SCALE_ 2)) >>> 8);
    wire signed [15:0] feat_ 3_norm = $signed((($signed({16'd0, feat_reg_ 3}) - MEAN_ 3) * $signed(INV_SCALE_ 3)) >>> 8);
    wire signed [15:0] feat_ 4_norm = $signed((($signed({16'd0, feat_reg_ 4}) - MEAN_ 4) * $signed(INV_SCALE_ 4)) >>> 8);
    wire signed [15:0] feat_ 5_norm = $signed((($signed({16'd0, feat_reg_ 5}) - MEAN_ 5) * $signed(INV_SCALE_ 5)) >>> 8);
    wire signed [15:0] feat_ 6_norm = $signed((($signed({16'd0, feat_reg_ 6}) - MEAN_ 6) * $signed(INV_SCALE_ 6)) >>> 8);
    wire signed [15:0] feat_ 7_norm = $signed((($signed({16'd0, feat_reg_ 7}) - MEAN_ 7) * $signed(INV_SCALE_ 7)) >>> 8);
    wire signed [15:0] feat_ 8_norm = $signed((($signed({16'd0, feat_reg_ 8}) - MEAN_ 8) * $signed(INV_SCALE_ 8)) >>> 8);
    wire signed [15:0] feat_ 9_norm = $signed((($signed({16'd0, feat_reg_ 9}) - MEAN_ 9) * $signed(INV_SCALE_ 9)) >>> 8);
    wire signed [15:0] feat_10_norm = $signed((($signed({16'd0, feat_reg_10}) - MEAN_10) * $signed(INV_SCALE_10)) >>> 8);
    wire signed [15:0] feat_11_norm = $signed((($signed({16'd0, feat_reg_11}) - MEAN_11) * $signed(INV_SCALE_11)) >>> 8);
    wire signed [15:0] feat_12_norm = $signed((($signed({16'd0, feat_reg_12}) - MEAN_12) * $signed(INV_SCALE_12)) >>> 8);
    wire signed [15:0] feat_13_norm = $signed((($signed({16'd0, feat_reg_13}) - MEAN_13) * $signed(INV_SCALE_13)) >>> 8);
    wire signed [15:0] feat_14_norm = $signed((($signed({16'd0, feat_reg_14}) - MEAN_14) * $signed(INV_SCALE_14)) >>> 8);

// ── prahari_lite_top instance ─────────────────────────────────────────────────
reg  start_r;
wire [2:0]  final_class;
wire        zero_day;
wire        valid;
wire [31:0] ae_error;

prahari_lite_top u_top (
    .clk      (s_axi_aclk),    .rst    (~s_axi_aresetn),
    .start    (start_r),
    .feat0    (feat_00_norm),   .feat1  (feat_01_norm),
    .feat2    (feat_02_norm),   .feat3  (feat_03_norm),
    .feat4    (feat_04_norm),   .feat5  (feat_05_norm),
    .feat6    (feat_06_norm),   .feat7  (feat_07_norm),
    .feat8    (feat_08_norm),   .feat9  (feat_09_norm),
    .feat10   (feat_10_norm),   .feat11 (feat_11_norm),
    .feat12   (feat_12_norm),   .feat13 (feat_13_norm),
    .feat14   (feat_14_norm),
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
                    5'd2: feat_reg_ 0 <= wdata_r[15:0];
                    5'd3: feat_reg_ 1 <= wdata_r[15:0];
                    5'd4: feat_reg_ 2 <= wdata_r[15:0];
                    5'd5: feat_reg_ 3 <= wdata_r[15:0];
                    5'd6: feat_reg_ 4 <= wdata_r[15:0];
                    5'd7: feat_reg_ 5 <= wdata_r[15:0];
                    5'd8: feat_reg_ 6 <= wdata_r[15:0];
                    5'd9: feat_reg_ 7 <= wdata_r[15:0];
                    5'd10: feat_reg_ 8 <= wdata_r[15:0];
                    5'd11: feat_reg_ 9 <= wdata_r[15:0];
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
                5'd2: rdata_r <= {16'd0, feat_reg_ 0};
                5'd3: rdata_r <= {16'd0, feat_reg_ 1};
                5'd4: rdata_r <= {16'd0, feat_reg_ 2};
                5'd5: rdata_r <= {16'd0, feat_reg_ 3};
                5'd6: rdata_r <= {16'd0, feat_reg_ 4};
                5'd7: rdata_r <= {16'd0, feat_reg_ 5};
                5'd8: rdata_r <= {16'd0, feat_reg_ 6};
                5'd9: rdata_r <= {16'd0, feat_reg_ 7};
                5'd10: rdata_r <= {16'd0, feat_reg_ 8};
                5'd11: rdata_r <= {16'd0, feat_reg_ 9};
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
