// PRAHARI-Lite: Top-Level HLS Wrapper
// Instantiates dt_inference + ae_inference + fusion_logic in a pipeline
// Target: Xilinx Pynq-Z2 (Zynq XC7Z020)
// Total estimated resources: ~1700 LUTs, 3 BRAM18, 12 DSPs, 54 cycle latency

#include <ap_fixed.h>
#include <hls_stream.h>
#include <ap_int.h>

// Type definitions (replicated from individual cores to avoid separate headers)
typedef ap_fixed<16, 8>  feature_t;
typedef ap_fixed<16, 8>  error_t;
typedef ap_uint<3>        label_t;
typedef ap_uint<16>       purity_t;
typedef ap_uint<2>        routing_t;
typedef ap_uint<10>       node_id_t;

// ── Structs (must match definitions in individual .cpp files) ─────────────────

struct dt_input_t {
    feature_t  features[15];
    ap_uint<1> valid;
};

struct dt_output_t {
    label_t    predicted_label;
    purity_t   leaf_purity;
    node_id_t  leaf_id;
    ap_uint<1> confident;
    ap_uint<1> valid;
};

struct ae_input_t {
    feature_t  features[15];
    ap_uint<1> valid;
};

struct ae_output_t {
    error_t    recon_error;
    ap_uint<1> anomaly;
    ap_uint<1> valid;
};

struct fusion_input_t {
    label_t    dt_label;
    purity_t   dt_purity;
    ap_uint<1> dt_confident;
    error_t    ae_error;
    ap_uint<1> ae_anomaly;
    ap_uint<1> valid;
};

struct fusion_output_t {
    label_t    final_label;
    routing_t  routing;
    ap_uint<1> alert;
    purity_t   leaf_purity;
    error_t    ae_error;
    ap_uint<1> valid;
};

// Common feature struct for top-level interface
struct flow_features_t {
    feature_t  features[15];
};

struct detection_result_t {
    label_t    final_label;   // 0-4 known, 5=ZERO_DAY
    routing_t  routing;       // 0=DT_CONF, 1=AE_FLAG, 2=LOW_CONF
    ap_uint<1> alert;
    purity_t   leaf_purity;
    error_t    ae_error;
};

// Forward declarations (defined in separate compilation units)
void dt_inference(hls::stream<dt_input_t>&, hls::stream<dt_output_t>&);
void ae_inference(hls::stream<ae_input_t>&, hls::stream<ae_output_t>&);
void fusion_logic(hls::stream<fusion_input_t>&, hls::stream<fusion_output_t>&);

// ── Top-level function ─────────────────────────────────────────────────────────
void prahari_lite_top(
    hls::stream<flow_features_t>    &features_in,
    hls::stream<detection_result_t> &result_out
) {
#pragma HLS INTERFACE axis port=features_in
#pragma HLS INTERFACE axis port=result_out
#pragma HLS DATAFLOW

    // Internal streams connecting the pipeline stages
    hls::stream<dt_input_t>     dt_in_stream("dt_in");
    hls::stream<dt_output_t>    dt_out_stream("dt_out");
    hls::stream<ae_input_t>     ae_in_stream("ae_in");
    hls::stream<ae_output_t>    ae_out_stream("ae_out");
    hls::stream<fusion_input_t> fusion_in_stream("fusion_in");
    hls::stream<fusion_output_t> fusion_out_stream("fusion_out");

#pragma HLS STREAM variable=dt_in_stream   depth=2
#pragma HLS STREAM variable=dt_out_stream  depth=2
#pragma HLS STREAM variable=ae_in_stream   depth=2
#pragma HLS STREAM variable=ae_out_stream  depth=2
#pragma HLS STREAM variable=fusion_in_stream depth=2
#pragma HLS STREAM variable=fusion_out_stream depth=2

    // ── Stage 0: Fanout input to DT and AE ────────────────────────────────────
    flow_features_t in_feat;
    if (features_in.read_nb(in_feat)) {
        dt_input_t dt_in;
        ae_input_t ae_in;

        for (int i = 0; i < 15; i++) {
#pragma HLS UNROLL
            dt_in.features[i] = in_feat.features[i];
            ae_in.features[i] = in_feat.features[i];
        }
        dt_in.valid = 1;
        ae_in.valid = 1;

        dt_in_stream.write(dt_in);
        ae_in_stream.write(ae_in);
    }

    // ── Stage 1+2: DT and AE run in parallel (DATAFLOW) ──────────────────────
    dt_inference(dt_in_stream, dt_out_stream);
    ae_inference(ae_in_stream, ae_out_stream);

    // ── Stage 3: Merge DT + AE outputs into fusion input ─────────────────────
    dt_output_t dt_out;
    ae_output_t ae_out;

    if (dt_out_stream.read_nb(dt_out) && ae_out_stream.read_nb(ae_out)) {
        fusion_input_t fuse_in;
        fuse_in.dt_label    = dt_out.predicted_label;
        fuse_in.dt_purity   = dt_out.leaf_purity;
        fuse_in.dt_confident = dt_out.confident;
        fuse_in.ae_error    = ae_out.recon_error;
        fuse_in.ae_anomaly  = ae_out.anomaly;
        fuse_in.valid       = 1;
        fusion_in_stream.write(fuse_in);
    }

    // ── Stage 4: Fusion decision ──────────────────────────────────────────────
    fusion_logic(fusion_in_stream, fusion_out_stream);

    // ── Stage 5: Output ───────────────────────────────────────────────────────
    fusion_output_t fuse_out;
    if (fusion_out_stream.read_nb(fuse_out)) {
        detection_result_t result;
        result.final_label = fuse_out.final_label;
        result.routing     = fuse_out.routing;
        result.alert       = fuse_out.alert;
        result.leaf_purity = fuse_out.leaf_purity;
        result.ae_error    = fuse_out.ae_error;
        result_out.write(result);
    }
}
