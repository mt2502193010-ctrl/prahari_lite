// PRAHARI-Lite: Autoencoder HLS Inference — interface header
// Include this in top-level HLS and testbench files.

#ifndef AE_INFERENCE_H
#define AE_INFERENCE_H

#ifdef __SYNTHESIS__
#include <ap_fixed.h>
#include <ap_int.h>
#include <hls_stream.h>
#else
#include "ap_types.h"
#endif

#include "ae_weights.h"   // AE_THRESHOLD_FP, weight arrays, layer dims

// Fixed-point types (must match ae_inference.cpp exactly)
typedef ap_fixed<16, 8>  ae_feature_t;
typedef ap_fixed<8,  4>  ae_weight_t;    // Q4.4 — scale=16
typedef ap_fixed<16, 8>  ae_activation_t;
typedef ap_fixed<16, 8>  ae_error_t;

// Structs
struct ae_input_t {
    ae_feature_t features[AE_IN_DIM];
    ap_uint<1>   valid;
};

struct ae_output_t {
    ae_error_t recon_error;
    ap_uint<1> anomaly;   // 1 if recon_error > AE_THRESHOLD_FP / AE_T_SCALE
    ap_uint<1> valid;
};

// Function declarations
void ae_inference(
    hls::stream<ae_input_t>  &input_stream,
    hls::stream<ae_output_t> &output_stream
);

void ae_load_weights(
    ae_weight_t *ext_enc1_w, ae_weight_t *ext_enc1_b,
    ae_weight_t *ext_enc2_w, ae_weight_t *ext_enc2_b,
    ae_weight_t *ext_dec1_w, ae_weight_t *ext_dec1_b,
    ae_weight_t *ext_dec2_w, ae_weight_t *ext_dec2_b,
    float        threshold
);

#endif // AE_INFERENCE_H
