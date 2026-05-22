// PRAHARI-Lite: Fusion Logic HLS — interface header
// Include this in top-level HLS and testbench files.

#ifndef FUSION_LOGIC_H
#define FUSION_LOGIC_H

#ifdef __SYNTHESIS__
#include <ap_fixed.h>
#include <ap_int.h>
#include <hls_stream.h>
#else
#include "ap_types.h"
#endif

// Shared type aliases matching fusion_logic.cpp
typedef ap_uint<3>     fl_label_t;    // 0=NORMAL 1=APT 2=RECON 3=TS 4=NRM 5=ZERO_DAY
typedef ap_uint<16>    fl_purity_t;   // 0-65535
typedef ap_uint<2>     fl_routing_t;  // 0=DT_CONF 1=AE_FLAGGED 2=LOW_CONF
typedef ap_fixed<16,8> fl_error_t;

// Label constants
#define LABEL_NORMAL    0
#define LABEL_APT       1
#define LABEL_RECON     2
#define LABEL_TS        3
#define LABEL_NRM       4
#define LABEL_ZERO_DAY  5

// Routing constants
#define ROUTING_DT_CONF    0
#define ROUTING_AE_FLAGGED 1
#define ROUTING_LOW_CONF   2

struct fusion_input_t {
    fl_label_t   dt_label;
    fl_purity_t  dt_purity;
    ap_uint<1>   dt_confident;
    fl_error_t   ae_error;
    ap_uint<1>   ae_anomaly;
    ap_uint<1>   valid;
};

struct fusion_output_t {
    fl_label_t   final_label;
    fl_routing_t routing;
    ap_uint<1>   alert;
    fl_purity_t  leaf_purity;
    fl_error_t   ae_error;
    ap_uint<1>   valid;
};

// Function declaration
void fusion_logic(
    hls::stream<fusion_input_t>  &input_stream,
    hls::stream<fusion_output_t> &output_stream
);

#endif // FUSION_LOGIC_H
