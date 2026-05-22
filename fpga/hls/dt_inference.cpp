// PRAHARI-Lite: Decision Tree HLS Inference Core
// Target: Xilinx Pynq-Z2 (Zynq XC7Z020)
// Architecture: Fixed-point DT traversal with leaf purity output
// Estimated resources: ~800 LUTs, 2 BRAM18, 0 DSPs, latency ~12 cycles

#ifdef __SYNTHESIS__
#include <ap_fixed.h>
#include <hls_stream.h>
#include <ap_int.h>
#else
#include "ap_types.h"
#endif

// Fixed-point types for FPGA efficiency
typedef ap_fixed<16, 8>  feature_t;   // Q8.8 fixed-point for features
typedef ap_fixed<16, 8>  threshold_t; // Q8.8 for tree thresholds
typedef ap_uint<3>        label_t;     // 0-4: NORMAL/APT/RECON/TS/NRM
typedef ap_uint<16>       purity_t;    // 0-65535 representing 0.0-1.0
typedef ap_uint<11>       node_id_t;   // Up to 2047 nodes (depth-15 model has 1533)

// Input/output structs
struct dt_input_t {
    feature_t features[15];  // 15 FPGA features
    ap_uint<1> valid;
};

struct dt_output_t {
    label_t    predicted_label;
    purity_t   leaf_purity;    // Fixed-point 0-65535 = 0.0-1.0
    node_id_t  leaf_id;
    ap_uint<1> confident;      // purity >= threshold
    ap_uint<1> valid;
};

// Feature indices matching PRAHARI-Lite 15-feature set
// [0]=dst_port [1]=fwd_bytes [2]=init_win_bwd [3]=init_win_fwd [4]=bwd_bytes
// [5]=fwd_seg_min [6]=fwd_pkt_mean [7]=flow_iat_min [8]=duration [9]=flow_byts_s
// [10]=avg_pkt_size [11]=bwd_pkt_max [12]=bwd_pkts [13]=syn_flag [14]=pkt_len_mean

// Tree node structure (flattened for BRAM storage)
struct tree_node_t {
    ap_uint<4>   feature_idx;    // which feature to split on (0-14, 15=leaf)
    threshold_t  threshold;       // split threshold
    node_id_t    left_child;      // left child node id
    node_id_t    right_child;     // right child node id
    label_t      leaf_label;      // prediction if leaf
    purity_t     leaf_purity;     // purity if leaf (0-65535)
};

// Depth-15 model has 1533 nodes; +1 guard for safety
#define MAX_NODES 1534
#define DT_CONFIDENCE_THRESHOLD 63034  // 0.9618 * 65535 (calibrated from training)

// Tree stored in BRAM
static tree_node_t tree_nodes[MAX_NODES];

// Confidence gate threshold (stored in register)
static const purity_t CONFIDENCE_THRESHOLD = DT_CONFIDENCE_THRESHOLD;

// Top-level DT inference function
void dt_inference(
    hls::stream<dt_input_t>  &input_stream,
    hls::stream<dt_output_t> &output_stream
) {
#pragma HLS INTERFACE axis port=input_stream
#pragma HLS INTERFACE axis port=output_stream
#pragma HLS PIPELINE II=1
#pragma HLS ARRAY_PARTITION variable=tree_nodes cyclic factor=4 dim=1

    dt_input_t  in_data;
    dt_output_t out_data;

    if (input_stream.read_nb(in_data)) {
        if (in_data.valid) {
            // Traverse tree from root
            node_id_t current_node = 0;
            bool found_leaf = false;

        TRAVERSE_LOOP:
            for (int depth = 0; depth < 16; depth++) {
#pragma HLS UNROLL factor=1
                tree_node_t node = tree_nodes[current_node];

                if (node.feature_idx == 15) {
                    // Leaf node
                    out_data.predicted_label = node.leaf_label;
                    out_data.leaf_purity     = node.leaf_purity;
                    out_data.leaf_id         = current_node;
                    out_data.confident       = (node.leaf_purity >= CONFIDENCE_THRESHOLD) ? 1 : 0;
                    found_leaf = true;
                    break;
                } else {
                    // Internal node: compare feature vs threshold
                    feature_t feat_val = in_data.features[node.feature_idx];
                    if (feat_val <= node.threshold) {
                        current_node = node.left_child;
                    } else {
                        current_node = node.right_child;
                    }
                }
            }

            if (!found_leaf) {
                // Safety: return root prediction if traversal fails
                out_data.predicted_label = tree_nodes[0].leaf_label;
                out_data.leaf_purity     = 0;
                out_data.leaf_id         = 0;
                out_data.confident       = 0;
            }

            out_data.valid = 1;
            output_stream.write(out_data);
        }
    }
}

// Utility: convert float purity (0.0-1.0) to fixed-point (0-65535)
purity_t float_to_purity(float p) {
    return (purity_t)(unsigned int)(p * 65535.0f);
}

// Utility: load tree from external memory (called once at startup)
void load_tree_from_memory(
    tree_node_t *ext_tree,
    unsigned int n_nodes
) {
    for (unsigned int i = 0; i < n_nodes && i < MAX_NODES; i++) {
        tree_nodes[i] = ext_tree[i];
    }
}
