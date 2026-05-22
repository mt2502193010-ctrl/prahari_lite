// PRAHARI-Lite: Fusion Logic HLS Core
// Target: Xilinx Pynq-Z2 (Zynq XC7Z020)
// Combines DT and AE outputs using leaf purity confidence gate
// Novel contribution: DT leaf purity as zero-day confidence gate
// Estimated resources: ~100 LUTs, 0 BRAM18, 0 DSPs, latency ~1 cycle

#ifdef __SYNTHESIS__
#include <ap_fixed.h>
#include <hls_stream.h>
#include <ap_int.h>
#else
#include "ap_types.h"
#endif

typedef ap_uint<3>  label_t;    // 0=NORMAL 1=APT 2=RECON 3=TS 4=NRM 5=ZERO_DAY
typedef ap_uint<16> purity_t;   // 0-65535 representing 0.0-1.0
typedef ap_uint<2>  routing_t;  // 0=DT_CONFIDENT 1=AE_FLAGGED 2=LOW_CONF_NORMAL
typedef ap_fixed<16,8> error_t;

#define LABEL_NORMAL    0
#define LABEL_APT       1
#define LABEL_RECON     2
#define LABEL_TS        3
#define LABEL_NRM       4
#define LABEL_ZERO_DAY  5

#define ROUTING_DT_CONF    0
#define ROUTING_AE_FLAGGED 1
#define ROUTING_LOW_CONF   2

// Fusion input (combined from DT and AE outputs)
struct fusion_input_t {
    // From DT
    label_t    dt_label;
    purity_t   dt_purity;
    ap_uint<1> dt_confident;  // purity >= threshold
    // From AE
    error_t    ae_error;
    ap_uint<1> ae_anomaly;    // error > threshold
    // Control
    ap_uint<1> valid;
};

struct fusion_output_t {
    label_t    final_label;   // 0-4 known, 5=ZERO_DAY
    routing_t  routing;       // 0=DT_CONF, 1=AE_FLAG, 2=LOW_CONF
    ap_uint<1> alert;         // 1 if any attack or zero-day
    purity_t   leaf_purity;   // passthrough for logging
    error_t    ae_error;      // passthrough for logging
    ap_uint<1> valid;
};

// Top-level fusion function
// Logic:
//   IF dt_confident → trust DT, use dt_label, routing=DT_CONFIDENT
//   ELSE IF ae_anomaly → ZERO_DAY detected, routing=AE_FLAGGED
//   ELSE → low confidence normal, use dt_label, routing=LOW_CONF_NORMAL
void fusion_logic(
    hls::stream<fusion_input_t>  &input_stream,
    hls::stream<fusion_output_t> &output_stream
) {
#pragma HLS INTERFACE axis port=input_stream
#pragma HLS INTERFACE axis port=output_stream
#pragma HLS PIPELINE II=1

    fusion_input_t  in_data;
    fusion_output_t out_data;

    if (input_stream.read_nb(in_data)) {
        if (in_data.valid) {
            out_data.leaf_purity = in_data.dt_purity;
            out_data.ae_error    = in_data.ae_error;

            if (in_data.dt_confident) {
                // Path 1: DT is confident → accept DT prediction
                out_data.final_label = in_data.dt_label;
                out_data.routing     = ROUTING_DT_CONF;
                out_data.alert       = (in_data.dt_label != LABEL_NORMAL) ? 1 : 0;
            } else if (in_data.ae_anomaly) {
                // Path 2: DT not confident, AE flags anomaly → ZERO_DAY
                out_data.final_label = LABEL_ZERO_DAY;
                out_data.routing     = ROUTING_AE_FLAGGED;
                out_data.alert       = 1;
            } else {
                // Path 3: Neither confident nor anomaly → low-conf, use DT anyway
                out_data.final_label = in_data.dt_label;
                out_data.routing     = ROUTING_LOW_CONF;
                out_data.alert       = (in_data.dt_label != LABEL_NORMAL) ? 1 : 0;
            }

            out_data.valid = 1;
            output_stream.write(out_data);
        }
    }
}
