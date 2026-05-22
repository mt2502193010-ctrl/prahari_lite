// PRAHARI-Lite: Decision Tree HLS Inference — interface header
// Include this in top-level HLS and testbench files.

#ifndef DT_INFERENCE_H
#define DT_INFERENCE_H

#ifdef __SYNTHESIS__
#include <ap_fixed.h>
#include <ap_int.h>
#include <hls_stream.h>
#else
#include "ap_types.h"
#endif

#include "dt_weights.h"   // DT_N_NODES, DT_MAX_DEPTH, DT_PURITY_THRESHOLD, ROM arrays

// Fixed-point types (must match dt_inference.cpp exactly)
typedef ap_fixed<16, 8>  dt_feature_t;
typedef ap_fixed<16, 8>  dt_threshold_t;
typedef ap_uint<3>        dt_label_t;    // 0-4: NORMAL/APT/RECON/TS/NRM
typedef ap_uint<16>       dt_purity_t;   // 0-65535 = 0.0-1.0
typedef ap_uint<11>       dt_node_id_t;  // up to 2047 nodes (depth-15: 1533 nodes)

// Structs
struct dt_input_t {
    dt_feature_t features[15];
    ap_uint<1>   valid;
};

struct dt_output_t {
    dt_label_t    predicted_label;
    dt_purity_t   leaf_purity;
    dt_node_id_t  leaf_id;
    ap_uint<1>    confident;   // purity >= DT_PURITY_THRESHOLD
    ap_uint<1>    valid;
};

struct tree_node_t {
    ap_uint<4>     feature_idx;
    dt_threshold_t threshold;
    dt_node_id_t   left_child;
    dt_node_id_t   right_child;
    dt_label_t     leaf_label;
    dt_purity_t    leaf_purity;
};

// Function declarations
void dt_inference(
    hls::stream<dt_input_t>  &input_stream,
    hls::stream<dt_output_t> &output_stream
);

void load_tree_from_memory(
    tree_node_t  *ext_tree,
    unsigned int  n_nodes
);

dt_purity_t float_to_purity(float p);

#endif // DT_INFERENCE_H
