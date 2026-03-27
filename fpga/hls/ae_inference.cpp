// PRAHARI-Lite: Autoencoder HLS Inference Core
// Target: Xilinx Pynq-Z2 (Zynq XC7Z020)
// Architecture: 15->8->4->8->15 with ReLU activations
// Estimated resources: ~500 LUTs, 1 BRAM18, 8 DSPs, latency ~38 cycles
// Weights stored as ap_fixed<8,4> for BRAM efficiency

#include <ap_fixed.h>
#include <hls_stream.h>
#include <ap_int.h>
#include <hls_math.h>

// Fixed-point types
typedef ap_fixed<16, 8>  feature_t;   // Input features (Q8.8)
typedef ap_fixed<8,  4>  weight_t;    // Weights (Q4.4 for BRAM density)
typedef ap_fixed<16, 8>  activation_t; // Hidden activations
typedef ap_fixed<16, 8>  error_t;     // Reconstruction error

// Layer dimensions
#define IN_DIM    15
#define ENC1_DIM   8
#define ENC2_DIM   4
#define DEC1_DIM   8
#define DEC2_DIM  15

// Input/output structs
struct ae_input_t {
    feature_t features[IN_DIM];
    ap_uint<1> valid;
};

struct ae_output_t {
    error_t    recon_error;  // MSE reconstruction error
    ap_uint<1> anomaly;      // 1 if error > threshold
    ap_uint<1> valid;
};

// Model weights stored in BRAM (loaded from PS at startup)
static weight_t enc1_w[ENC1_DIM][IN_DIM];
static weight_t enc1_b[ENC1_DIM];
static weight_t enc2_w[ENC2_DIM][ENC1_DIM];
static weight_t enc2_b[ENC2_DIM];
static weight_t dec1_w[DEC1_DIM][ENC2_DIM];
static weight_t dec1_b[DEC1_DIM];
static weight_t dec2_w[DEC2_DIM][DEC1_DIM];
static weight_t dec2_b[DEC2_DIM];

// Anomaly threshold (set from Python-computed 95th percentile)
static error_t AE_THRESHOLD = 0.05;

// ReLU activation
static activation_t relu(activation_t x) {
#pragma HLS INLINE
    return (x > 0) ? x : (activation_t)0;
}

// Dense layer: output = ReLU(W * input + b)
template<int OUT_DIM, int IN_DIM_T>
static void dense_relu(
    activation_t input[IN_DIM_T],
    weight_t     weights[OUT_DIM][IN_DIM_T],
    weight_t     bias[OUT_DIM],
    activation_t output[OUT_DIM]
) {
#pragma HLS INLINE
DENSE_OUT:
    for (int o = 0; o < OUT_DIM; o++) {
#pragma HLS PIPELINE II=1
        activation_t acc = (activation_t)bias[o];
    DENSE_IN:
        for (int i = 0; i < IN_DIM_T; i++) {
#pragma HLS UNROLL
            acc += weights[o][i] * input[i];
        }
        output[o] = relu(acc);
    }
}

// Dense layer without activation (final decoder layer)
template<int OUT_DIM, int IN_DIM_T>
static void dense_linear(
    activation_t input[IN_DIM_T],
    weight_t     weights[OUT_DIM][IN_DIM_T],
    weight_t     bias[OUT_DIM],
    activation_t output[OUT_DIM]
) {
#pragma HLS INLINE
DENSE_LINEAR_OUT:
    for (int o = 0; o < OUT_DIM; o++) {
#pragma HLS PIPELINE II=1
        activation_t acc = (activation_t)bias[o];
    DENSE_LINEAR_IN:
        for (int i = 0; i < IN_DIM_T; i++) {
#pragma HLS UNROLL
            acc += weights[o][i] * input[i];
        }
        output[o] = acc;
    }
}

// Top-level AE inference function
void ae_inference(
    hls::stream<ae_input_t>  &input_stream,
    hls::stream<ae_output_t> &output_stream
) {
#pragma HLS INTERFACE axis port=input_stream
#pragma HLS INTERFACE axis port=output_stream
#pragma HLS PIPELINE II=1
#pragma HLS ARRAY_PARTITION variable=enc1_w complete dim=2
#pragma HLS ARRAY_PARTITION variable=enc2_w complete dim=2
#pragma HLS ARRAY_PARTITION variable=dec1_w complete dim=2
#pragma HLS ARRAY_PARTITION variable=dec2_w complete dim=2

    ae_input_t  in_data;
    ae_output_t out_data;

    if (input_stream.read_nb(in_data)) {
        if (in_data.valid) {
            // Cast input features to activation type
            activation_t x[IN_DIM];
        CAST_INPUT:
            for (int i = 0; i < IN_DIM; i++) {
#pragma HLS UNROLL
                x[i] = (activation_t)in_data.features[i];
            }

            // Encoder
            activation_t enc1_out[ENC1_DIM];
            activation_t enc2_out[ENC2_DIM];
            dense_relu<ENC1_DIM, IN_DIM>(x, enc1_w, enc1_b, enc1_out);
            dense_relu<ENC2_DIM, ENC1_DIM>(enc1_out, enc2_w, enc2_b, enc2_out);

            // Decoder
            activation_t dec1_out[DEC1_DIM];
            activation_t dec2_out[DEC2_DIM];
            dense_relu<DEC1_DIM, ENC2_DIM>(enc2_out, dec1_w, dec1_b, dec1_out);
            dense_linear<DEC2_DIM, DEC1_DIM>(dec1_out, dec2_w, dec2_b, dec2_out);

            // MSE reconstruction error
            error_t mse = 0;
        COMPUTE_MSE:
            for (int i = 0; i < IN_DIM; i++) {
#pragma HLS UNROLL
                activation_t diff = x[i] - dec2_out[i];
                mse += diff * diff;
            }
            mse /= IN_DIM;

            out_data.recon_error = mse;
            out_data.anomaly     = (mse > AE_THRESHOLD) ? 1 : 0;
            out_data.valid       = 1;

            output_stream.write(out_data);
        }
    }
}

// Load weights from external memory (called once from PS at startup)
void ae_load_weights(
    weight_t *ext_enc1_w, weight_t *ext_enc1_b,
    weight_t *ext_enc2_w, weight_t *ext_enc2_b,
    weight_t *ext_dec1_w, weight_t *ext_dec1_b,
    weight_t *ext_dec2_w, weight_t *ext_dec2_b,
    float threshold
) {
    for (int o = 0; o < ENC1_DIM; o++)
        for (int i = 0; i < IN_DIM; i++)
            enc1_w[o][i] = ext_enc1_w[o * IN_DIM + i];
    for (int i = 0; i < ENC1_DIM; i++) enc1_b[i] = ext_enc1_b[i];

    for (int o = 0; o < ENC2_DIM; o++)
        for (int i = 0; i < ENC1_DIM; i++)
            enc2_w[o][i] = ext_enc2_w[o * ENC1_DIM + i];
    for (int i = 0; i < ENC2_DIM; i++) enc2_b[i] = ext_enc2_b[i];

    for (int o = 0; o < DEC1_DIM; o++)
        for (int i = 0; i < ENC2_DIM; i++)
            dec1_w[o][i] = ext_dec1_w[o * ENC2_DIM + i];
    for (int i = 0; i < DEC1_DIM; i++) dec1_b[i] = ext_dec1_b[i];

    for (int o = 0; o < DEC2_DIM; o++)
        for (int i = 0; i < DEC1_DIM; i++)
            dec2_w[o][i] = ext_dec2_w[o * DEC1_DIM + i];
    for (int i = 0; i < DEC2_DIM; i++) dec2_b[i] = ext_dec2_b[i];

    AE_THRESHOLD = (error_t)threshold;
}
