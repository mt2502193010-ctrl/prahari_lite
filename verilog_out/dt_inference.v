`timescale 1ns/1ps
// PRAHARI-Lite — Decision Tree Inference Engine
// Nodes: 767  Max depth: 15  Classes: 5
// ROM format [53:0]:
//   [53:46]=purity(8) [45:43]=class(3) [42]=is_leaf [41:31]=right(11)
//   [30:20]=left(11) [19:4]=threshold(16,signed Q8.8) [3:0]=feature_index(4)
module dt_inference (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire signed [15:0] feat0,  feat1,  feat2,  feat3,  feat4,
    input  wire signed [15:0] feat5,  feat6,  feat7,  feat8,  feat9,
    input  wire signed [15:0] feat10, feat11, feat12, feat13, feat14,
    output reg  [2:0]  class_out,
    output reg  [7:0]  purity_out,
    output reg         done
);

// ── ROM ──────────────────────────────────────────────────────
(* rom_style = "block" *) reg [53:0] rom [0:766];
initial begin
        rom[   0] = 54'h0CC8D1001FF9F0;  // feat= 0 thr= -0.3789 L=   1 R= 418 cls=1 pur=0.200 leaf=0
        rom[   1] = 54'h191821802FF9F0;  // feat= 0 thr= -0.3789 L=   2 R=  67 cls=3 pur=0.390 leaf=0
        rom[   2] = 54'h3D880A00300015;  // feat= 5 thr=  0.0039 L=   3 R=  20 cls=1 pur=0.963 leaf=0
        rom[   3] = 54'h2C5008804FF9CE;  // feat=14 thr= -0.3906 L=   4 R=  17 cls=2 pur=0.689 leaf=0
        rom[   4] = 54'h385007005FF9BE;  // feat=14 thr= -0.3945 L=   5 R=  14 cls=2 pur=0.880 leaf=0
        rom[   5] = 54'h3AC004806FFFCC;  // feat=12 thr= -0.0156 L=   6 R=   9 cls=0 pur=0.917 leaf=0
        rom[   6] = 54'h3F4004007FFE07;  // feat= 7 thr= -0.1250 L=   7 R=   8 cls=0 pur=0.989 leaf=0
        rom[   7] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[   8] = 54'h2904000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=0.640 leaf=1
        rom[   9] = 54'h23400680AFF9E0;  // feat= 0 thr= -0.3828 L=  10 R=  13 cls=0 pur=0.552 leaf=0
        rom[  10] = 54'h33400600BFFAE8;  // feat= 8 thr= -0.3203 L=  11 R=  12 cls=0 pur=0.800 leaf=0
        rom[  11] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[  12] = 54'h2694000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.600 leaf=1
        rom[  13] = 54'h314C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.769 leaf=1
        rom[  14] = 54'h3FD00800FFF9E0;  // feat= 0 thr= -0.3828 L=  15 R=  16 cls=2 pur=1.000 leaf=0
        rom[  15] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[  16] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[  17] = 54'h3FC009812FF9E0;  // feat= 0 thr= -0.3828 L=  18 R=  19 cls=0 pur=1.000 leaf=0
        rom[  18] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[  19] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[  20] = 54'h3EC81E01500015;  // feat= 5 thr=  0.0039 L=  21 R=  60 cls=1 pur=0.982 leaf=0
        rom[  21] = 54'h3F881D81600ED2;  // feat= 2 thr=  0.9258 L=  22 R=  59 cls=1 pur=0.994 leaf=0
        rom[  22] = 54'h3FC81C017FFFF4;  // feat= 4 thr= -0.0039 L=  23 R=  56 cls=1 pur=0.995 leaf=0
        rom[  23] = 54'h3FC819818FFE07;  // feat= 7 thr= -0.1250 L=  24 R=  51 cls=1 pur=0.997 leaf=0
        rom[  24] = 54'h3FC819019FFB88;  // feat= 8 thr= -0.2812 L=  25 R=  50 cls=1 pur=0.998 leaf=0
        rom[  25] = 54'h3FC81381AFF933;  // feat= 3 thr= -0.4258 L=  26 R=  39 cls=1 pur=0.996 leaf=0
        rom[  26] = 54'h3FC81101BFFFCC;  // feat=12 thr= -0.0156 L=  27 R=  34 cls=1 pur=0.999 leaf=0
        rom[  27] = 54'h3FC81081CFFFCC;  // feat=12 thr= -0.0156 L=  28 R=  33 cls=1 pur=1.000 leaf=0
        rom[  28] = 54'h3FC81001D02D8D;  // feat=13 thr=  2.8438 L=  29 R=  32 cls=1 pur=0.999 leaf=0
        rom[  29] = 54'h2F800F81EFFE07;  // feat= 7 thr= -0.1250 L=  30 R=  31 cls=0 pur=0.740 leaf=0
        rom[  30] = 54'h2B44000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=0.677 leaf=1
        rom[  31] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[  32] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[  33] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[  34] = 54'h380813023FFBF2;  // feat= 2 thr= -0.2539 L=  35 R=  38 cls=1 pur=0.875 leaf=0
        rom[  35] = 54'h3FC812824FFF81;  // feat= 1 thr= -0.0312 L=  36 R=  37 cls=1 pur=1.000 leaf=0
        rom[  36] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[  37] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[  38] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[  39] = 54'h1D4816828FFB0B;  // feat=11 thr= -0.3125 L=  40 R=  45 cls=1 pur=0.456 leaf=0
        rom[  40] = 54'h31C816029FFAE8;  // feat= 8 thr= -0.3203 L=  41 R=  44 cls=1 pur=0.777 leaf=0
        rom[  41] = 54'h3FC01582AFF9E0;  // feat= 0 thr= -0.3828 L=  42 R=  43 cls=0 pur=1.000 leaf=0
        rom[  42] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[  43] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[  44] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[  45] = 54'h2DC01782EFFF81;  // feat= 1 thr= -0.0312 L=  46 R=  47 cls=0 pur=0.713 leaf=0
        rom[  46] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[  47] = 54'h3FC0188300003C;  // feat=12 thr=  0.0117 L=  48 R=  49 cls=0 pur=1.000 leaf=0
        rom[  48] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[  49] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[  50] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[  51] = 54'h2C081A834FF943;  // feat= 3 thr= -0.4219 L=  52 R=  53 cls=1 pur=0.688 leaf=0
        rom[  52] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[  53] = 54'h34C01B836FFFCC;  // feat=12 thr= -0.0156 L=  54 R=  55 cls=0 pur=0.826 leaf=0
        rom[  54] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[  55] = 54'h264C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.597 leaf=1
        rom[  56] = 54'h3D401D039FFF69;  // feat= 9 thr= -0.0391 L=  57 R=  58 cls=0 pur=0.957 leaf=0
        rom[  57] = 54'h280C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.625 leaf=1
        rom[  58] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[  59] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[  60] = 54'h3ED02003DFFF69;  // feat= 9 thr= -0.0391 L=  61 R=  64 cls=2 pur=0.980 leaf=0
        rom[  61] = 54'h2A481F83EFF963;  // feat= 3 thr= -0.4141 L=  62 R=  63 cls=1 pur=0.661 leaf=0
        rom[  62] = 54'h3A4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.909 leaf=1
        rom[  63] = 54'h2E84000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=0.727 leaf=1
        rom[  64] = 54'h3FD021041FFE07;  // feat= 7 thr= -0.1250 L=  65 R=  66 cls=2 pur=0.997 leaf=0
        rom[  65] = 54'h2C54000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.692 leaf=1
        rom[  66] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[  67] = 54'h269822844FF8F3;  // feat= 3 thr= -0.4414 L=  68 R=  69 cls=3 pur=0.600 leaf=0
        rom[  68] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[  69] = 54'h33988A846FFC12;  // feat= 2 thr= -0.2461 L=  70 R= 277 cls=3 pur=0.804 leaf=0
        rom[  70] = 54'h3C586D047FFC12;  // feat= 2 thr= -0.2461 L=  71 R= 218 cls=3 pur=0.943 leaf=0
        rom[  71] = 54'h36D85B848FF75A;  // feat=10 thr= -0.5430 L=  72 R= 183 cls=3 pur=0.856 leaf=0
        rom[  72] = 54'h3C9856049FFBC2;  // feat= 2 thr= -0.2656 L=  73 R= 172 cls=3 pur=0.943 leaf=0
        rom[  73] = 54'h3E182D84AFFE07;  // feat= 7 thr= -0.1250 L=  74 R=  91 cls=3 pur=0.968 leaf=0
        rom[  74] = 54'h3FD82C04BFF983;  // feat= 3 thr= -0.4062 L=  75 R=  88 cls=3 pur=0.998 leaf=0
        rom[  75] = 54'h3FD82984C00015;  // feat= 5 thr=  0.0039 L=  76 R=  83 cls=3 pur=0.999 leaf=0
        rom[  76] = 54'h3FD82704DFF6DA;  // feat=10 thr= -0.5742 L=  77 R=  78 cls=3 pur=0.999 leaf=0
        rom[  77] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[  78] = 54'h3FD82804FFF75A;  // feat=10 thr= -0.5430 L=  79 R=  80 cls=3 pur=1.000 leaf=0
        rom[  79] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[  80] = 54'h3A5829051FFAE8;  // feat= 8 thr= -0.3203 L=  81 R=  82 cls=3 pur=0.908 leaf=0
        rom[  81] = 54'h385C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.878 leaf=1
        rom[  82] = 54'h3B5C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.926 leaf=1
        rom[  83] = 54'h3FD82A854FFAE8;  // feat= 8 thr= -0.3203 L=  84 R=  85 cls=3 pur=1.000 leaf=0
        rom[  84] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[  85] = 54'h3F182B856FFAE8;  // feat= 8 thr= -0.3203 L=  86 R=  87 cls=3 pur=0.984 leaf=0
        rom[  86] = 54'h30DC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.762 leaf=1
        rom[  87] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[  88] = 54'h38C02D05900243;  // feat= 3 thr=  0.1406 L=  89 R=  90 cls=0 pur=0.888 leaf=0
        rom[  89] = 54'h21CC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.526 leaf=1
        rom[  90] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[  91] = 54'h39D84A85CFFB78;  // feat= 8 thr= -0.2852 L=  92 R= 149 cls=3 pur=0.903 leaf=0
        rom[  92] = 54'h34584305DFFE07;  // feat= 7 thr= -0.1250 L=  93 R= 134 cls=3 pur=0.815 leaf=0
        rom[  93] = 54'h38583B85EFF943;  // feat= 3 thr= -0.4219 L=  94 R= 119 cls=3 pur=0.878 leaf=0
        rom[  94] = 54'h3B183405FFFAE8;  // feat= 8 thr= -0.3203 L=  95 R= 104 cls=3 pur=0.920 leaf=0
        rom[  95] = 54'h34983086000015;  // feat= 5 thr=  0.0039 L=  96 R=  97 cls=3 pur=0.821 leaf=0
        rom[  96] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[  97] = 54'h3A5832862FF933;  // feat= 3 thr= -0.4258 L=  98 R= 101 cls=3 pur=0.912 leaf=0
        rom[  98] = 54'h3F0032063FF933;  // feat= 3 thr= -0.4258 L=  99 R= 100 cls=0 pur=0.985 leaf=0
        rom[  99] = 54'h2F04000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=0.735 leaf=1
        rom[ 100] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 101] = 54'h3DD833866FF933;  // feat= 3 thr= -0.4258 L= 102 R= 103 cls=3 pur=0.965 leaf=0
        rom[ 102] = 54'h3F5C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.989 leaf=1
        rom[ 103] = 54'h3ADC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.917 leaf=1
        rom[ 104] = 54'h3F1838069FFE07;  // feat= 7 thr= -0.1250 L= 105 R= 112 cls=3 pur=0.986 leaf=0
        rom[ 105] = 54'h3C983686AFF933;  // feat= 3 thr= -0.4258 L= 106 R= 109 cls=3 pur=0.945 leaf=0
        rom[ 106] = 54'h39983606BFFAE8;  // feat= 8 thr= -0.3203 L= 107 R= 108 cls=3 pur=0.898 leaf=0
        rom[ 107] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 108] = 54'h35DC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.839 leaf=1
        rom[ 109] = 54'h3FD83786EFFE07;  // feat= 7 thr= -0.1250 L= 110 R= 111 cls=3 pur=0.997 leaf=0
        rom[ 110] = 54'h3A9C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.915 leaf=1
        rom[ 111] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 112] = 54'h3FD83A071FF933;  // feat= 3 thr= -0.4258 L= 113 R= 116 cls=3 pur=0.997 leaf=0
        rom[ 113] = 54'h231839872FFAE8;  // feat= 8 thr= -0.3203 L= 114 R= 115 cls=3 pur=0.545 leaf=0
        rom[ 114] = 54'h2C44000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=0.690 leaf=1
        rom[ 115] = 54'h2EDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.730 leaf=1
        rom[ 116] = 54'h3FD83B075FFE07;  // feat= 7 thr= -0.1250 L= 117 R= 118 cls=3 pur=0.999 leaf=0
        rom[ 117] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.999 leaf=1
        rom[ 118] = 54'h399C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.900 leaf=1
        rom[ 119] = 54'h1FC83E878FFA83;  // feat= 3 thr= -0.3438 L= 120 R= 125 cls=1 pur=0.495 leaf=0
        rom[ 120] = 54'h3D883D079FFA63;  // feat= 3 thr= -0.3516 L= 121 R= 122 cls=1 pur=0.961 leaf=0
        rom[ 121] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 122] = 54'h3FC83E07BFFAE8;  // feat= 8 thr= -0.3203 L= 123 R= 124 cls=1 pur=1.000 leaf=0
        rom[ 123] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 124] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 125] = 54'h2F004187EFFE07;  // feat= 7 thr= -0.1250 L= 126 R= 131 cls=0 pur=0.735 leaf=0
        rom[ 126] = 54'h3E004007FFFE07;  // feat= 7 thr= -0.1250 L= 127 R= 128 cls=0 pur=0.971 leaf=0
        rom[ 127] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 128] = 54'h35404108101953;  // feat= 3 thr=  1.5820 L= 129 R= 130 cls=0 pur=0.833 leaf=0
        rom[ 129] = 54'h2DC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=0.714 leaf=1
        rom[ 130] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 131] = 54'h38184288401893;  // feat= 3 thr=  1.5352 L= 132 R= 133 cls=3 pur=0.873 leaf=0
        rom[ 132] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 133] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 134] = 54'h350045087FF933;  // feat= 3 thr= -0.4258 L= 135 R= 138 cls=0 pur=0.829 leaf=0
        rom[ 135] = 54'h3F5844888FFAE8;  // feat= 8 thr= -0.3203 L= 136 R= 137 cls=3 pur=0.990 leaf=0
        rom[ 136] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 137] = 54'h385C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.878 leaf=1
        rom[ 138] = 54'h3E404908BFFB48;  // feat= 8 thr= -0.2969 L= 139 R= 146 cls=0 pur=0.974 leaf=0
        rom[ 139] = 54'h3F004688CFFAE8;  // feat= 8 thr= -0.3203 L= 140 R= 141 cls=0 pur=0.986 leaf=0
        rom[ 140] = 54'h2804000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=0.625 leaf=1
        rom[ 141] = 54'h3F804788EFF933;  // feat= 3 thr= -0.4258 L= 142 R= 143 cls=0 pur=0.993 leaf=0
        rom[ 142] = 54'h3144000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=0.769 leaf=1
        rom[ 143] = 54'h3FC048890FFAE8;  // feat= 8 thr= -0.3203 L= 144 R= 145 cls=0 pur=0.996 leaf=0
        rom[ 144] = 54'h3D04000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=0.952 leaf=1
        rom[ 145] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 146] = 54'h2C404A093FFB58;  // feat= 8 thr= -0.2930 L= 147 R= 148 cls=0 pur=0.690 leaf=0
        rom[ 147] = 54'h321C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.783 leaf=1
        rom[ 148] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 149] = 54'h3F585589601A23;  // feat= 3 thr=  1.6328 L= 150 R= 171 cls=3 pur=0.989 leaf=0
        rom[ 150] = 54'h3FD84D097FFE47;  // feat= 7 thr= -0.1094 L= 151 R= 154 cls=3 pur=0.997 leaf=0
        rom[ 151] = 54'h3FD84C898FF75A;  // feat=10 thr= -0.5430 L= 152 R= 153 cls=3 pur=1.000 leaf=0
        rom[ 152] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 153] = 54'h3B5C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.926 leaf=1
        rom[ 154] = 54'h3F984F09B00015;  // feat= 5 thr=  0.0039 L= 155 R= 158 cls=3 pur=0.991 leaf=0
        rom[ 155] = 54'h38404E89CFFA03;  // feat= 3 thr= -0.3750 L= 156 R= 157 cls=0 pur=0.878 leaf=0
        rom[ 156] = 54'h2C44000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=0.690 leaf=1
        rom[ 157] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 158] = 54'h3FD85309FFFCB8;  // feat= 8 thr= -0.2070 L= 159 R= 166 cls=3 pur=0.996 leaf=0
        rom[ 159] = 54'h3A98518A000017;  // feat= 7 thr=  0.0039 L= 160 R= 163 cls=3 pur=0.915 leaf=0
        rom[ 160] = 54'h3FD8510A1FFFF7;  // feat= 7 thr= -0.0039 L= 161 R= 162 cls=3 pur=1.000 leaf=0
        rom[ 161] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 162] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 163] = 54'h33D8528A4FFC18;  // feat= 8 thr= -0.2461 L= 164 R= 165 cls=3 pur=0.808 leaf=0
        rom[ 164] = 54'h2EDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.730 leaf=1
        rom[ 165] = 54'h385C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.878 leaf=1
        rom[ 166] = 54'h3FD8550A700497;  // feat= 7 thr=  0.2852 L= 167 R= 170 cls=3 pur=0.997 leaf=0
        rom[ 167] = 54'h3FD8548A8FFFC7;  // feat= 7 thr= -0.0156 L= 168 R= 169 cls=3 pur=0.996 leaf=0
        rom[ 168] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.998 leaf=1
        rom[ 169] = 54'h321C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.783 leaf=1
        rom[ 170] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 171] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 172] = 54'h28805A0ADFF9F0;  // feat= 0 thr= -0.3789 L= 173 R= 180 cls=0 pur=0.634 leaf=0
        rom[ 173] = 54'h3ED0598AEFFF81;  // feat= 1 thr= -0.0312 L= 174 R= 179 cls=2 pur=0.982 leaf=0
        rom[ 174] = 54'h3FD0580AFFFE07;  // feat= 7 thr= -0.1250 L= 175 R= 176 cls=2 pur=0.998 leaf=0
        rom[ 175] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 176] = 54'h3F90590B1FFF89;  // feat= 9 thr= -0.0312 L= 177 R= 178 cls=2 pur=0.994 leaf=0
        rom[ 177] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 178] = 54'h3AD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.918 leaf=1
        rom[ 179] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 180] = 54'h3FC05B0B5FFE07;  // feat= 7 thr= -0.1250 L= 181 R= 182 cls=0 pur=1.000 leaf=0
        rom[ 181] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 182] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 183] = 54'h3440678B800646;  // feat= 6 thr=  0.3906 L= 184 R= 207 cls=0 pur=0.816 leaf=0
        rom[ 184] = 54'h3E40660B9FFC12;  // feat= 2 thr= -0.2461 L= 185 R= 204 cls=0 pur=0.971 leaf=0
        rom[ 185] = 54'h3F40608BAFF933;  // feat= 3 thr= -0.4258 L= 186 R= 193 cls=0 pur=0.988 leaf=0
        rom[ 186] = 54'h2B585E0BBFFE07;  // feat= 7 thr= -0.1250 L= 187 R= 188 cls=3 pur=0.675 leaf=0
        rom[ 187] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 188] = 54'h37D85F0BDFFF69;  // feat= 9 thr= -0.0391 L= 189 R= 190 cls=3 pur=0.871 leaf=0
        rom[ 189] = 54'h231C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.545 leaf=1
        rom[ 190] = 54'h3D98600BFFFAE8;  // feat= 8 thr= -0.3203 L= 191 R= 192 cls=3 pur=0.959 leaf=0
        rom[ 191] = 54'h385C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.878 leaf=1
        rom[ 192] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 193] = 54'h3F80628C200317;  // feat= 7 thr=  0.1914 L= 194 R= 197 cls=0 pur=0.994 leaf=0
        rom[ 194] = 54'h3FC0620C3FFF69;  // feat= 9 thr= -0.0391 L= 195 R= 196 cls=0 pur=0.997 leaf=0
        rom[ 195] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 196] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 197] = 54'h2F00658C6FF9A3;  // feat= 3 thr= -0.3984 L= 198 R= 203 cls=0 pur=0.735 leaf=0
        rom[ 198] = 54'h2258650C700E67;  // feat= 7 thr=  0.8984 L= 199 R= 202 cls=3 pur=0.534 leaf=0
        rom[ 199] = 54'h2440648C800947;  // feat= 7 thr=  0.5781 L= 200 R= 201 cls=0 pur=0.565 leaf=0
        rom[ 200] = 54'h231C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.545 leaf=1
        rom[ 201] = 54'h2C44000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=0.690 leaf=1
        rom[ 202] = 54'h295C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.643 leaf=1
        rom[ 203] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 204] = 54'h3F50670CDFFE88;  // feat= 8 thr= -0.0938 L= 205 R= 206 cls=2 pur=0.987 leaf=0
        rom[ 205] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 206] = 54'h3994000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.900 leaf=1
        rom[ 207] = 54'h26D86C8D0FFBC2;  // feat= 2 thr= -0.2656 L= 208 R= 217 cls=3 pur=0.606 leaf=0
        rom[ 208] = 54'h3FD86B0D101FA6;  // feat= 6 thr=  1.9766 L= 209 R= 214 cls=3 pur=0.995 leaf=0
        rom[ 209] = 54'h3FD8698D2FFE07;  // feat= 7 thr= -0.1250 L= 210 R= 211 cls=3 pur=0.998 leaf=0
        rom[ 210] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 211] = 54'h3F186A8D400187;  // feat= 7 thr=  0.0938 L= 212 R= 213 cls=3 pur=0.984 leaf=0
        rom[ 212] = 54'h2EDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.730 leaf=1
        rom[ 213] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 214] = 54'h36186C0D700459;  // feat= 9 thr=  0.2695 L= 215 R= 216 cls=3 pur=0.844 leaf=0
        rom[ 215] = 54'h231C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.545 leaf=1
        rom[ 216] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 217] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 218] = 54'h3F98850DB015BE;  // feat=14 thr=  1.3555 L= 219 R= 266 cls=3 pur=0.991 leaf=0
        rom[ 219] = 54'h36986E8DCFF933;  // feat= 3 thr= -0.4258 L= 220 R= 221 cls=3 pur=0.852 leaf=0
        rom[ 220] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 221] = 54'h2258818DE00178;  // feat= 8 thr=  0.0898 L= 222 R= 259 cls=3 pur=0.534 leaf=0
        rom[ 222] = 54'h2188760DFFFE07;  // feat= 7 thr= -0.1250 L= 223 R= 236 cls=1 pur=0.522 leaf=0
        rom[ 223] = 54'h2B58738E000006;  // feat= 6 thr=  0.0000 L= 224 R= 231 cls=3 pur=0.678 leaf=0
        rom[ 224] = 54'h3E58720E1FFD83;  // feat= 3 thr= -0.1562 L= 225 R= 228 cls=3 pur=0.972 leaf=0
        rom[ 225] = 54'h3FD8718E200079;  // feat= 9 thr=  0.0273 L= 226 R= 227 cls=3 pur=0.996 leaf=0
        rom[ 226] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 227] = 54'h399C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.900 leaf=1
        rom[ 228] = 54'h2E18730E5FFF81;  // feat= 1 thr= -0.0312 L= 229 R= 230 cls=3 pur=0.720 leaf=0
        rom[ 229] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 230] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 231] = 54'h3240748E800F5E;  // feat=14 thr=  0.9570 L= 232 R= 233 cls=0 pur=0.786 leaf=0
        rom[ 232] = 54'h3DCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.964 leaf=1
        rom[ 233] = 54'h3FC0758EAFFFDC;  // feat=12 thr= -0.0117 L= 234 R= 235 cls=0 pur=1.000 leaf=0
        rom[ 234] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 235] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 236] = 54'h2FC8800EDFFE07;  // feat= 7 thr= -0.1250 L= 237 R= 256 cls=1 pur=0.747 leaf=0
        rom[ 237] = 54'h32887D8EEFFF69;  // feat= 9 thr= -0.0391 L= 238 R= 251 cls=1 pur=0.791 leaf=0
        rom[ 238] = 54'h37887B0EFFFD68;  // feat= 8 thr= -0.1641 L= 239 R= 246 cls=1 pur=0.865 leaf=0
        rom[ 239] = 54'h3208798F0FFAE8;  // feat= 8 thr= -0.3203 L= 240 R= 243 cls=1 pur=0.780 leaf=0
        rom[ 240] = 54'h3FC8790F1FF933;  // feat= 3 thr= -0.4258 L= 241 R= 242 cls=1 pur=0.994 leaf=0
        rom[ 241] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 242] = 54'h3C0C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.937 leaf=1
        rom[ 243] = 54'h3E987A8F4FFD83;  // feat= 3 thr= -0.1562 L= 244 R= 245 cls=3 pur=0.977 leaf=0
        rom[ 244] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 245] = 54'h2EDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.730 leaf=1
        rom[ 246] = 54'h3E487C0F7FFC12;  // feat= 2 thr= -0.2461 L= 247 R= 248 cls=1 pur=0.972 leaf=0
        rom[ 247] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 248] = 54'h3FC87D0F9FFF69;  // feat= 9 thr= -0.0391 L= 249 R= 250 cls=1 pur=0.997 leaf=0
        rom[ 249] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 250] = 54'h3DCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.964 leaf=1
        rom[ 251] = 54'h39987F8FCFFFE4;  // feat= 4 thr= -0.0078 L= 252 R= 255 cls=3 pur=0.897 leaf=0
        rom[ 252] = 54'h3FD87F0FDFF86A;  // feat=10 thr= -0.4766 L= 253 R= 254 cls=3 pur=1.000 leaf=0
        rom[ 253] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 254] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 255] = 54'h2A44000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=0.660 leaf=1
        rom[ 256] = 54'h3D8081101FFAF8;  // feat= 8 thr= -0.3164 L= 257 R= 258 cls=0 pur=0.962 leaf=0
        rom[ 257] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 258] = 54'h2C44000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=0.690 leaf=1
        rom[ 259] = 54'h3DD884904FFFEC;  // feat=12 thr= -0.0078 L= 260 R= 265 cls=3 pur=0.966 leaf=0
        rom[ 260] = 54'h3FD883105FFFE4;  // feat= 4 thr= -0.0078 L= 261 R= 262 cls=3 pur=0.994 leaf=0
        rom[ 261] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 262] = 54'h3B98841070117E;  // feat=14 thr=  1.0898 L= 263 R= 264 cls=3 pur=0.930 leaf=0
        rom[ 263] = 54'h231C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.545 leaf=1
        rom[ 264] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 265] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 266] = 54'h3FD88A10BFFFFC;  // feat=12 thr= -0.0039 L= 267 R= 276 cls=3 pur=1.000 leaf=0
        rom[ 267] = 54'h3FD88990CFFFF4;  // feat= 4 thr= -0.0039 L= 268 R= 275 cls=3 pur=1.000 leaf=0
        rom[ 268] = 54'h3FD88910DFFFE4;  // feat= 4 thr= -0.0078 L= 269 R= 274 cls=3 pur=0.994 leaf=0
        rom[ 269] = 54'h3FD88890EFFD66;  // feat= 6 thr= -0.1641 L= 270 R= 273 cls=3 pur=0.998 leaf=0
        rom[ 270] = 54'h3F188810FFFD26;  // feat= 6 thr= -0.1797 L= 271 R= 272 cls=3 pur=0.983 leaf=0
        rom[ 271] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 272] = 54'h30DC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.762 leaf=1
        rom[ 273] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 274] = 54'h301C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.750 leaf=1
        rom[ 275] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 276] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 277] = 54'h2BC89291600015;  // feat= 5 thr=  0.0039 L= 278 R= 293 cls=1 pur=0.685 leaf=0
        rom[ 278] = 54'h3E808F117FFAE8;  // feat= 8 thr= -0.3203 L= 279 R= 286 cls=0 pur=0.978 leaf=0
        rom[ 279] = 54'h20D08D91801CA2;  // feat= 2 thr=  1.7891 L= 280 R= 283 cls=2 pur=0.511 leaf=0
        rom[ 280] = 54'h3FC08D119FFF69;  // feat= 9 thr= -0.0391 L= 281 R= 282 cls=0 pur=1.000 leaf=0
        rom[ 281] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 282] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 283] = 54'h3F508E91CFFAE8;  // feat= 8 thr= -0.3203 L= 284 R= 285 cls=2 pur=0.989 leaf=0
        rom[ 284] = 54'h3994000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.900 leaf=1
        rom[ 285] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 286] = 54'h3FC09211FFF933;  // feat= 3 thr= -0.4258 L= 287 R= 292 cls=0 pur=0.996 leaf=0
        rom[ 287] = 54'h24D89192001182;  // feat= 2 thr=  1.0938 L= 288 R= 291 cls=3 pur=0.574 leaf=0
        rom[ 288] = 54'h3FC091121FFAE8;  // feat= 8 thr= -0.3203 L= 289 R= 290 cls=0 pur=1.000 leaf=0
        rom[ 289] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 290] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 291] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 292] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 293] = 54'h35C8B9926FFE07;  // feat= 7 thr= -0.1250 L= 294 R= 371 cls=1 pur=0.840 leaf=0
        rom[ 294] = 54'h1D009A127FFAE8;  // feat= 8 thr= -0.3203 L= 295 R= 308 cls=0 pur=0.451 leaf=0
        rom[ 295] = 54'h378897928FFA83;  // feat= 3 thr= -0.3438 L= 296 R= 303 cls=1 pur=0.868 leaf=0
        rom[ 296] = 54'h3EC895129FFE07;  // feat= 7 thr= -0.1250 L= 297 R= 298 cls=1 pur=0.980 leaf=0
        rom[ 297] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 298] = 54'h3F489712BFF963;  // feat= 3 thr= -0.4141 L= 299 R= 302 cls=1 pur=0.988 leaf=0
        rom[ 299] = 54'h3D089692CFFC12;  // feat= 2 thr= -0.2461 L= 300 R= 301 cls=1 pur=0.955 leaf=0
        rom[ 300] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 301] = 54'h260C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.594 leaf=1
        rom[ 302] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 303] = 54'h3D5098930FFAE8;  // feat= 8 thr= -0.3203 L= 304 R= 305 cls=2 pur=0.958 leaf=0
        rom[ 304] = 54'h2694000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.600 leaf=1
        rom[ 305] = 54'h3F5099932FFE07;  // feat= 7 thr= -0.1250 L= 306 R= 307 cls=2 pur=0.989 leaf=0
        rom[ 306] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 307] = 54'h3994000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.900 leaf=1
        rom[ 308] = 54'h22C0B9135003B1;  // feat= 1 thr=  0.2305 L= 309 R= 370 cls=0 pur=0.542 leaf=0
        rom[ 309] = 54'h2AC0A6936FFC22;  // feat= 2 thr= -0.2422 L= 310 R= 333 cls=0 pur=0.669 leaf=0
        rom[ 310] = 54'h1BC8A1137015DE;  // feat=14 thr=  1.3633 L= 311 R= 322 cls=1 pur=0.433 leaf=0
        rom[ 311] = 54'h2BC89C938FFC12;  // feat= 2 thr= -0.2461 L= 312 R= 313 cls=1 pur=0.683 leaf=0
        rom[ 312] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 313] = 54'h2D809E93AFFC12;  // feat= 2 thr= -0.2461 L= 314 R= 317 cls=0 pur=0.709 leaf=0
        rom[ 314] = 54'h3FC09E13BFFFE4;  // feat= 4 thr= -0.0078 L= 315 R= 316 cls=0 pur=1.000 leaf=0
        rom[ 315] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 316] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 317] = 54'h2588A093EFFF69;  // feat= 9 thr= -0.0391 L= 318 R= 321 cls=1 pur=0.586 leaf=0
        rom[ 318] = 54'h3A40A013F006FE;  // feat=14 thr=  0.4336 L= 319 R= 320 cls=0 pur=0.911 leaf=0
        rom[ 319] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 320] = 54'h2904000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=0.640 leaf=1
        rom[ 321] = 54'h3B8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.930 leaf=1
        rom[ 322] = 54'h3358A5143FFEA8;  // feat= 8 thr= -0.0859 L= 323 R= 330 cls=3 pur=0.802 leaf=0
        rom[ 323] = 54'h2C48A394402B0E;  // feat=14 thr=  2.6875 L= 324 R= 327 cls=1 pur=0.693 leaf=0
        rom[ 324] = 54'h3C08A3145FFFEC;  // feat=12 thr= -0.0078 L= 325 R= 326 cls=1 pur=0.937 leaf=0
        rom[ 325] = 54'h364C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.847 leaf=1
        rom[ 326] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 327] = 54'h3998A4948FFDE8;  // feat= 8 thr= -0.1328 L= 328 R= 329 cls=3 pur=0.900 leaf=0
        rom[ 328] = 54'h2EDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.730 leaf=1
        rom[ 329] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 330] = 54'h3E18A614B0000C;  // feat=12 thr=  0.0000 L= 331 R= 332 cls=3 pur=0.971 leaf=0
        rom[ 331] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 332] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 333] = 54'h3280AE94E02092;  // feat= 2 thr=  2.0352 L= 334 R= 349 cls=0 pur=0.789 leaf=0
        rom[ 334] = 54'h3DC0AD14F03D0B;  // feat=11 thr=  3.8125 L= 335 R= 346 cls=0 pur=0.964 leaf=0
        rom[ 335] = 54'h3F40A8950FFFE1;  // feat= 1 thr= -0.0078 L= 336 R= 337 cls=0 pur=0.987 leaf=0
        rom[ 336] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 337] = 54'h3540AB952FFE07;  // feat= 7 thr= -0.1250 L= 338 R= 343 cls=0 pur=0.832 leaf=0
        rom[ 338] = 54'h3EC0AA153FFC22;  // feat= 2 thr= -0.2422 L= 339 R= 340 cls=0 pur=0.981 leaf=0
        rom[ 339] = 54'h3144000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=0.769 leaf=1
        rom[ 340] = 54'h3FC0AB155004FE;  // feat=14 thr=  0.3086 L= 341 R= 342 cls=0 pur=1.000 leaf=0
        rom[ 341] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 342] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 343] = 54'h25C8AC958FFC52;  // feat= 2 thr= -0.2305 L= 344 R= 345 cls=1 pur=0.588 leaf=0
        rom[ 344] = 54'h3A4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.909 leaf=1
        rom[ 345] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 346] = 54'h37C8AE15B0237A;  // feat=10 thr=  2.2148 L= 347 R= 348 cls=1 pur=0.870 leaf=0
        rom[ 347] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 348] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 349] = 54'h1F00B595E00068;  // feat= 8 thr=  0.0234 L= 350 R= 363 cls=0 pur=0.483 leaf=0
        rom[ 350] = 54'h2280B415FFFF81;  // feat= 1 thr= -0.0312 L= 351 R= 360 cls=0 pur=0.540 leaf=0
        rom[ 351] = 54'h2440B396002372;  // feat= 2 thr=  2.2148 L= 352 R= 359 cls=0 pur=0.566 leaf=0
        rom[ 352] = 54'h2208B2161FFE07;  // feat= 7 thr= -0.1250 L= 353 R= 356 cls=1 pur=0.533 leaf=0
        rom[ 353] = 54'h2780B1962FFE78;  // feat= 8 thr= -0.0977 L= 354 R= 355 cls=0 pur=0.618 leaf=0
        rom[ 354] = 54'h3344000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=0.799 leaf=1
        rom[ 355] = 54'h29CC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.652 leaf=1
        rom[ 356] = 54'h3848B3165FFE78;  // feat= 8 thr= -0.0977 L= 357 R= 358 cls=1 pur=0.878 leaf=0
        rom[ 357] = 54'h31CC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.777 leaf=1
        rom[ 358] = 54'h3DCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.964 leaf=1
        rom[ 359] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 360] = 54'h3D18B5169FFE07;  // feat= 7 thr= -0.1250 L= 361 R= 362 cls=3 pur=0.954 leaf=0
        rom[ 361] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 362] = 54'h2EDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.730 leaf=1
        rom[ 363] = 54'h3ED8B896CFFE07;  // feat= 7 thr= -0.1250 L= 364 R= 369 cls=3 pur=0.981 leaf=0
        rom[ 364] = 54'h3C18B816DFFE07;  // feat= 7 thr= -0.1250 L= 365 R= 368 cls=3 pur=0.939 leaf=0
        rom[ 365] = 54'h3FD8B796E038C8;  // feat= 8 thr=  3.5469 L= 366 R= 367 cls=3 pur=1.000 leaf=0
        rom[ 366] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 367] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 368] = 54'h375C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.863 leaf=1
        rom[ 369] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 370] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 371] = 54'h3D08CF974FFE07;  // feat= 7 thr= -0.1250 L= 372 R= 415 cls=1 pur=0.954 leaf=0
        rom[ 372] = 54'h3EC8CD175000C8;  // feat= 8 thr=  0.0469 L= 373 R= 410 cls=1 pur=0.981 leaf=0
        rom[ 373] = 54'h3F08C9976FFF69;  // feat= 9 thr= -0.0391 L= 374 R= 403 cls=1 pur=0.986 leaf=0
        rom[ 374] = 54'h3F48C9177029A2;  // feat= 2 thr=  2.6016 L= 375 R= 402 cls=1 pur=0.989 leaf=0
        rom[ 375] = 54'h3F88C197802092;  // feat= 2 thr=  2.0352 L= 376 R= 387 cls=1 pur=0.991 leaf=0
        rom[ 376] = 54'h3A88C1179FFF52;  // feat= 2 thr= -0.0430 L= 377 R= 386 cls=1 pur=0.913 leaf=0
        rom[ 377] = 54'h3F88BE97AFFC22;  // feat= 2 thr= -0.2422 L= 378 R= 381 cls=1 pur=0.991 leaf=0
        rom[ 378] = 54'h3FC8BE17BFFF46;  // feat= 6 thr= -0.0469 L= 379 R= 380 cls=1 pur=1.000 leaf=0
        rom[ 379] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 380] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 381] = 54'h3D88BF97EFFE07;  // feat= 7 thr= -0.1250 L= 382 R= 383 cls=1 pur=0.962 leaf=0
        rom[ 382] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 383] = 54'h3A48C0980FFE07;  // feat= 7 thr= -0.1250 L= 384 R= 385 cls=1 pur=0.909 leaf=0
        rom[ 384] = 54'h3A4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.909 leaf=1
        rom[ 385] = 54'h3A4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.909 leaf=1
        rom[ 386] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 387] = 54'h3F88C2984FFAF8;  // feat= 8 thr= -0.3164 L= 388 R= 389 cls=1 pur=0.993 leaf=0
        rom[ 388] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 389] = 54'h3FC8C6986FFE07;  // feat= 7 thr= -0.1250 L= 390 R= 397 cls=1 pur=0.994 leaf=0
        rom[ 390] = 54'h3808C5187FFE28;  // feat= 8 thr= -0.1172 L= 391 R= 394 cls=1 pur=0.874 leaf=0
        rom[ 391] = 54'h3AC8C4988FFDF8;  // feat= 8 thr= -0.1289 L= 392 R= 393 cls=1 pur=0.920 leaf=0
        rom[ 392] = 54'h344C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.816 leaf=1
        rom[ 393] = 54'h3C8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.943 leaf=1
        rom[ 394] = 54'h3588C618BFFE48;  // feat= 8 thr= -0.1094 L= 395 R= 396 cls=1 pur=0.836 leaf=0
        rom[ 395] = 54'h2ACC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.667 leaf=1
        rom[ 396] = 54'h3A0C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.905 leaf=1
        rom[ 397] = 54'h3FC8C898EFFE88;  // feat= 8 thr= -0.0938 L= 398 R= 401 cls=1 pur=0.996 leaf=0
        rom[ 398] = 54'h3FC8C818FFFDE8;  // feat= 8 thr= -0.1328 L= 399 R= 400 cls=1 pur=0.996 leaf=0
        rom[ 399] = 54'h3DCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.965 leaf=1
        rom[ 400] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.996 leaf=1
        rom[ 401] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 402] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 403] = 54'h1780CB994FFC18;  // feat= 8 thr= -0.2461 L= 404 R= 407 cls=0 pur=0.367 leaf=0
        rom[ 404] = 54'h3FC0CB195FFBAB;  // feat=11 thr= -0.2734 L= 405 R= 406 cls=0 pur=1.000 leaf=0
        rom[ 405] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 406] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 407] = 54'h2348CC99800B16;  // feat= 6 thr=  0.6914 L= 408 R= 409 cls=1 pur=0.552 leaf=0
        rom[ 408] = 54'h328C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.787 leaf=1
        rom[ 409] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 410] = 54'h2DD8CE19BFFFDC;  // feat=12 thr= -0.0117 L= 411 R= 412 cls=3 pur=0.716 leaf=0
        rom[ 411] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 412] = 54'h2CC0CF19DFFC22;  // feat= 2 thr= -0.2422 L= 413 R= 414 cls=0 pur=0.698 leaf=0
        rom[ 413] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 414] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 415] = 54'h3FC0D09A0FFE87;  // feat= 7 thr= -0.0938 L= 416 R= 417 cls=0 pur=0.996 leaf=0
        rom[ 416] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 417] = 54'h2C44000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=0.690 leaf=1
        rom[ 418] = 54'h1A61441A3FFF81;  // feat= 1 thr= -0.0312 L= 419 R= 648 cls=4 pur=0.410 leaf=0
        rom[ 419] = 54'h2F11039A4FFF69;  // feat= 9 thr= -0.0391 L= 420 R= 519 cls=2 pur=0.734 leaf=0
        rom[ 420] = 54'h2DA0E11A5FFFE4;  // feat= 4 thr= -0.0078 L= 421 R= 450 cls=4 pur=0.712 leaf=0
        rom[ 421] = 54'h3E40D79A601823;  // feat= 3 thr=  1.5078 L= 422 R= 431 cls=0 pur=0.973 leaf=0
        rom[ 422] = 54'h3FC0D71A7FF836;  // feat= 6 thr= -0.4883 L= 423 R= 430 cls=0 pur=0.996 leaf=0
        rom[ 423] = 54'h3FC0D49A8FFE17;  // feat= 7 thr= -0.1211 L= 424 R= 425 cls=0 pur=0.998 leaf=0
        rom[ 424] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 425] = 54'h3D40D69AAFFAE8;  // feat= 8 thr= -0.3203 L= 426 R= 429 cls=0 pur=0.956 leaf=0
        rom[ 426] = 54'h2AE0D61ABFFE10;  // feat= 0 thr= -0.1211 L= 427 R= 428 cls=4 pur=0.667 leaf=0
        rom[ 427] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 428] = 54'h3A64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.909 leaf=1
        rom[ 429] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 430] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 431] = 54'h2F00DF9B0018B3;  // feat= 3 thr=  1.5430 L= 432 R= 447 cls=0 pur=0.735 leaf=0
        rom[ 432] = 54'h2B90DF1B1FFE07;  // feat= 7 thr= -0.1250 L= 433 R= 446 cls=2 pur=0.678 leaf=0
        rom[ 433] = 54'h3990DE9B202122;  // feat= 2 thr=  2.0703 L= 434 R= 445 cls=2 pur=0.898 leaf=0
        rom[ 434] = 54'h3BD0DD1B3009F0;  // feat= 0 thr=  0.6211 L= 435 R= 442 cls=2 pur=0.935 leaf=0
        rom[ 435] = 54'h3E10DC9B4FFAEB;  // feat=11 thr= -0.3203 L= 436 R= 441 cls=2 pur=0.970 leaf=0
        rom[ 436] = 54'h3BD0DC1B5FFAE8;  // feat= 8 thr= -0.3203 L= 437 R= 440 cls=2 pur=0.935 leaf=0
        rom[ 437] = 54'h3F10DB9B6FFAE8;  // feat= 8 thr= -0.3203 L= 438 R= 439 cls=2 pur=0.986 leaf=0
        rom[ 438] = 54'h3454000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.818 leaf=1
        rom[ 439] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 440] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 441] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 442] = 54'h2240DE1BBFF99E;  // feat=14 thr= -0.4023 L= 443 R= 444 cls=0 pur=0.536 leaf=0
        rom[ 443] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 444] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 445] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 446] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 447] = 54'h3FC0E09C0FFFE4;  // feat= 4 thr= -0.0078 L= 448 R= 449 cls=0 pur=1.000 leaf=0
        rom[ 448] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 449] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 450] = 54'h3F61021C3FF9BE;  // feat=14 thr= -0.3945 L= 451 R= 516 cls=4 pur=0.989 leaf=0
        rom[ 451] = 54'h3FE0E39C4FFE10;  // feat= 0 thr= -0.1211 L= 452 R= 455 cls=4 pur=0.997 leaf=0
        rom[ 452] = 54'h39C0E31C5FF99E;  // feat=14 thr= -0.4023 L= 453 R= 454 cls=0 pur=0.901 leaf=0
        rom[ 453] = 54'h280C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.625 leaf=1
        rom[ 454] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 455] = 54'h3FE0E69C8FFB78;  // feat= 8 thr= -0.2852 L= 456 R= 461 cls=4 pur=0.999 leaf=0
        rom[ 456] = 54'h3F20E51C9FFB78;  // feat= 8 thr= -0.2852 L= 457 R= 458 cls=4 pur=0.983 leaf=0
        rom[ 457] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 458] = 54'h3D60E61CBFFB78;  // feat= 8 thr= -0.2852 L= 459 R= 460 cls=4 pur=0.959 leaf=0
        rom[ 459] = 54'h3EA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.976 leaf=1
        rom[ 460] = 54'h3C24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.937 leaf=1
        rom[ 461] = 54'h3FE0FB9CEFFE07;  // feat= 7 thr= -0.1250 L= 462 R= 503 cls=4 pur=0.999 leaf=0
        rom[ 462] = 54'h3FE0FB1CFFFB88;  // feat= 8 thr= -0.2812 L= 463 R= 502 cls=4 pur=0.999 leaf=0
        rom[ 463] = 54'h3FE0F59D0FFE07;  // feat= 7 thr= -0.1250 L= 464 R= 491 cls=4 pur=0.999 leaf=0
        rom[ 464] = 54'h3FE0F51D1FFB88;  // feat= 8 thr= -0.2812 L= 465 R= 490 cls=4 pur=0.999 leaf=0
        rom[ 465] = 54'h3FE0EE9D2FFB78;  // feat= 8 thr= -0.2852 L= 466 R= 477 cls=4 pur=0.999 leaf=0
        rom[ 466] = 54'h3FE0EC1D3FFB78;  // feat= 8 thr= -0.2852 L= 467 R= 472 cls=4 pur=0.999 leaf=0
        rom[ 467] = 54'h3FE0EB9D4FFB78;  // feat= 8 thr= -0.2852 L= 468 R= 471 cls=4 pur=0.999 leaf=0
        rom[ 468] = 54'h3FE0EB1D5FFB78;  // feat= 8 thr= -0.2852 L= 469 R= 470 cls=4 pur=0.999 leaf=0
        rom[ 469] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.999 leaf=1
        rom[ 470] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.998 leaf=1
        rom[ 471] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 472] = 54'h3F20ED1D9FFE07;  // feat= 7 thr= -0.1250 L= 473 R= 474 cls=4 pur=0.985 leaf=0
        rom[ 473] = 54'h3EA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.976 leaf=1
        rom[ 474] = 54'h3F60EE1DBFFB78;  // feat= 8 thr= -0.2852 L= 475 R= 476 cls=4 pur=0.989 leaf=0
        rom[ 475] = 54'h3EA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.976 leaf=1
        rom[ 476] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 477] = 54'h3FE0F19DEFFE07;  // feat= 7 thr= -0.1250 L= 478 R= 483 cls=4 pur=0.999 leaf=0
        rom[ 478] = 54'h3FA0F11DFFFB78;  // feat= 8 thr= -0.2852 L= 479 R= 482 cls=4 pur=0.994 leaf=0
        rom[ 479] = 54'h3E20F09E0FFE07;  // feat= 7 thr= -0.1250 L= 480 R= 481 cls=4 pur=0.968 leaf=0
        rom[ 480] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 481] = 54'h3BA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.930 leaf=1
        rom[ 482] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 483] = 54'h3FE0F39E4FFB78;  // feat= 8 thr= -0.2852 L= 484 R= 487 cls=4 pur=0.999 leaf=0
        rom[ 484] = 54'h3FE0F31E5FFE07;  // feat= 7 thr= -0.1250 L= 485 R= 486 cls=4 pur=1.000 leaf=0
        rom[ 485] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 486] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.999 leaf=1
        rom[ 487] = 54'h3FE0F49E8FFB88;  // feat= 8 thr= -0.2812 L= 488 R= 489 cls=4 pur=0.999 leaf=0
        rom[ 488] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.998 leaf=1
        rom[ 489] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 490] = 54'h3EA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.976 leaf=1
        rom[ 491] = 54'h3FE0F69ECFFB78;  // feat= 8 thr= -0.2852 L= 492 R= 493 cls=4 pur=0.997 leaf=0
        rom[ 492] = 54'h3EA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.976 leaf=1
        rom[ 493] = 54'h3FE0F79EEFFB78;  // feat= 8 thr= -0.2852 L= 494 R= 495 cls=4 pur=0.997 leaf=0
        rom[ 494] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 495] = 54'h3FE0FA9F0FFE07;  // feat= 7 thr= -0.1250 L= 496 R= 501 cls=4 pur=0.995 leaf=0
        rom[ 496] = 54'h3F60FA1F1FFE07;  // feat= 7 thr= -0.1250 L= 497 R= 500 cls=4 pur=0.990 leaf=0
        rom[ 497] = 54'h3FE0F99F2FFB78;  // feat= 8 thr= -0.2852 L= 498 R= 499 cls=4 pur=0.994 leaf=0
        rom[ 498] = 54'h3F24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.986 leaf=1
        rom[ 499] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 500] = 54'h3C24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.938 leaf=1
        rom[ 501] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 502] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 503] = 54'h3FA1019F8FFB88;  // feat= 8 thr= -0.2812 L= 504 R= 515 cls=4 pur=0.994 leaf=0
        rom[ 504] = 54'h3FA0FD1F9FFB78;  // feat= 8 thr= -0.2852 L= 505 R= 506 cls=4 pur=0.991 leaf=0
        rom[ 505] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 506] = 54'h3F60FE1FBFFB78;  // feat= 8 thr= -0.2852 L= 507 R= 508 cls=4 pur=0.989 leaf=0
        rom[ 507] = 54'h3C24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.938 leaf=1
        rom[ 508] = 54'h3FA0FF1FDFFE07;  // feat= 7 thr= -0.1250 L= 509 R= 510 cls=4 pur=0.992 leaf=0
        rom[ 509] = 54'h3E64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.972 leaf=1
        rom[ 510] = 54'h3FE1001FFFFE07;  // feat= 7 thr= -0.1250 L= 511 R= 512 cls=4 pur=0.995 leaf=0
        rom[ 511] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 512] = 54'h3F2101201FFB78;  // feat= 8 thr= -0.2852 L= 513 R= 514 cls=4 pur=0.985 leaf=0
        rom[ 513] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 514] = 54'h3C24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.937 leaf=1
        rom[ 515] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 516] = 54'h3E8103205FF9BE;  // feat=14 thr= -0.3945 L= 517 R= 518 cls=0 pur=0.976 leaf=0
        rom[ 517] = 54'h280C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.625 leaf=1
        rom[ 518] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 519] = 54'h3FD143A08FFFE4;  // feat= 4 thr= -0.0078 L= 520 R= 647 cls=2 pur=0.997 leaf=0
        rom[ 520] = 54'h3FD106209FF9AE;  // feat=14 thr= -0.3984 L= 521 R= 524 cls=2 pur=0.999 leaf=0
        rom[ 521] = 54'h2BE105A0AFFAE8;  // feat= 8 thr= -0.3203 L= 522 R= 523 cls=4 pur=0.682 leaf=0
        rom[ 522] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 523] = 54'h3C24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.937 leaf=1
        rom[ 524] = 54'h3FD10720DFF9A3;  // feat= 3 thr= -0.3984 L= 525 R= 526 cls=2 pur=1.000 leaf=0
        rom[ 525] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 526] = 54'h3FD10920FFF846;  // feat= 6 thr= -0.4844 L= 527 R= 530 cls=2 pur=1.000 leaf=0
        rom[ 527] = 54'h3FD108A10FFAE8;  // feat= 8 thr= -0.3203 L= 528 R= 529 cls=2 pur=1.000 leaf=0
        rom[ 528] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 529] = 54'h2F54000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.738 leaf=1
        rom[ 530] = 54'h3FD128213FFF89;  // feat= 9 thr= -0.0312 L= 531 R= 592 cls=2 pur=0.999 leaf=0
        rom[ 531] = 54'h3FD11BA14FFF89;  // feat= 9 thr= -0.0312 L= 532 R= 567 cls=2 pur=0.999 leaf=0
        rom[ 532] = 54'h3FD10E215FFF79;  // feat= 9 thr= -0.0352 L= 533 R= 540 cls=2 pur=0.999 leaf=0
        rom[ 533] = 54'h3F910DA16FFF79;  // feat= 9 thr= -0.0352 L= 534 R= 539 cls=2 pur=0.993 leaf=0
        rom[ 534] = 54'h3FD10C217FFC70;  // feat= 0 thr= -0.2227 L= 535 R= 536 cls=2 pur=0.997 leaf=0
        rom[ 535] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 536] = 54'h3F910D219FFD00;  // feat= 0 thr= -0.1875 L= 537 R= 538 cls=2 pur=0.992 leaf=0
        rom[ 537] = 54'h3994000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.900 leaf=1
        rom[ 538] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 539] = 54'h3CD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.947 leaf=1
        rom[ 540] = 54'h3FD11321DFFA20;  // feat= 0 thr= -0.3672 L= 541 R= 550 cls=2 pur=1.000 leaf=0
        rom[ 541] = 54'h3FD111A1EFFA20;  // feat= 0 thr= -0.3672 L= 542 R= 547 cls=2 pur=0.997 leaf=0
        rom[ 542] = 54'h3FD11121FFFF79;  // feat= 9 thr= -0.0352 L= 543 R= 546 cls=2 pur=0.998 leaf=0
        rom[ 543] = 54'h3F1110A20FFA00;  // feat= 0 thr= -0.3750 L= 544 R= 545 cls=2 pur=0.985 leaf=0
        rom[ 544] = 54'h3994000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.900 leaf=1
        rom[ 545] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 546] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 547] = 54'h3DD112A24FFF89;  // feat= 9 thr= -0.0312 L= 548 R= 549 cls=2 pur=0.964 leaf=0
        rom[ 548] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 549] = 54'h3994000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.900 leaf=1
        rom[ 550] = 54'h3FD11922703110;  // feat= 0 thr=  3.0664 L= 551 R= 562 cls=2 pur=1.000 leaf=0
        rom[ 551] = 54'h3FD116A28FFF89;  // feat= 9 thr= -0.0312 L= 552 R= 557 cls=2 pur=1.000 leaf=0
        rom[ 552] = 54'h3FD116229FFF79;  // feat= 9 thr= -0.0352 L= 553 R= 556 cls=2 pur=1.000 leaf=0
        rom[ 553] = 54'h3FD115A2AFFF79;  // feat= 9 thr= -0.0352 L= 554 R= 555 cls=2 pur=0.999 leaf=0
        rom[ 554] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 555] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.999 leaf=1
        rom[ 556] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 557] = 54'h3FD117A2EFFDB0;  // feat= 0 thr= -0.1445 L= 558 R= 559 cls=2 pur=0.999 leaf=0
        rom[ 558] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 559] = 54'h3FD118A30FFDE0;  // feat= 0 thr= -0.1328 L= 560 R= 561 cls=2 pur=0.998 leaf=0
        rom[ 560] = 54'h3D14000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.953 leaf=1
        rom[ 561] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 562] = 54'h3FD11B233031A0;  // feat= 0 thr=  3.1016 L= 563 R= 566 cls=2 pur=0.997 leaf=0
        rom[ 563] = 54'h3E111AA34FFE07;  // feat= 7 thr= -0.1250 L= 564 R= 565 cls=2 pur=0.967 leaf=0
        rom[ 564] = 54'h3994000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.900 leaf=1
        rom[ 565] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 566] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 567] = 54'h3FD127A38003B0;  // feat= 0 thr=  0.2305 L= 568 R= 591 cls=2 pur=0.997 leaf=0
        rom[ 568] = 54'h3FD127239003B0;  // feat= 0 thr=  0.2305 L= 569 R= 590 cls=2 pur=0.997 leaf=0
        rom[ 569] = 54'h3FD124A3AFFF89;  // feat= 9 thr= -0.0312 L= 570 R= 585 cls=2 pur=0.997 leaf=0
        rom[ 570] = 54'h3FD12123BFFF89;  // feat= 9 thr= -0.0312 L= 571 R= 578 cls=2 pur=0.996 leaf=0
        rom[ 571] = 54'h3FD11FA3C00170;  // feat= 0 thr=  0.0898 L= 572 R= 575 cls=2 pur=0.998 leaf=0
        rom[ 572] = 54'h3FD11F23DFFDA0;  // feat= 0 thr= -0.1484 L= 573 R= 574 cls=2 pur=0.999 leaf=0
        rom[ 573] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.999 leaf=1
        rom[ 574] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 575] = 54'h3F9120A4000180;  // feat= 0 thr=  0.0938 L= 576 R= 577 cls=2 pur=0.991 leaf=0
        rom[ 576] = 54'h3994000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.900 leaf=1
        rom[ 577] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.994 leaf=1
        rom[ 578] = 54'h3FD123243FFFC0;  // feat= 0 thr= -0.0156 L= 579 R= 582 cls=2 pur=0.995 leaf=0
        rom[ 579] = 54'h3FD122A44FFFC0;  // feat= 0 thr= -0.0156 L= 580 R= 581 cls=2 pur=0.995 leaf=0
        rom[ 580] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.995 leaf=1
        rom[ 581] = 54'h3B94000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.931 leaf=1
        rom[ 582] = 54'h3FD124247FFF89;  // feat= 9 thr= -0.0312 L= 583 R= 584 cls=2 pur=0.999 leaf=0
        rom[ 583] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 584] = 54'h3F94000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.994 leaf=1
        rom[ 585] = 54'h3FD125A4A00020;  // feat= 0 thr=  0.0078 L= 586 R= 587 cls=2 pur=0.999 leaf=0
        rom[ 586] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 587] = 54'h3FD126A4C00060;  // feat= 0 thr=  0.0234 L= 588 R= 589 cls=2 pur=0.995 leaf=0
        rom[ 588] = 54'h3994000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.900 leaf=1
        rom[ 589] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 590] = 54'h3B94000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.931 leaf=1
        rom[ 591] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 592] = 54'h3FD135251FFFA9;  // feat= 9 thr= -0.0234 L= 593 R= 618 cls=2 pur=0.999 leaf=0
        rom[ 593] = 54'h3FD12EA52FFF89;  // feat= 9 thr= -0.0312 L= 594 R= 605 cls=2 pur=1.000 leaf=0
        rom[ 594] = 54'h3FD12A253FFAE0;  // feat= 0 thr= -0.3203 L= 595 R= 596 cls=2 pur=0.999 leaf=0
        rom[ 595] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 596] = 54'h3FD12B255FFAE0;  // feat= 0 thr= -0.3203 L= 597 R= 598 cls=2 pur=0.999 leaf=0
        rom[ 597] = 54'h3D14000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.953 leaf=1
        rom[ 598] = 54'h3FD12C257FFC40;  // feat= 0 thr= -0.2344 L= 599 R= 600 cls=2 pur=0.999 leaf=0
        rom[ 599] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 600] = 54'h3FD12D259FFC40;  // feat= 0 thr= -0.2344 L= 601 R= 602 cls=2 pur=0.999 leaf=0
        rom[ 601] = 54'h3994000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.900 leaf=1
        rom[ 602] = 54'h3FD12E25BFFF90;  // feat= 0 thr= -0.0273 L= 603 R= 604 cls=2 pur=0.999 leaf=0
        rom[ 603] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 604] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.999 leaf=1
        rom[ 605] = 54'h3FD12FA5EFFF00;  // feat= 0 thr= -0.0625 L= 606 R= 607 cls=2 pur=1.000 leaf=0
        rom[ 606] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 607] = 54'h3FD131A60FFF00;  // feat= 0 thr= -0.0625 L= 608 R= 611 cls=2 pur=1.000 leaf=0
        rom[ 608] = 54'h3D1131261FFF99;  // feat= 9 thr= -0.0273 L= 609 R= 610 cls=2 pur=0.953 leaf=0
        rom[ 609] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 610] = 54'h3994000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.900 leaf=1
        rom[ 611] = 54'h3FD132A6400BA0;  // feat= 0 thr=  0.7266 L= 612 R= 613 cls=2 pur=1.000 leaf=0
        rom[ 612] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 613] = 54'h3FD134A6600C20;  // feat= 0 thr=  0.7578 L= 614 R= 617 cls=2 pur=1.000 leaf=0
        rom[ 614] = 54'h3E1134267FFF99;  // feat= 9 thr= -0.0273 L= 615 R= 616 cls=2 pur=0.967 leaf=0
        rom[ 615] = 54'h3CD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.947 leaf=1
        rom[ 616] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 617] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 618] = 54'h3FD13726BFF9F0;  // feat= 0 thr= -0.3789 L= 619 R= 622 cls=2 pur=0.999 leaf=0
        rom[ 619] = 54'h3D1136A6CFFFD9;  // feat= 9 thr= -0.0117 L= 620 R= 621 cls=2 pur=0.953 leaf=0
        rom[ 620] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 621] = 54'h3994000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.900 leaf=1
        rom[ 622] = 54'h3FD13E26FFFD20;  // feat= 0 thr= -0.1797 L= 623 R= 636 cls=2 pur=0.999 leaf=0
        rom[ 623] = 54'h3FD13DA70FFB00;  // feat= 0 thr= -0.3125 L= 624 R= 635 cls=2 pur=0.999 leaf=0
        rom[ 624] = 54'h3FD13B271FFB00;  // feat= 0 thr= -0.3125 L= 625 R= 630 cls=2 pur=0.999 leaf=0
        rom[ 625] = 54'h3FD13AA72FFAE0;  // feat= 0 thr= -0.3203 L= 626 R= 629 cls=2 pur=0.999 leaf=0
        rom[ 626] = 54'h3FD13A273FFAE0;  // feat= 0 thr= -0.3203 L= 627 R= 628 cls=2 pur=0.999 leaf=0
        rom[ 627] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.999 leaf=1
        rom[ 628] = 54'h3AD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.918 leaf=1
        rom[ 629] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 630] = 54'h3F113C277FFFB9;  // feat= 9 thr= -0.0195 L= 631 R= 632 cls=2 pur=0.985 leaf=0
        rom[ 631] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 632] = 54'h3E113D27900059;  // feat= 9 thr=  0.0195 L= 633 R= 634 cls=2 pur=0.970 leaf=0
        rom[ 633] = 54'h3F14000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.983 leaf=1
        rom[ 634] = 54'h3994000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.900 leaf=1
        rom[ 635] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 636] = 54'h3FD13F27DFFD20;  // feat= 0 thr= -0.1797 L= 637 R= 638 cls=2 pur=0.998 leaf=0
        rom[ 637] = 54'h3B94000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.931 leaf=1
        rom[ 638] = 54'h3FD14327FFFFE9;  // feat= 9 thr= -0.0078 L= 639 R= 646 cls=2 pur=0.999 leaf=0
        rom[ 639] = 54'h3FD141A8000450;  // feat= 0 thr=  0.2695 L= 640 R= 643 cls=2 pur=0.998 leaf=0
        rom[ 640] = 54'h3FD14128100420;  // feat= 0 thr=  0.2578 L= 641 R= 642 cls=2 pur=0.997 leaf=0
        rom[ 641] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.997 leaf=1
        rom[ 642] = 54'h3994000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.900 leaf=1
        rom[ 643] = 54'h3FD142A8402A30;  // feat= 0 thr=  2.6367 L= 644 R= 645 cls=2 pur=0.999 leaf=0
        rom[ 644] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 645] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.998 leaf=1
        rom[ 646] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 647] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 648] = 54'h2B215A289FFBB0;  // feat= 0 thr= -0.2695 L= 649 R= 692 cls=4 pur=0.671 leaf=0
        rom[ 649] = 54'h3F0152A8AFFA50;  // feat= 0 thr= -0.3555 L= 650 R= 677 cls=0 pur=0.984 leaf=0
        rom[ 650] = 54'h3FC14A28BFF9BE;  // feat=14 thr= -0.3945 L= 651 R= 660 cls=0 pur=0.996 leaf=0
        rom[ 651] = 54'h2EC146A8CFF9BE;  // feat=14 thr= -0.3945 L= 652 R= 653 cls=0 pur=0.731 leaf=0
        rom[ 652] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 653] = 54'h2ED148A8EFFA20;  // feat= 0 thr= -0.3672 L= 654 R= 657 cls=2 pur=0.731 leaf=0
        rom[ 654] = 54'h3E514828FFFE07;  // feat= 7 thr= -0.1250 L= 655 R= 656 cls=2 pur=0.972 leaf=0
        rom[ 655] = 54'h2694000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.600 leaf=1
        rom[ 656] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 657] = 54'h3FC149A92FFFCC;  // feat=12 thr= -0.0156 L= 658 R= 659 cls=0 pur=1.000 leaf=0
        rom[ 658] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 659] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 660] = 54'h3FC151295FFA30;  // feat= 0 thr= -0.3633 L= 661 R= 674 cls=0 pur=0.999 leaf=0
        rom[ 661] = 54'h3F814CA96FFA00;  // feat= 0 thr= -0.3750 L= 662 R= 665 cls=0 pur=0.992 leaf=0
        rom[ 662] = 54'h3FC14C297FFF81;  // feat= 1 thr= -0.0312 L= 663 R= 664 cls=0 pur=1.000 leaf=0
        rom[ 663] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 664] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 665] = 54'h32C14EA9AFFF79;  // feat= 9 thr= -0.0352 L= 666 R= 669 cls=0 pur=0.792 leaf=0
        rom[ 666] = 54'h2C514E29B00D03;  // feat= 3 thr=  0.8125 L= 667 R= 668 cls=2 pur=0.692 leaf=0
        rom[ 667] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 668] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 669] = 54'h3A8150A9EFFFC9;  // feat= 9 thr= -0.0156 L= 670 R= 673 cls=0 pur=0.914 leaf=0
        rom[ 670] = 54'h3FC15029FFFBBB;  // feat=11 thr= -0.2695 L= 671 R= 672 cls=0 pur=1.000 leaf=0
        rom[ 671] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 672] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 673] = 54'h280C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.625 leaf=1
        rom[ 674] = 54'h3FC1522A300015;  // feat= 5 thr=  0.0039 L= 675 R= 676 cls=0 pur=1.000 leaf=0
        rom[ 675] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 676] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 677] = 54'h330154AA6FFA50;  // feat= 0 thr= -0.3555 L= 678 R= 681 cls=0 pur=0.795 leaf=0
        rom[ 678] = 54'h3F49542A7FFF81;  // feat= 1 thr= -0.0312 L= 679 R= 680 cls=1 pur=0.988 leaf=0
        rom[ 679] = 54'h280C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.625 leaf=1
        rom[ 680] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 681] = 54'h3C8158AAA01932;  // feat= 2 thr=  1.5742 L= 682 R= 689 cls=0 pur=0.944 leaf=0
        rom[ 682] = 54'h3F41572ABFFF69;  // feat= 9 thr= -0.0391 L= 683 R= 686 cls=0 pur=0.987 leaf=0
        rom[ 683] = 54'h290156AAC00015;  // feat= 5 thr=  0.0039 L= 684 R= 685 cls=0 pur=0.640 leaf=0
        rom[ 684] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 685] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 686] = 54'h3FC1582AFFFE07;  // feat= 7 thr= -0.1250 L= 687 R= 688 cls=0 pur=1.000 leaf=0
        rom[ 687] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 688] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 689] = 54'h39D159AB2FF8A6;  // feat= 6 thr= -0.4609 L= 690 R= 691 cls=2 pur=0.903 leaf=0
        rom[ 690] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 691] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 692] = 54'h36A15D2B5FFBE2;  // feat= 2 thr= -0.2578 L= 693 R= 698 cls=4 pur=0.851 leaf=0
        rom[ 693] = 54'h3FC15BAB6039A0;  // feat= 0 thr=  3.6016 L= 694 R= 695 cls=0 pur=1.000 leaf=0
        rom[ 694] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 695] = 54'h3EC15CAB8039B0;  // feat= 0 thr=  3.6055 L= 696 R= 697 cls=0 pur=0.981 leaf=0
        rom[ 696] = 54'h2C44000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=0.690 leaf=1
        rom[ 697] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 698] = 54'h3CA15E2BBFF933;  // feat= 3 thr= -0.4258 L= 699 R= 700 cls=4 pur=0.945 leaf=0
        rom[ 699] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 700] = 54'h3E617F2BD02EE0;  // feat= 0 thr=  2.9297 L= 701 R= 766 cls=4 pur=0.972 leaf=0
        rom[ 701] = 54'h3F217EABE010D2;  // feat= 2 thr=  1.0508 L= 702 R= 765 cls=4 pur=0.983 leaf=0
        rom[ 702] = 54'h3F61622BFFF75A;  // feat=10 thr= -0.5430 L= 703 R= 708 cls=4 pur=0.987 leaf=0
        rom[ 703] = 54'h2EC160AC0FFF81;  // feat= 1 thr= -0.0312 L= 704 R= 705 cls=0 pur=0.731 leaf=0
        rom[ 704] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 705] = 54'h3FC161AC2FFFCC;  // feat=12 thr= -0.0156 L= 706 R= 707 cls=0 pur=1.000 leaf=0
        rom[ 706] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 707] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 708] = 54'h3F617D2C500015;  // feat= 5 thr=  0.0039 L= 709 R= 762 cls=4 pur=0.989 leaf=0
        rom[ 709] = 54'h3FA16DAC6001D0;  // feat= 0 thr=  0.1133 L= 710 R= 731 cls=4 pur=0.990 leaf=0
        rom[ 710] = 54'h3FE16C2C7001D0;  // feat= 0 thr=  0.1133 L= 711 R= 728 cls=4 pur=0.998 leaf=0
        rom[ 711] = 54'h3FA167AC8FF943;  // feat= 3 thr= -0.4219 L= 712 R= 719 cls=4 pur=0.991 leaf=0
        rom[ 712] = 54'h3FE1652C9FFF79;  // feat= 9 thr= -0.0352 L= 713 R= 714 cls=4 pur=1.000 leaf=0
        rom[ 713] = 54'h37E4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.870 leaf=1
        rom[ 714] = 54'h3FE1662CBFF933;  // feat= 3 thr= -0.4258 L= 715 R= 716 cls=4 pur=1.000 leaf=0
        rom[ 715] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 716] = 54'h3FE1672CDFFFB9;  // feat= 9 thr= -0.0195 L= 717 R= 718 cls=4 pur=0.997 leaf=0
        rom[ 717] = 54'h3E64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.972 leaf=1
        rom[ 718] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 719] = 54'h38E16AAD0FFE20;  // feat= 0 thr= -0.1172 L= 720 R= 725 cls=4 pur=0.886 leaf=0
        rom[ 720] = 54'h3CE1692D1FFC70;  // feat= 0 thr= -0.2227 L= 721 R= 722 cls=4 pur=0.947 leaf=0
        rom[ 721] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 722] = 54'h3DA16A2D3FFC22;  // feat= 2 thr= -0.2422 L= 723 R= 724 cls=4 pur=0.962 leaf=0
        rom[ 723] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 724] = 54'h3E64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.971 leaf=1
        rom[ 725] = 54'h3FC16BAD6FFEA0;  // feat= 0 thr= -0.0859 L= 726 R= 727 cls=0 pur=1.000 leaf=0
        rom[ 726] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 727] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 728] = 54'h3FE16D2D9FFF69;  // feat= 9 thr= -0.0391 L= 729 R= 730 cls=4 pur=1.000 leaf=0
        rom[ 729] = 54'h3C24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.937 leaf=1
        rom[ 730] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 731] = 54'h3E6173ADCFF933;  // feat= 3 thr= -0.4258 L= 732 R= 743 cls=4 pur=0.975 leaf=0
        rom[ 732] = 54'h3FE1732DDFFC22;  // feat= 2 thr= -0.2422 L= 733 R= 742 cls=4 pur=0.999 leaf=0
        rom[ 733] = 54'h3FE16FADEFFC22;  // feat= 2 thr= -0.2422 L= 734 R= 735 cls=4 pur=1.000 leaf=0
        rom[ 734] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 735] = 54'h3FE171AE0FF933;  // feat= 3 thr= -0.4258 L= 736 R= 739 cls=4 pur=1.000 leaf=0
        rom[ 736] = 54'h3FE1712E1FFF99;  // feat= 9 thr= -0.0273 L= 737 R= 738 cls=4 pur=1.000 leaf=0
        rom[ 737] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 738] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 739] = 54'h3FE172AE4FFFB9;  // feat= 9 thr= -0.0195 L= 740 R= 741 cls=4 pur=0.996 leaf=0
        rom[ 740] = 54'h3EA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.976 leaf=1
        rom[ 741] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 742] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 743] = 54'h2E2175AE802C90;  // feat= 0 thr=  2.7852 L= 744 R= 747 cls=4 pur=0.720 leaf=0
        rom[ 744] = 54'h3FC1752E9FF933;  // feat= 3 thr= -0.4258 L= 745 R= 746 cls=0 pur=1.000 leaf=0
        rom[ 745] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 746] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 747] = 54'h38E179AECFFA13;  // feat= 3 thr= -0.3711 L= 748 R= 755 cls=4 pur=0.888 leaf=0
        rom[ 748] = 54'h23A1782EDFF943;  // feat= 3 thr= -0.4219 L= 749 R= 752 cls=4 pur=0.556 leaf=0
        rom[ 749] = 54'h3FA177AEEFFFB9;  // feat= 9 thr= -0.0195 L= 750 R= 751 cls=4 pur=0.992 leaf=0
        rom[ 750] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 751] = 54'h3EA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.976 leaf=1
        rom[ 752] = 54'h25C1792F1002D9;  // feat= 9 thr=  0.1758 L= 753 R= 754 cls=0 pur=0.589 leaf=0
        rom[ 753] = 54'h2FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=0.745 leaf=1
        rom[ 754] = 54'h3924000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.889 leaf=1
        rom[ 755] = 54'h3E217BAF4FFAD3;  // feat= 3 thr= -0.3242 L= 756 R= 759 cls=4 pur=0.968 leaf=0
        rom[ 756] = 54'h3FE17B2F5FFA23;  // feat= 3 thr= -0.3672 L= 757 R= 758 cls=4 pur=0.997 leaf=0
        rom[ 757] = 54'h3BA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.930 leaf=1
        rom[ 758] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.998 leaf=1
        rom[ 759] = 54'h3FC17CAF802CB0;  // feat= 0 thr=  2.7930 L= 760 R= 761 cls=0 pur=1.000 leaf=0
        rom[ 760] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 761] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 762] = 54'h34417E2FBFFC12;  // feat= 2 thr= -0.2461 L= 763 R= 764 cls=0 pur=0.816 leaf=0
        rom[ 763] = 54'h3EA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.976 leaf=1
        rom[ 764] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 765] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 766] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
end

// ── State machine ─────────────────────────────────────────────
// 4-state FSM to handle BRAM registered-output latency.
// BRAM on XC7Z020: address presented at posedge T → data valid at posedge T+1.
// BRAM_WAIT gives that one-cycle settling time after every node_idx update.
localparam IDLE      = 2'd0;
localparam BRAM_WAIT = 2'd1;   // wait one cycle for BRAM output to settle
localparam COMPARE   = 2'd2;   // BRAM data valid — read fields, branch or latch
localparam DONE      = 2'd3;

reg [1:0]  state;
reg [10:0] node_idx;
reg [4:0]  timeout;   // safety counter — max depth 15, allow 20

// ── Feature MUX ───────────────────────────────────────────────
reg signed [15:0] cur_feat;
wire [3:0] feat_sel = rom[node_idx][3:0];
always @(*) begin
    case (feat_sel)
        4'd0:  cur_feat = feat0;
        4'd1:  cur_feat = feat1;
        4'd2:  cur_feat = feat2;
        4'd3:  cur_feat = feat3;
        4'd4:  cur_feat = feat4;
        4'd5:  cur_feat = feat5;
        4'd6:  cur_feat = feat6;
        4'd7:  cur_feat = feat7;
        4'd8:  cur_feat = feat8;
        4'd9:  cur_feat = feat9;
        4'd10: cur_feat = feat10;
        4'd11: cur_feat = feat11;
        4'd12: cur_feat = feat12;
        4'd13: cur_feat = feat13;
        4'd14: cur_feat = feat14;
        default: cur_feat = 16'sd0;
    endcase
end

// ── Decode current ROM entry ──────────────────────────────────
wire        cur_is_leaf  = rom[node_idx][42];
wire [10:0] cur_left     = rom[node_idx][30:20];
wire [10:0] cur_right    = rom[node_idx][41:31];
wire signed [15:0] cur_thresh = $signed(rom[node_idx][19:4]);
wire [2:0]  cur_class    = rom[node_idx][45:43];
wire [7:0]  cur_purity   = rom[node_idx][53:46];

// ── FSM ───────────────────────────────────────────────────────
//
// Cycle trace — 3-node example (path 0 → 1 → 3):
//
//  Notation: node_idx[T] = register value during period T (assigned at posedge T-1).
//            BRAM output[T+1] = rom[ node_idx[T] ] (one-cycle registered pipeline).
//
//  T0  IDLE      node_idx=0, start=1 detected
//                → assign node_idx<=0 (stays 0), state<=BRAM_WAIT
//  T1  BRAM_WAIT node_idx=0.  BRAM addr sampled=0 at T0 → output=rom[0] at T2.
//                → state<=COMPARE
//  T2  COMPARE   BRAM output=rom[0] ✓ (valid for node 0).
//                Compare cur_feat vs cur_thresh[0].  Left taken → node_idx<=1.
//                → state<=BRAM_WAIT
//  T3  BRAM_WAIT node_idx=1.  BRAM addr sampled=1 at T2 → output=rom[1] at T4.
//                → state<=COMPARE
//  T4  COMPARE   BRAM output=rom[1] ✓ (valid for node 1).
//                Compare cur_feat vs cur_thresh[1].  Left taken → node_idx<=3.
//                → state<=BRAM_WAIT
//  T5  BRAM_WAIT node_idx=3.  BRAM addr sampled=3 at T4 → output=rom[3] at T6.
//                → state<=COMPARE
//  T6  COMPARE   BRAM output=rom[3] ✓ (valid for node 3 — leaf).
//                cur_is_leaf=1 → latch class_out, purity_out; done<=1; state<=DONE
//  T7  DONE      done=1, state<=IDLE
//  T8  IDLE      done<=0
//
//  Latency for depth-D tree: 1 (IDLE) + 2*D (BRAM_WAIT+COMPARE per node) + 1 (DONE)
//  Depth-15 DT: 1 + 30 + 1 = 32 cycles  (was ~17 with 3-state FSM)
//
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state      <= IDLE;
        node_idx   <= 11'd0;
        class_out  <= 3'd0;
        purity_out <= 8'd0;
        done       <= 1'b0;
        timeout    <= 5'd0;
    end else begin
        case (state)
            IDLE: begin
                done <= 1'b0;
                if (start) begin
                    node_idx <= 11'd0;
                    timeout  <= 5'd0;
                    state    <= BRAM_WAIT;
                end
            end
            BRAM_WAIT: begin
                // One-cycle stall: BRAM registered output now settling for node_idx.
                state <= COMPARE;
            end
            COMPARE: begin
                timeout <= timeout + 5'd1;
                if (cur_is_leaf || timeout >= 5'd20) begin
                    class_out  <= cur_class;
                    purity_out <= cur_purity;
                    done       <= 1'b1;
                    state      <= DONE;
                end else begin
                    if (cur_feat <= cur_thresh)
                        node_idx <= cur_left;
                    else
                        node_idx <= cur_right;
                    state <= BRAM_WAIT;
                end
            end
            DONE: begin
                done  <= 1'b1;
                state <= IDLE;
            end
        endcase
    end
end

endmodule