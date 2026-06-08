// ============================================================
// PRAHARI-LITE Complete RTL Simulation — EDA Playground v3
// Simulator: Icarus Verilog 12.0
// Paste entire file into the single editor pane, Run.
// ============================================================
`timescale 1ns/1ps

// ============================================================
// MODULE 1 — dt_inference_sim
// ROM-based state machine, Q8.8, 15 nodes, depth-4 stub
// Structurally identical to production dt_inference.v
// ============================================================
module dt_inference_sim(
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire signed [15:0] f0,f1,f2,f3,f4,f5,
                              f6,f7,f8,f9,f10,f11,
                              f12,f13,f14,
    output reg  [2:0]  class_out,
    output reg  [7:0]  purity_out,
    output reg         done
);
    // Flatten feature array — avoids Icarus unpacked port issues
    wire signed [15:0] feat[0:14];
    assign feat[0]=f0; assign feat[1]=f1; assign feat[2]=f2;
    assign feat[3]=f3; assign feat[4]=f4; assign feat[5]=f5;
    assign feat[6]=f6; assign feat[7]=f7; assign feat[8]=f8;
    assign feat[9]=f9; assign feat[10]=f10; assign feat[11]=f11;
    assign feat[12]=f12; assign feat[13]=f13; assign feat[14]=f14;

    // ROM: {is_leaf[39], feat_idx[38:35], threshold[34:19],
    //        left[18:15], right[14:11], class[10:8], purity[7:0]}
    reg [39:0] rom[0:14];
    initial begin
        // Node 0 root: feat[0]=dst_port <= 20480(=80.0) → left=1, right=2
        rom[0]  = {1'b0, 4'd0,  16'd20480, 4'd1, 4'd2, 3'd0, 8'd0  };
        // Node 1: feat[13]=syn_flag <= 128(=0.5) → left=3(NORMAL), right=4(RECON)
        rom[1]  = {1'b0, 4'd13, 16'd128,   4'd3, 4'd4, 3'd0, 8'd0  };
        // Node 2: feat[7]=flow_iat_min <= 25600(=100.0) → left=5(APT), right=6
        rom[2]  = {1'b0, 4'd7,  16'd25600, 4'd5, 4'd6, 3'd0, 8'd0  };
        // Node 3: feat[1]=fwd_bytes <= 5120(=20.0) → left=7(RECON), right=8(NORMAL)
        rom[3]  = {1'b0, 4'd1,  16'd5120,  4'd7, 4'd8, 3'd0, 8'd0  };
        // Node 4: feat[9]=flow_byts_s <= 10240(=40.0) → left=9, right=10
        rom[4]  = {1'b0, 4'd9,  16'd10240, 4'd9, 4'd10,3'd0, 8'd0  };
        // Node 5: feat[8]=duration <= 7680(=30.0) → left=11(APT), right=12(APT)
        rom[5]  = {1'b0, 4'd8,  16'd7680,  4'd11,4'd12,3'd0, 8'd0  };
        // Node 6: feat[1]=fwd_bytes <= 16640(=65.0) → left=13(TS), right=14(NRM)
        rom[6]  = {1'b0, 4'd1,  16'd16640, 4'd13,4'd14,3'd0, 8'd0  };
        // Leaves
        rom[7]  = {1'b1, 4'd0, 16'd0, 4'd0, 4'd0, 3'd2, 8'd242}; // RECON  p=0.95
        rom[8]  = {1'b1, 4'd0, 16'd0, 4'd0, 4'd0, 3'd0, 8'd252}; // NORMAL p=0.99
        rom[9]  = {1'b1, 4'd0, 16'd0, 4'd0, 4'd0, 3'd2, 8'd230}; // RECON  p=0.90
        rom[10] = {1'b1, 4'd0, 16'd0, 4'd0, 4'd0, 3'd0, 8'd245}; // NORMAL p=0.96
        rom[11] = {1'b1, 4'd0, 16'd0, 4'd0, 4'd0, 3'd1, 8'd238}; // APT    p=0.93
        rom[12] = {1'b1, 4'd0, 16'd0, 4'd0, 4'd0, 3'd1, 8'd180}; // APT    p=0.70 (low purity for ZD test)
        rom[13] = {1'b1, 4'd0, 16'd0, 4'd0, 4'd0, 3'd3, 8'd235}; // TRAF_SPIKE p=0.92
        rom[14] = {1'b1, 4'd0, 16'd0, 4'd0, 4'd0, 3'd4, 8'd228}; // NR_MAL p=0.89
    end

    localparam ST_IDLE=2'd0, ST_TRAV=2'd1, ST_DONE=2'd2;
    reg [1:0] state;
    reg [3:0] nidx;
    reg [4:0] depth;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state<=ST_IDLE; nidx<=0; depth<=0;
            class_out<=0; purity_out<=0; done<=0;
        end else begin
            case(state)
                ST_IDLE: begin
                    done<=0;
                    if(start) begin nidx<=0; depth<=0; state<=ST_TRAV; end
                end
                ST_TRAV: begin
                    if(rom[nidx][39]) begin           // leaf
                        class_out  <= rom[nidx][10:8];
                        purity_out <= rom[nidx][7:0];
                        state      <= ST_DONE;
                    end else begin                    // internal
                        if($signed(feat[rom[nidx][38:35]]) <= $signed(rom[nidx][34:19]))
                            nidx <= rom[nidx][18:15];
                        else
                            nidx <= rom[nidx][14:11];
                        depth <= depth+1;
                        if(depth>=15) state<=ST_DONE; // safety
                    end
                end
                ST_DONE: begin done<=1; state<=ST_IDLE; end
            endcase
        end
    end
endmodule


// ============================================================
// MODULE 2 — ae_inference_sim
// Combinational Q4.4 encoder-decoder, MSE error, threshold=158206
// Avoids 2D arrays — uses flat wires compatible with Icarus 12
// ============================================================
module ae_inference_sim(
    input  wire signed [15:0] f0,f1,f2,f3,f4,f5,
                              f6,f7,f8,f9,f10,f11,
                              f12,f13,f14,
    output wire        anomaly,
    output wire [31:0] ae_error
);
    // Encoder: 4 neurons. Each weight = Q4.4 signed 8-bit.
    // W[neuron][feat] pattern: (i+j)%3==0 → +2, ==1 → -1, else +1
    // z[i] = ReLU(sum_j W[i][j]*feat[j] / 16)
    // Using 32-bit accumulators throughout

    wire signed [15:0] feat[0:14];
    assign feat[0]=f0;  assign feat[1]=f1;  assign feat[2]=f2;
    assign feat[3]=f3;  assign feat[4]=f4;  assign feat[5]=f5;
    assign feat[6]=f6;  assign feat[7]=f7;  assign feat[8]=f8;
    assign feat[9]=f9;  assign feat[10]=f10;assign feat[11]=f11;
    assign feat[12]=f12;assign feat[13]=f13;assign feat[14]=f14;

    // Weight function (pure combinational, no arrays)
    // Weights 32/-16/16 in Q4.4 → large reconstruction error for extreme T6 features
    function signed [7:0] W1;
        input [1:0] i; input [3:0] j;
        reg [4:0] s;
        begin s = i+j; W1 = (s%3==0)?8'sd32:(s%3==1)?-8'sd16:8'sd16; end
    endfunction
    function signed [7:0] W2;
        input [3:0] i; input [1:0] j;
        reg [4:0] s;
        begin s = i+j; W2 = (s%3==0)?8'sd32:(s%3==1)?-8'sd16:8'sd16; end
    endfunction

    // Encoder neuron 0
    wire signed [31:0] e0_sum;
    assign e0_sum = (W1(0,0)*feat[0] + W1(0,1)*feat[1] + W1(0,2)*feat[2]  +
                     W1(0,3)*feat[3] + W1(0,4)*feat[4] + W1(0,5)*feat[5]  +
                     W1(0,6)*feat[6] + W1(0,7)*feat[7] + W1(0,8)*feat[8]  +
                     W1(0,9)*feat[9] + W1(0,10)*feat[10]+W1(0,11)*feat[11] +
                     W1(0,12)*feat[12]+W1(0,13)*feat[13]+W1(0,14)*feat[14])>>>4;
    wire signed [31:0] z0; assign z0 = (e0_sum<0)?0:e0_sum;

    // Encoder neuron 1
    wire signed [31:0] e1_sum;
    assign e1_sum = (W1(1,0)*feat[0] + W1(1,1)*feat[1] + W1(1,2)*feat[2]  +
                     W1(1,3)*feat[3] + W1(1,4)*feat[4] + W1(1,5)*feat[5]  +
                     W1(1,6)*feat[6] + W1(1,7)*feat[7] + W1(1,8)*feat[8]  +
                     W1(1,9)*feat[9] + W1(1,10)*feat[10]+W1(1,11)*feat[11] +
                     W1(1,12)*feat[12]+W1(1,13)*feat[13]+W1(1,14)*feat[14])>>>4;
    wire signed [31:0] z1; assign z1 = (e1_sum<0)?0:e1_sum;

    // Encoder neuron 2
    wire signed [31:0] e2_sum;
    assign e2_sum = (W1(2,0)*feat[0] + W1(2,1)*feat[1] + W1(2,2)*feat[2]  +
                     W1(2,3)*feat[3] + W1(2,4)*feat[4] + W1(2,5)*feat[5]  +
                     W1(2,6)*feat[6] + W1(2,7)*feat[7] + W1(2,8)*feat[8]  +
                     W1(2,9)*feat[9] + W1(2,10)*feat[10]+W1(2,11)*feat[11] +
                     W1(2,12)*feat[12]+W1(2,13)*feat[13]+W1(2,14)*feat[14])>>>4;
    wire signed [31:0] z2; assign z2 = (e2_sum<0)?0:e2_sum;

    // Encoder neuron 3
    wire signed [31:0] e3_sum;
    assign e3_sum = (W1(3,0)*feat[0] + W1(3,1)*feat[1] + W1(3,2)*feat[2]  +
                     W1(3,3)*feat[3] + W1(3,4)*feat[4] + W1(3,5)*feat[5]  +
                     W1(3,6)*feat[6] + W1(3,7)*feat[7] + W1(3,8)*feat[8]  +
                     W1(3,9)*feat[9] + W1(3,10)*feat[10]+W1(3,11)*feat[11] +
                     W1(3,12)*feat[12]+W1(3,13)*feat[13]+W1(3,14)*feat[14])>>>4;
    wire signed [31:0] z3; assign z3 = (e3_sum<0)?0:e3_sum;

    // Decoder — 15 outputs, each sums 4 latent neurons
    wire signed [31:0] r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14;
    assign r0  = (W2(0, 0)*z0+W2(0, 1)*z1+W2(0, 2)*z2+W2(0, 3)*z3)>>>4;
    assign r1  = (W2(1, 0)*z0+W2(1, 1)*z1+W2(1, 2)*z2+W2(1, 3)*z3)>>>4;
    assign r2  = (W2(2, 0)*z0+W2(2, 1)*z1+W2(2, 2)*z2+W2(2, 3)*z3)>>>4;
    assign r3  = (W2(3, 0)*z0+W2(3, 1)*z1+W2(3, 2)*z2+W2(3, 3)*z3)>>>4;
    assign r4  = (W2(4, 0)*z0+W2(4, 1)*z1+W2(4, 2)*z2+W2(4, 3)*z3)>>>4;
    assign r5  = (W2(5, 0)*z0+W2(5, 1)*z1+W2(5, 2)*z2+W2(5, 3)*z3)>>>4;
    assign r6  = (W2(6, 0)*z0+W2(6, 1)*z1+W2(6, 2)*z2+W2(6, 3)*z3)>>>4;
    assign r7  = (W2(7, 0)*z0+W2(7, 1)*z1+W2(7, 2)*z2+W2(7, 3)*z3)>>>4;
    assign r8  = (W2(8, 0)*z0+W2(8, 1)*z1+W2(8, 2)*z2+W2(8, 3)*z3)>>>4;
    assign r9  = (W2(9, 0)*z0+W2(9, 1)*z1+W2(9, 2)*z2+W2(9, 3)*z3)>>>4;
    assign r10 = (W2(10,0)*z0+W2(10,1)*z1+W2(10,2)*z2+W2(10,3)*z3)>>>4;
    assign r11 = (W2(11,0)*z0+W2(11,1)*z1+W2(11,2)*z2+W2(11,3)*z3)>>>4;
    assign r12 = (W2(12,0)*z0+W2(12,1)*z1+W2(12,2)*z2+W2(12,3)*z3)>>>4;
    assign r13 = (W2(13,0)*z0+W2(13,1)*z1+W2(13,2)*z2+W2(13,3)*z3)>>>4;
    assign r14 = (W2(14,0)*z0+W2(14,1)*z1+W2(14,2)*z2+W2(14,3)*z3)>>>4;

    // MSE = sum((feat-recon)^2) / 15, result in Q16.16
    wire signed [63:0] sq0,sq1,sq2,sq3,sq4,sq5,sq6,sq7,
                       sq8,sq9,sq10,sq11,sq12,sq13,sq14;
    assign sq0  = (feat[0] -r0 )*(feat[0] -r0 );
    assign sq1  = (feat[1] -r1 )*(feat[1] -r1 );
    assign sq2  = (feat[2] -r2 )*(feat[2] -r2 );
    assign sq3  = (feat[3] -r3 )*(feat[3] -r3 );
    assign sq4  = (feat[4] -r4 )*(feat[4] -r4 );
    assign sq5  = (feat[5] -r5 )*(feat[5] -r5 );
    assign sq6  = (feat[6] -r6 )*(feat[6] -r6 );
    assign sq7  = (feat[7] -r7 )*(feat[7] -r7 );
    assign sq8  = (feat[8] -r8 )*(feat[8] -r8 );
    assign sq9  = (feat[9] -r9 )*(feat[9] -r9 );
    assign sq10 = (feat[10]-r10)*(feat[10]-r10);
    assign sq11 = (feat[11]-r11)*(feat[11]-r11);
    assign sq12 = (feat[12]-r12)*(feat[12]-r12);
    assign sq13 = (feat[13]-r13)*(feat[13]-r13);
    assign sq14 = (feat[14]-r14)*(feat[14]-r14);

    wire [63:0] mse_sum;
    assign mse_sum = sq0+sq1+sq2+sq3+sq4+sq5+sq6+sq7+
                     sq8+sq9+sq10+sq11+sq12+sq13+sq14;

    // Shift to Q16.16 and divide by 15
    wire [31:0] mse_q;
    assign mse_q   = mse_sum[47:16] / 15;
    assign ae_error = mse_q;
    assign anomaly  = (mse_q > 32'd158206) ? 1'b1 : 1'b0;
endmodule


// ============================================================
// MODULE 3 — fusion_logic  (IDENTICAL to production)
// ============================================================
module fusion_logic(
    input  wire [2:0] dt_class,
    input  wire [7:0] dt_purity,
    input  wire       ae_anomaly,
    input  wire       dt_done,
    output reg  [2:0] final_class,
    output reg        zero_day,
    output reg        valid
);
    always @(*) begin
        valid       = dt_done;
        zero_day    = 0;
        final_class = dt_class;
        if (dt_done) begin
            if ((dt_purity < 8'd192) && ae_anomaly) begin
                zero_day    = 1;
                final_class = 3'd5;
            end
        end
    end
endmodule


// ============================================================
// MODULE 4 — prahari_lite_top  (IDENTICAL wiring to production)
// ============================================================
module prahari_lite_top(
    input  wire        clk, rst, start,
    input  wire signed [15:0] f0,f1,f2,f3,f4,f5,
                               f6,f7,f8,f9,f10,f11,f12,f13,f14,
    output wire [2:0]  final_class,
    output wire        zero_day, valid,
    output wire [31:0] ae_error
);
    wire [2:0] dt_class;
    wire [7:0] dt_purity;
    wire       dt_done, ae_anomaly;

    dt_inference_sim DT(
        .clk(clk),.rst(rst),.start(start),
        .f0(f0),.f1(f1),.f2(f2),.f3(f3),.f4(f4),.f5(f5),
        .f6(f6),.f7(f7),.f8(f8),.f9(f9),.f10(f10),.f11(f11),
        .f12(f12),.f13(f13),.f14(f14),
        .class_out(dt_class),.purity_out(dt_purity),.done(dt_done)
    );
    ae_inference_sim AE(
        .f0(f0),.f1(f1),.f2(f2),.f3(f3),.f4(f4),.f5(f5),
        .f6(f6),.f7(f7),.f8(f8),.f9(f9),.f10(f10),.f11(f11),
        .f12(f12),.f13(f13),.f14(f14),
        .anomaly(ae_anomaly),.ae_error(ae_error)
    );
    fusion_logic FU(
        .dt_class(dt_class),.dt_purity(dt_purity),
        .ae_anomaly(ae_anomaly),.dt_done(dt_done),
        .final_class(final_class),.zero_day(zero_day),.valid(valid)
    );
endmodule


// ============================================================
// MODULE 5 — prahari_lite_axi (rewritten — single always block)
// Key fixes:
//   1. AW+W handled together: address latched, data written, bvalid next cycle
//   2. start_r driven combinationally from reg_ctrl[0] — no cross-block race
//   3. wready only pulses once per transaction (gated by bvalid)
//   4. Read channel: rdata registered, rvalid held until rready
// ============================================================
module prahari_lite_axi(
    input  wire        s_axi_aclk, s_axi_aresetn,
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready
);
    reg [31:0] reg_ctrl, reg_status, reg_result, reg_ae_err;
    reg signed [15:0] rf[0:14];

    wire [2:0] fc; wire zd, vld; wire [31:0] ae_err_w;

    // start_r is combinational from reg_ctrl[0] — no always-block race
    wire start_r = reg_ctrl[0];

    prahari_lite_top TOP(
        .clk(s_axi_aclk),.rst(~s_axi_aresetn),.start(start_r),
        .f0(rf[0]),.f1(rf[1]),.f2(rf[2]),.f3(rf[3]),.f4(rf[4]),
        .f5(rf[5]),.f6(rf[6]),.f7(rf[7]),.f8(rf[8]),.f9(rf[9]),
        .f10(rf[10]),.f11(rf[11]),.f12(rf[12]),.f13(rf[13]),.f14(rf[14]),
        .final_class(fc),.zero_day(zd),.valid(vld),.ae_error(ae_err_w)
    );

    integer k;

    // ── Single unified always block ───────────────────────────
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 0; s_axi_wready  <= 0;
            s_axi_bvalid  <= 0; s_axi_bresp   <= 0;
            s_axi_arready <= 0; s_axi_rvalid  <= 0;
            s_axi_rdata   <= 0; s_axi_rresp   <= 0;
            reg_ctrl <= 0; reg_status <= 0;
            reg_result <= 0; reg_ae_err <= 0;
            for(k=0;k<15;k=k+1) rf[k]<=0;
        end else begin

            // ── Defaults (deassert unless re-asserted below) ──
            s_axi_awready <= 0;
            s_axi_wready  <= 0;

            // ── Capture inference result ──────────────────────
            if (vld) begin
                reg_status <= {30'd0, zd, 1'b1};
                reg_result <= {29'd0, fc};
                reg_ae_err <= ae_err_w;
            end

            // ── Auto-clear start bit after one cycle ──────────
            if (reg_ctrl[0]) begin
                reg_ctrl   <= 0;
                reg_status <= 0;   // clear done while inference runs
            end

            // ── AXI Write: accept AW+W together ──────────────
            // Both awvalid and wvalid must be high simultaneously
            // (TB drives them together — this is legal per AXI spec)
            if (s_axi_awvalid && s_axi_wvalid && !s_axi_bvalid) begin
                s_axi_awready <= 1;
                s_axi_wready  <= 1;
                // Decode register from AW address directly (no aw_lat needed)
                case(s_axi_awaddr[7:0])
                    8'h00: reg_ctrl     <= s_axi_wdata;
                    8'h08: rf[0]  <= s_axi_wdata[15:0];
                    8'h0C: rf[1]  <= s_axi_wdata[15:0];
                    8'h10: rf[2]  <= s_axi_wdata[15:0];
                    8'h14: rf[3]  <= s_axi_wdata[15:0];
                    8'h18: rf[4]  <= s_axi_wdata[15:0];
                    8'h1C: rf[5]  <= s_axi_wdata[15:0];
                    8'h20: rf[6]  <= s_axi_wdata[15:0];
                    8'h24: rf[7]  <= s_axi_wdata[15:0];
                    8'h28: rf[8]  <= s_axi_wdata[15:0];
                    8'h2C: rf[9]  <= s_axi_wdata[15:0];
                    8'h30: rf[10] <= s_axi_wdata[15:0];
                    8'h34: rf[11] <= s_axi_wdata[15:0];
                    8'h38: rf[12] <= s_axi_wdata[15:0];
                    8'h3C: rf[13] <= s_axi_wdata[15:0];
                    8'h40: rf[14] <= s_axi_wdata[15:0];
                    default:;
                endcase
                s_axi_bvalid <= 1;
                s_axi_bresp  <= 0;
            end

            // ── Write response handshake ──────────────────────
            if (s_axi_bvalid && s_axi_bready) s_axi_bvalid <= 0;

            // ── AXI Read ──────────────────────────────────────
            if (s_axi_arvalid && !s_axi_arready) begin
                s_axi_arready <= 1;
                s_axi_rvalid  <= 1;
                s_axi_rresp   <= 0;
                case(s_axi_araddr[7:0])
                    8'h00: s_axi_rdata <= reg_ctrl;
                    8'h04: s_axi_rdata <= reg_status;
                    8'h44: s_axi_rdata <= reg_result;
                    8'h48: s_axi_rdata <= reg_ae_err;
                    default: s_axi_rdata <= 32'hDEAD_BEEF;
                endcase
            end else begin
                s_axi_arready <= 0;
            end
            if (s_axi_rvalid && s_axi_rready) s_axi_rvalid <= 0;
        end
    end
endmodule


// ============================================================
// TESTBENCH
// ============================================================
module tb_prahari_lite;
    reg clk=0;
    always #5 clk=~clk;   // 100 MHz

    reg        aresetn;
    reg [31:0] awaddr; reg awvalid; wire awready;
    reg [31:0] wdata;  reg wvalid;  wire wready;
    wire[1:0]  bresp;  wire bvalid; reg  bready;
    reg [31:0] araddr; reg arvalid; wire arready;
    wire[31:0] rdata;  wire[1:0] rresp; wire rvalid; reg rready;

    prahari_lite_axi DUT(
        .s_axi_aclk(clk),.s_axi_aresetn(aresetn),
        .s_axi_awaddr(awaddr),.s_axi_awvalid(awvalid),.s_axi_awready(awready),
        .s_axi_wdata(wdata),  .s_axi_wvalid(wvalid),  .s_axi_wready(wready),
        .s_axi_bresp(bresp),  .s_axi_bvalid(bvalid),  .s_axi_bready(bready),
        .s_axi_araddr(araddr),.s_axi_arvalid(arvalid),.s_axi_arready(arready),
        .s_axi_rdata(rdata),  .s_axi_rresp(rresp),    .s_axi_rvalid(rvalid),
        .s_axi_rready(rready)
    );

    // ── AXI write — hold awvalid+wvalid together until bvalid ──
    task axi_wr;
        input [31:0] addr, data;
        begin
            @(posedge clk); #1;
            awaddr=addr; awvalid=1; wdata=data; wvalid=1; bready=1;
            // Hold BOTH valid signals high until DUT accepts (bvalid fires)
            // DUT sees awvalid&&wvalid simultaneously — fires awready+wready+bvalid
            @(posedge clk);
            while(!bvalid) @(posedge clk);
            // Handshake complete — release everything
            #1; awvalid=0; wvalid=0; bready=0;
            @(posedge clk); // one idle cycle between transactions
        end
    endtask

    // ── AXI read — hold arvalid+rready until rvalid fires ───────
    reg [31:0] rd_data;
    task axi_rd;
        input [31:0] addr;
        begin
            @(posedge clk); #1;
            araddr=addr; arvalid=1; rready=1;
            // Hold arvalid high until rvalid fires
            @(posedge clk);
            while(!rvalid) @(posedge clk);
            rd_data=rdata;
            #1; arvalid=0; rready=0;
            @(posedge clk);
        end
    endtask

    // ── Write 15 features then trigger inference ──────────────
    task run_test;
        input [159:0] name;
        input [15:0] f0,f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13,f14;
        reg [31:0] status;
        integer    timeout;
        begin
            // Write features
            axi_wr(32'h43C00008,{16'd0,f0});  axi_wr(32'h43C0000C,{16'd0,f1});
            axi_wr(32'h43C00010,{16'd0,f2});  axi_wr(32'h43C00014,{16'd0,f3});
            axi_wr(32'h43C00018,{16'd0,f4});  axi_wr(32'h43C0001C,{16'd0,f5});
            axi_wr(32'h43C00020,{16'd0,f6});  axi_wr(32'h43C00024,{16'd0,f7});
            axi_wr(32'h43C00028,{16'd0,f8});  axi_wr(32'h43C0002C,{16'd0,f9});
            axi_wr(32'h43C00030,{16'd0,f10}); axi_wr(32'h43C00034,{16'd0,f11});
            axi_wr(32'h43C00038,{16'd0,f12}); axi_wr(32'h43C0003C,{16'd0,f13});
            axi_wr(32'h43C00040,{16'd0,f14});
            // Start
            axi_wr(32'h43C00000, 32'h1);
            // Wait for DT traversal (depth≤4 + pipeline = ~10 cycles minimum)
            repeat(20) @(posedge clk);
            // Poll done
            timeout=0; status=0;
            while(!status[0] && timeout<200) begin
                axi_rd(32'h43C00004); status=rd_data; timeout=timeout+1;
            end
            // Extra cycles to let reg_ae_err settle after vld (non-blocking takes 1 cycle)
            @(posedge clk); @(posedge clk); @(posedge clk);
            // Read result register (class_id)
            axi_rd(32'h43C00044);
            begin : read_result
                reg [31:0] class_reg, ae_reg;
                class_reg = rd_data;
                // Read AE error register
                axi_rd(32'h43C00048);
                ae_reg = rd_data;
                $display("[%-20s] class=%0d (%s) zd=%b ae_err=0x%08X status=0x%08X cyc=%0d",
                    name, class_reg[2:0],
                    (class_reg[2:0]==0)?"NORMAL    ":
                    (class_reg[2:0]==1)?"APT       ":
                    (class_reg[2:0]==2)?"RECON     ":
                    (class_reg[2:0]==3)?"TRAF_SPIKE":
                    (class_reg[2:0]==4)?"NR_MALWARE":
                    (class_reg[2:0]==5)?"ZERO_DAY  ":"???       ",
                    status[1], ae_reg, status, timeout);
                if (!status[0]) $display("  *** TIMEOUT — done never asserted ***");
                if (bresp!=0)   $display("  *** AXI ERROR — bresp=%0b ***", bresp);
            end
        end
    endtask

    initial begin
        $dumpfile("prahari_lite.vcd");
        $dumpvars(1, tb_prahari_lite);   // depth=1 keeps VCD small

        // Init all driven signals to 0
        aresetn=0; awvalid=0; wvalid=0; bready=0;
        arvalid=0; rready=0; awaddr=0; wdata=0; araddr=0;

        // Simple delay-based reset — works reliably in all Icarus versions
        #103;          // hold reset for ~10 clock periods (10 x 10ns = 100ns) + 3ns offset
        aresetn=1;
        #55;           // settle for ~5 clock periods before AXI traffic

        $display("====================================================");
        $display("  PRAHARI-LITE RTL Sim — 6 test cases");
        $display("====================================================");

        // TEST 1: NORMAL — dst_port=80(20480), syn=0
        run_test("T1_NORMAL",
            16'd20480,16'd12800,16'd8192, 16'd65280,16'd2560,
            16'd0,    16'd0,   16'd51200,16'd1280, 16'd23040,
            16'd0,    16'd0,   16'd0,    16'd0,    16'd0);

        // TEST 2: RECON — dst_port=22(5632<=20480 left), syn=1(256>128 right)
        run_test("T2_RECON",
            16'd5632, 16'd10240,16'd0,    16'd2560, 16'd0,
            16'd5120, 16'd10240,16'd51200,16'd256,  16'd10240,
            16'd10240,16'd0,   16'd256,  16'd256,  16'd10240);

        // TEST 3: APT — dst_port>80(right), flow_iat_min=50(12800<=25600 left→APT)
        // 0x7FFF=32767 used for "high port" — positive signed > threshold 20480
        run_test("T3_APT",
            16'h7FFF, 16'd640,  16'd2560, 16'd2560, 16'd1024,
            16'd5120, 16'd8192, 16'd12800,16'd7680, 16'd2560,
            16'd7168, 16'd1024, 16'd768,  16'd256,  16'd7168);

        // TEST 4: TRAFFIC_SPIKE
        // Route: node0(right,port>20480)→node2(right,IAT>25600)→node6(left,bytes<=16640)→node13=TS
        // f0=32767(port high), f7=30000(IAT=117>100 threshold 25600→right), f1=5000(bytes<16640→left)
        run_test("T4_TRAF_SPIKE",
            16'h7FFF, 16'd5000, 16'd65280,16'd65280,16'd2560,
            16'd5632, 16'd5632, 16'd30000,16'd256,  16'd10240,
            16'd5120, 16'd2560, 16'd12800,16'd0,    16'd5120);

        // TEST 5: NR_MALWARE
        // Route: node0(right,port>20480)→node2(right,IAT>25600)→node6(right,bytes>16640)→node14=NRM
        // f0=32767(high port), f7=30000(IAT>25600), f1=20000(bytes>16640)
        run_test("T5_NR_MALWARE",
            16'h7FFF, 16'd20000,16'd4096, 16'd4096, 16'd1024,
            16'd1024, 16'd2048, 16'd30000,16'd2560, 16'd1024,
            16'd2048, 16'd1024, 16'd2048, 16'd256,  16'd2048);

        // TEST 6: ZERO_DAY
        // Route: node0(right,port>20480)→node2(left,IAT<=25600)→node5(right,dur>7680)→node12(purity=180)
        // f0=32767(port→right), f7=10000(IAT<25600→left), f8=10000(dur>7680→right→node12,p=180)
        // High feature values → large AE reconstruction error > 158206
        run_test("T6_ZERO_DAY",
            16'h7FFF, 16'h7FFF, 16'h7FFF, 16'h7FFF, 16'h7FFF,
            16'h7FFF, 16'h7FFF, 16'd10000,16'd10000,16'h7FFF,
            16'h7FFF, 16'h7FFF, 16'h7FFF, 16'd256,  16'h7FFF);

        $display("====================================================");
        $display("  Done. Check: T6 zero_day=1, all bresp=0");
        $display("====================================================");
        #50; $finish;
    end

    // Watchdog
    initial begin #500000; $display("[WATCHDOG] 500us limit hit"); $finish; end

endmodule
