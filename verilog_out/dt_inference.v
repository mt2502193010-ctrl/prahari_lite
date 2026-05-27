`timescale 1ns/1ps
// PRAHARI-Lite — Decision Tree Inference Engine
// Nodes: 1533  Max depth: 15  Classes: 5
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
reg [53:0] rom [0:1532];
initial begin
        rom[   0] = 54'h0CDAE9001FF9E0;  // feat= 0 thr= -0.3830 L=   1 R=1490 cls=3 pur=0.200 leaf=0
        rom[   1] = 54'h0F5840802FFF81;  // feat= 1 thr= -0.0319 L=   2 R= 129 cls=3 pur=0.237 leaf=0
        rom[   2] = 54'h349836003FFF81;  // feat= 1 thr= -0.0320 L=   3 R= 108 cls=3 pur=0.820 leaf=0
        rom[   3] = 54'h2CE009804FFF69;  // feat= 9 thr= -0.0379 L=   4 R=  19 cls=4 pur=0.698 leaf=0
        rom[   4] = 54'h1EC004005FFF81;  // feat= 1 thr= -0.0324 L=   5 R=   8 cls=0 pur=0.479 leaf=0
        rom[   5] = 54'h3FC003806FFBC2;  // feat= 2 thr= -0.2646 L=   6 R=   7 cls=0 pur=1.000 leaf=0
        rom[   6] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[   7] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[   8] = 54'h1EC809009FFAE8;  // feat= 8 thr= -0.3222 L=   9 R=  18 cls=1 pur=0.479 leaf=0
        rom[   9] = 54'h20080880AFFF81;  // feat= 1 thr= -0.0320 L=  10 R=  17 cls=1 pur=0.500 leaf=0
        rom[  10] = 54'h21880700BFFFE4;  // feat= 4 thr= -0.0083 L=  11 R=  14 cls=1 pur=0.523 leaf=0
        rom[  11] = 54'h1F080680CFFF81;  // feat= 1 thr= -0.0322 L=  12 R=  13 cls=1 pur=0.486 leaf=0
        rom[  12] = 54'h200C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.500 leaf=1
        rom[  13] = 54'h3F24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.983 leaf=1
        rom[  14] = 54'h3FC80800FFFFE4;  // feat= 4 thr= -0.0083 L=  15 R=  16 cls=1 pur=1.000 leaf=0
        rom[  15] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[  16] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[  17] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[  18] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[  19] = 54'h352035814FF8F3;  // feat= 3 thr= -0.4413 L=  20 R= 107 cls=4 pur=0.830 leaf=0
        rom[  20] = 54'h362023015FFDBE;  // feat=14 thr= -0.1464 L=  21 R=  70 cls=4 pur=0.842 leaf=0
        rom[  21] = 54'h2B6017816FFCCE;  // feat=14 thr= -0.2049 L=  22 R=  47 cls=4 pur=0.676 leaf=0
        rom[  22] = 54'h30A00D017FFF81;  // feat= 1 thr= -0.0323 L=  23 R=  26 cls=4 pur=0.758 leaf=0
        rom[  23] = 54'h28900C818FFFA9;  // feat= 9 thr= -0.0250 L=  24 R=  25 cls=2 pur=0.631 leaf=0
        rom[  24] = 54'h3194000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.772 leaf=1
        rom[  25] = 54'h1A14000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.407 leaf=1
        rom[  26] = 54'h32200E01BFFF89;  // feat= 9 thr= -0.0332 L=  27 R=  28 cls=4 pur=0.780 leaf=0
        rom[  27] = 54'h1764000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.365 leaf=1
        rom[  28] = 54'h33E01101DFFF89;  // feat= 9 thr= -0.0314 L=  29 R=  34 cls=4 pur=0.808 leaf=0
        rom[  29] = 54'h3A201081E00045;  // feat= 5 thr=  0.0175 L=  30 R=  33 cls=4 pur=0.906 leaf=0
        rom[  30] = 54'h39601001FFFF89;  // feat= 9 thr= -0.0324 L=  31 R=  32 cls=4 pur=0.894 leaf=0
        rom[  31] = 54'h3A24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.908 leaf=1
        rom[  32] = 54'h37A4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.866 leaf=1
        rom[  33] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[  34] = 54'h2FE014023FFF99;  // feat= 9 thr= -0.0258 L=  35 R=  40 cls=4 pur=0.747 leaf=0
        rom[  35] = 54'h292013824FFF99;  // feat= 9 thr= -0.0284 L=  36 R=  39 cls=4 pur=0.643 leaf=0
        rom[  36] = 54'h286013025FFF89;  // feat= 9 thr= -0.0301 L=  37 R=  38 cls=4 pur=0.628 leaf=0
        rom[  37] = 54'h2A24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.658 leaf=1
        rom[  38] = 54'h2564000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.584 leaf=1
        rom[  39] = 54'h2AA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.662 leaf=1
        rom[  40] = 54'h36A01702900029;  // feat= 9 thr=  0.0064 L=  41 R=  46 cls=4 pur=0.851 leaf=0
        rom[  41] = 54'h3A601682AFFFC9;  // feat= 9 thr= -0.0141 L=  42 R=  45 cls=4 pur=0.911 leaf=0
        rom[  42] = 54'h39E01602BFFFA9;  // feat= 9 thr= -0.0217 L=  43 R=  44 cls=4 pur=0.901 leaf=0
        rom[  43] = 54'h3C64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.942 leaf=1
        rom[  44] = 54'h3924000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.891 leaf=1
        rom[  45] = 54'h3CE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.950 leaf=1
        rom[  46] = 54'h2DA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.712 leaf=1
        rom[  47] = 54'h18201D830FFF81;  // feat= 1 thr= -0.0322 L=  48 R=  59 cls=4 pur=0.374 leaf=0
        rom[  48] = 54'h1B481A031FFCEE;  // feat=14 thr= -0.1947 L=  49 R=  52 cls=1 pur=0.425 leaf=0
        rom[  49] = 54'h281819832FFF99;  // feat= 9 thr= -0.0284 L=  50 R=  51 cls=3 pur=0.624 leaf=0
        rom[  50] = 54'h27DC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.619 leaf=1
        rom[  51] = 54'h285C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.631 leaf=1
        rom[  52] = 54'h1BC81B035FFF79;  // feat= 9 thr= -0.0342 L=  53 R=  54 cls=1 pur=0.433 leaf=0
        rom[  53] = 54'h2024000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.499 leaf=1
        rom[  54] = 54'h1C481D037FFF89;  // feat= 9 thr= -0.0301 L=  55 R=  58 cls=1 pur=0.441 leaf=0
        rom[  55] = 54'h1D881C838FFF89;  // feat= 9 thr= -0.0324 L=  56 R=  57 cls=1 pur=0.459 leaf=0
        rom[  56] = 54'h1E8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.476 leaf=1
        rom[  57] = 54'h198C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.397 leaf=1
        rom[  58] = 54'h1794000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.367 leaf=1
        rom[  59] = 54'h30A02183CFFF81;  // feat= 1 thr= -0.0321 L=  60 R=  67 cls=4 pur=0.758 leaf=0
        rom[  60] = 54'h39601F03DFFF89;  // feat= 9 thr= -0.0324 L=  61 R=  62 cls=4 pur=0.895 leaf=0
        rom[  61] = 54'h2EE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.730 leaf=1
        rom[  62] = 54'h3CE02003FFFF99;  // feat= 9 thr= -0.0291 L=  63 R=  64 cls=4 pur=0.949 leaf=0
        rom[  63] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[  64] = 54'h39E021041FFD1E;  // feat=14 thr= -0.1820 L=  65 R=  66 cls=4 pur=0.903 leaf=0
        rom[  65] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[  66] = 54'h34E4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.823 leaf=1
        rom[  67] = 54'h1C1822844FFD9E;  // feat=14 thr= -0.1515 L=  68 R=  69 cls=3 pur=0.436 leaf=0
        rom[  68] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[  69] = 54'h2624000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.592 leaf=1
        rom[  70] = 54'h39E034047FFDCE;  // feat=14 thr= -0.1413 L=  71 R= 104 cls=4 pur=0.901 leaf=0
        rom[  71] = 54'h39E029848FFF89;  // feat= 9 thr= -0.0332 L=  72 R=  83 cls=4 pur=0.902 leaf=0
        rom[  72] = 54'h3D6028049FFF79;  // feat= 9 thr= -0.0349 L=  73 R=  80 cls=4 pur=0.958 leaf=0
        rom[  73] = 54'h3D602784AFFF79;  // feat= 9 thr= -0.0357 L=  74 R=  79 cls=4 pur=0.958 leaf=0
        rom[  74] = 54'h3EE02704BFFF69;  // feat= 9 thr= -0.0373 L=  75 R=  78 cls=4 pur=0.980 leaf=0
        rom[  75] = 54'h3E202684CFFF69;  // feat= 9 thr= -0.0377 L=  76 R=  77 cls=4 pur=0.970 leaf=0
        rom[  76] = 54'h3D64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.956 leaf=1
        rom[  77] = 54'h3EA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.977 leaf=1
        rom[  78] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[  79] = 54'h38E4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.886 leaf=1
        rom[  80] = 54'h3D6029051FFF79;  // feat= 9 thr= -0.0338 L=  81 R=  82 cls=4 pur=0.958 leaf=0
        rom[  81] = 54'h3DA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.960 leaf=1
        rom[  82] = 54'h3D64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.958 leaf=1
        rom[  83] = 54'h39A02B854FFF89;  // feat= 9 thr= -0.0314 L=  84 R=  87 cls=4 pur=0.898 leaf=0
        rom[  84] = 54'h38202B055FFF89;  // feat= 9 thr= -0.0324 L=  85 R=  86 cls=4 pur=0.876 leaf=0
        rom[  85] = 54'h38A4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.885 leaf=1
        rom[  86] = 54'h3764000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.864 leaf=1
        rom[  87] = 54'h3AA031858FFFC9;  // feat= 9 thr= -0.0141 L=  88 R=  99 cls=4 pur=0.915 leaf=0
        rom[  88] = 54'h3B602D059FFF89;  // feat= 9 thr= -0.0301 L=  89 R=  90 cls=4 pur=0.926 leaf=0
        rom[  89] = 54'h3E24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.969 leaf=1
        rom[  90] = 54'h3B202E05BFFF99;  // feat= 9 thr= -0.0284 L=  91 R=  92 cls=4 pur=0.920 leaf=0
        rom[  91] = 54'h3724000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.860 leaf=1
        rom[  92] = 54'h3BE02F05DFFF99;  // feat= 9 thr= -0.0258 L=  93 R=  94 cls=4 pur=0.932 leaf=0
        rom[  93] = 54'h3DA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.959 leaf=1
        rom[  94] = 54'h3B603005FFFFA9;  // feat= 9 thr= -0.0217 L=  95 R=  96 cls=4 pur=0.924 leaf=0
        rom[  95] = 54'h38E4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.887 leaf=1
        rom[  96] = 54'h3C603106100095;  // feat= 5 thr=  0.0340 L=  97 R=  98 cls=4 pur=0.941 leaf=0
        rom[  97] = 54'h3C64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.941 leaf=1
        rom[  98] = 54'h3A24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.905 leaf=1
        rom[  99] = 54'h38203386400029;  // feat= 9 thr=  0.0064 L= 100 R= 103 cls=4 pur=0.877 leaf=0
        rom[ 100] = 54'h37A03306500045;  // feat= 5 thr=  0.0166 L= 101 R= 102 cls=4 pur=0.869 leaf=0
        rom[ 101] = 54'h3764000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.861 leaf=1
        rom[ 102] = 54'h3DE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.966 leaf=1
        rom[ 103] = 54'h38A4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.882 leaf=1
        rom[ 104] = 54'h336035069FFF81;  // feat= 1 thr= -0.0320 L= 105 R= 106 cls=4 pur=0.800 leaf=0
        rom[ 105] = 54'h2DE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.716 leaf=1
        rom[ 106] = 54'h3864000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.877 leaf=1
        rom[ 107] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 108] = 54'h3FD83706DFFF69;  // feat= 9 thr= -0.0386 L= 109 R= 110 cls=3 pur=0.999 leaf=0
        rom[ 109] = 54'h379C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.867 leaf=1
        rom[ 110] = 54'h3FD83906FFFF79;  // feat= 9 thr= -0.0351 L= 111 R= 114 cls=3 pur=0.999 leaf=0
        rom[ 111] = 54'h3F5838870FFF79;  // feat= 9 thr= -0.0355 L= 112 R= 113 cls=3 pur=0.986 leaf=0
        rom[ 112] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 113] = 54'h359C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.835 leaf=1
        rom[ 114] = 54'h3FD83E073FFF99;  // feat= 9 thr= -0.0258 L= 115 R= 124 cls=3 pur=0.999 leaf=0
        rom[ 115] = 54'h3FD83D874FFF89;  // feat= 9 thr= -0.0301 L= 116 R= 123 cls=3 pur=0.999 leaf=0
        rom[ 116] = 54'h3FD83D075FFF89;  // feat= 9 thr= -0.0314 L= 117 R= 122 cls=3 pur=0.999 leaf=0
        rom[ 117] = 54'h3FD83C876FFF89;  // feat= 9 thr= -0.0324 L= 118 R= 121 cls=3 pur=1.000 leaf=0
        rom[ 118] = 54'h3FD83C077FFF89;  // feat= 9 thr= -0.0332 L= 119 R= 120 cls=3 pur=1.000 leaf=0
        rom[ 119] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 120] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 121] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.999 leaf=1
        rom[ 122] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.997 leaf=1
        rom[ 123] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 124] = 54'h3FD83F07DFFFA9;  // feat= 9 thr= -0.0217 L= 125 R= 126 cls=3 pur=0.999 leaf=0
        rom[ 125] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.995 leaf=1
        rom[ 126] = 54'h3FD84007FFFFC9;  // feat= 9 thr= -0.0141 L= 127 R= 128 cls=3 pur=0.999 leaf=0
        rom[ 127] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.999 leaf=1
        rom[ 128] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 129] = 54'h12908C882FFF81;  // feat= 1 thr= -0.0315 L= 130 R= 281 cls=2 pur=0.288 leaf=0
        rom[ 130] = 54'h375083083FFFE4;  // feat= 4 thr= -0.0083 L= 131 R= 262 cls=2 pur=0.865 leaf=0
        rom[ 131] = 54'h3C506E8840004E;  // feat=14 thr=  0.0163 L= 132 R= 221 cls=2 pur=0.941 leaf=0
        rom[ 132] = 54'h15D056085FFF81;  // feat= 1 thr= -0.0318 L= 133 R= 172 cls=2 pur=0.340 leaf=0
        rom[ 133] = 54'h23504E886FFEFE;  // feat=14 thr= -0.0651 L= 134 R= 157 cls=2 pur=0.552 leaf=0
        rom[ 134] = 54'h14484C087FFEEE;  // feat=14 thr= -0.0701 L= 135 R= 152 cls=1 pur=0.317 leaf=0
        rom[ 135] = 54'h1B1046888FFF89;  // feat= 9 thr= -0.0324 L= 136 R= 141 cls=2 pur=0.420 leaf=0
        rom[ 136] = 54'h252045089FFF79;  // feat= 9 thr= -0.0340 L= 137 R= 138 cls=4 pur=0.579 leaf=0
        rom[ 137] = 54'h1D14000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.454 leaf=1
        rom[ 138] = 54'h2E204608BFFF81;  // feat= 1 thr= -0.0318 L= 139 R= 140 cls=4 pur=0.717 leaf=0
        rom[ 139] = 54'h2D24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.704 leaf=1
        rom[ 140] = 54'h2F24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.736 leaf=1
        rom[ 141] = 54'h21904A88EFFEBE;  // feat=14 thr= -0.0803 L= 142 R= 149 cls=2 pur=0.523 leaf=0
        rom[ 142] = 54'h24D04808FFFF81;  // feat= 1 thr= -0.0319 L= 143 R= 144 cls=2 pur=0.574 leaf=0
        rom[ 143] = 54'h3254000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.787 leaf=1
        rom[ 144] = 54'h231849091FFF81;  // feat= 1 thr= -0.0319 L= 145 R= 146 cls=3 pur=0.549 leaf=0
        rom[ 145] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 146] = 54'h26104A093FFFA9;  // feat= 9 thr= -0.0217 L= 147 R= 148 cls=2 pur=0.594 leaf=0
        rom[ 147] = 54'h2A94000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.664 leaf=1
        rom[ 148] = 54'h231C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.549 leaf=1
        rom[ 149] = 54'h22604B896FFEDE;  // feat=14 thr= -0.0752 L= 150 R= 151 cls=4 pur=0.535 leaf=0
        rom[ 150] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 151] = 54'h3214000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.780 leaf=1
        rom[ 152] = 54'h3E484D099FFF89;  // feat= 9 thr= -0.0324 L= 153 R= 154 cls=1 pur=0.974 leaf=0
        rom[ 153] = 54'h3BCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.933 leaf=1
        rom[ 154] = 54'h3FC84E09BFFF89;  // feat= 9 thr= -0.0301 L= 155 R= 156 cls=1 pur=0.996 leaf=0
        rom[ 155] = 54'h3F4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.989 leaf=1
        rom[ 156] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 157] = 54'h32D05489EFFF1E;  // feat=14 thr= -0.0600 L= 158 R= 169 cls=2 pur=0.793 leaf=0
        rom[ 158] = 54'h2B105009FFFF69;  // feat= 9 thr= -0.0374 L= 159 R= 160 cls=2 pur=0.671 leaf=0
        rom[ 159] = 54'h21CC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.529 leaf=1
        rom[ 160] = 54'h2C10520A1FFF89;  // feat= 9 thr= -0.0324 L= 161 R= 164 cls=2 pur=0.687 leaf=0
        rom[ 161] = 54'h3010518A2FFF89;  // feat= 9 thr= -0.0332 L= 162 R= 163 cls=2 pur=0.752 leaf=0
        rom[ 162] = 54'h2C14000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.687 leaf=1
        rom[ 163] = 54'h3194000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.772 leaf=1
        rom[ 164] = 54'h2890530A5FFF89;  // feat= 9 thr= -0.0301 L= 165 R= 166 cls=2 pur=0.633 leaf=0
        rom[ 165] = 54'h1DA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.460 leaf=1
        rom[ 166] = 54'h3010540A7FFFA9;  // feat= 9 thr= -0.0233 L= 167 R= 168 cls=2 pur=0.750 leaf=0
        rom[ 167] = 54'h3794000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.868 leaf=1
        rom[ 168] = 54'h2A54000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.660 leaf=1
        rom[ 169] = 54'h3FD0558AAFFF99;  // feat= 9 thr= -0.0269 L= 170 R= 171 cls=2 pur=0.996 leaf=0
        rom[ 170] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 171] = 54'h3F54000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.988 leaf=1
        rom[ 172] = 54'h16E05D0ADFFF8E;  // feat=14 thr= -0.0295 L= 173 R= 186 cls=4 pur=0.355 leaf=0
        rom[ 173] = 54'h31E05A8AEFFF89;  // feat= 9 thr= -0.0314 L= 174 R= 181 cls=4 pur=0.776 leaf=0
        rom[ 174] = 54'h2D205A0AFFFF89;  // feat= 9 thr= -0.0324 L= 175 R= 180 cls=4 pur=0.702 leaf=0
        rom[ 175] = 54'h3060588B0FFF69;  // feat= 9 thr= -0.0396 L= 176 R= 177 cls=4 pur=0.755 leaf=0
        rom[ 176] = 54'h3F24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.983 leaf=1
        rom[ 177] = 54'h2D60598B2FFF7E;  // feat=14 thr= -0.0346 L= 178 R= 179 cls=4 pur=0.705 leaf=0
        rom[ 178] = 54'h29A4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.647 leaf=1
        rom[ 179] = 54'h38E4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.886 leaf=1
        rom[ 180] = 54'h2A4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.659 leaf=1
        rom[ 181] = 54'h36E05B8B6FFF99;  // feat= 9 thr= -0.0258 L= 182 R= 183 cls=4 pur=0.857 leaf=0
        rom[ 182] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 183] = 54'h32205C8B8FFF81;  // feat= 1 thr= -0.0317 L= 184 R= 185 cls=4 pur=0.782 leaf=0
        rom[ 184] = 54'h2E24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.720 leaf=1
        rom[ 185] = 54'h38E4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.888 leaf=1
        rom[ 186] = 54'h14C86C0BBFFFEE;  // feat=14 thr= -0.0091 L= 187 R= 216 cls=1 pur=0.322 leaf=0
        rom[ 187] = 54'h16C8698BCFFFA9;  // feat= 9 thr= -0.0233 L= 188 R= 211 cls=1 pur=0.355 leaf=0
        rom[ 188] = 54'h1788660BDFFFCC;  // feat=12 thr= -0.0148 L= 189 R= 204 cls=1 pur=0.365 leaf=0
        rom[ 189] = 54'h15C8608BEFFF89;  // feat= 9 thr= -0.0332 L= 190 R= 193 cls=1 pur=0.340 leaf=0
        rom[ 190] = 54'h1908600BFFFF79;  // feat= 9 thr= -0.0338 L= 191 R= 192 cls=1 pur=0.392 leaf=0
        rom[ 191] = 54'h1F64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.486 leaf=1
        rom[ 192] = 54'h194C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.395 leaf=1
        rom[ 193] = 54'h14C8628C2FFFCE;  // feat=14 thr= -0.0142 L= 194 R= 197 cls=1 pur=0.325 leaf=0
        rom[ 194] = 54'h15E0620C3FFF89;  // feat= 9 thr= -0.0324 L= 195 R= 196 cls=4 pur=0.339 leaf=0
        rom[ 195] = 54'h118C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.272 leaf=1
        rom[ 196] = 54'h2364000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.552 leaf=1
        rom[ 197] = 54'h1788638C6FFF89;  // feat= 9 thr= -0.0324 L= 198 R= 199 cls=1 pur=0.368 leaf=0
        rom[ 198] = 54'h1954000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.396 leaf=1
        rom[ 199] = 54'h1A88658C8FFF99;  // feat= 9 thr= -0.0284 L= 200 R= 203 cls=1 pur=0.412 leaf=0
        rom[ 200] = 54'h1DC8650C9FFF89;  // feat= 9 thr= -0.0307 L= 201 R= 202 cls=1 pur=0.466 leaf=0
        rom[ 201] = 54'h1E8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.478 leaf=1
        rom[ 202] = 54'h1D0C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.454 leaf=1
        rom[ 203] = 54'h1654000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.348 leaf=1
        rom[ 204] = 54'h1AC8670CDFFF69;  // feat= 9 thr= -0.0396 L= 205 R= 206 cls=1 pur=0.416 leaf=0
        rom[ 205] = 54'h18CC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.386 leaf=1
        rom[ 206] = 54'h1BC8680CFFFF69;  // feat= 9 thr= -0.0396 L= 207 R= 208 cls=1 pur=0.433 leaf=0
        rom[ 207] = 54'h1E54000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.473 leaf=1
        rom[ 208] = 54'h1C88690D1FFF69;  // feat= 9 thr= -0.0396 L= 209 R= 210 cls=1 pur=0.446 leaf=0
        rom[ 209] = 54'h1E8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.478 leaf=1
        rom[ 210] = 54'h1ACC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.417 leaf=1
        rom[ 211] = 54'h1A106B8D4FFF81;  // feat= 1 thr= -0.0316 L= 212 R= 215 cls=2 pur=0.407 leaf=0
        rom[ 212] = 54'h1B886B0D5FFFC9;  // feat= 9 thr= -0.0141 L= 213 R= 214 cls=1 pur=0.428 leaf=0
        rom[ 213] = 54'h1C4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.441 leaf=1
        rom[ 214] = 54'h1A8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.416 leaf=1
        rom[ 215] = 54'h20E4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.511 leaf=1
        rom[ 216] = 54'h3B206D0D9FFF81;  // feat= 1 thr= -0.0316 L= 217 R= 218 cls=4 pur=0.922 leaf=0
        rom[ 217] = 54'h3624000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.843 leaf=1
        rom[ 218] = 54'h3F206E0DBFFF99;  // feat= 9 thr= -0.0258 L= 219 R= 220 cls=4 pur=0.985 leaf=0
        rom[ 219] = 54'h3F24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.986 leaf=1
        rom[ 220] = 54'h3F24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.983 leaf=1
        rom[ 221] = 54'h3FD07E8DEFFFCC;  // feat=12 thr= -0.0148 L= 222 R= 253 cls=2 pur=0.995 leaf=0
        rom[ 222] = 54'h3FD0760DFFFF89;  // feat= 9 thr= -0.0332 L= 223 R= 236 cls=2 pur=0.999 leaf=0
        rom[ 223] = 54'h3FD0748E0FFF79;  // feat= 9 thr= -0.0343 L= 224 R= 233 cls=2 pur=0.997 leaf=0
        rom[ 224] = 54'h3FD0720E1FFF69;  // feat= 9 thr= -0.0371 L= 225 R= 228 cls=2 pur=0.999 leaf=0
        rom[ 225] = 54'h3FD0718E2FFF69;  // feat= 9 thr= -0.0373 L= 226 R= 227 cls=2 pur=0.996 leaf=0
        rom[ 226] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 227] = 54'h3ED4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.981 leaf=1
        rom[ 228] = 54'h3FD0730E5FFF79;  // feat= 9 thr= -0.0357 L= 229 R= 230 cls=2 pur=0.999 leaf=0
        rom[ 229] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 230] = 54'h3FD0740E7FFF79;  // feat= 9 thr= -0.0354 L= 231 R= 232 cls=2 pur=0.998 leaf=0
        rom[ 231] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.996 leaf=1
        rom[ 232] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 233] = 54'h3FD0758EAFFF79;  // feat= 9 thr= -0.0338 L= 234 R= 235 cls=2 pur=0.995 leaf=0
        rom[ 234] = 54'h3F54000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.990 leaf=1
        rom[ 235] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.996 leaf=1
        rom[ 236] = 54'h3FD0790EDFFF89;  // feat= 9 thr= -0.0301 L= 237 R= 242 cls=2 pur=0.999 leaf=0
        rom[ 237] = 54'h3FD0788EEFFF89;  // feat= 9 thr= -0.0314 L= 238 R= 241 cls=2 pur=1.000 leaf=0
        rom[ 238] = 54'h3FD0780EFFFF89;  // feat= 9 thr= -0.0324 L= 239 R= 240 cls=2 pur=1.000 leaf=0
        rom[ 239] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 240] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 241] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 242] = 54'h3FD07B0F3FFF99;  // feat= 9 thr= -0.0258 L= 243 R= 246 cls=2 pur=0.999 leaf=0
        rom[ 243] = 54'h3FD07A8F4FFF99;  // feat= 9 thr= -0.0284 L= 244 R= 245 cls=2 pur=0.996 leaf=0
        rom[ 244] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.995 leaf=1
        rom[ 245] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.997 leaf=1
        rom[ 246] = 54'h3FD07E0F700029;  // feat= 9 thr=  0.0064 L= 247 R= 252 cls=2 pur=1.000 leaf=0
        rom[ 247] = 54'h3FD07C8F8FFFA9;  // feat= 9 thr= -0.0217 L= 248 R= 249 cls=2 pur=1.000 leaf=0
        rom[ 248] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 249] = 54'h3FD07D8FAFFFC9;  // feat= 9 thr= -0.0141 L= 250 R= 251 cls=2 pur=1.000 leaf=0
        rom[ 250] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 251] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 252] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.999 leaf=1
        rom[ 253] = 54'h2F88828FEFFF69;  // feat= 9 thr= -0.0396 L= 254 R= 261 cls=1 pur=0.743 leaf=0
        rom[ 254] = 54'h3308800FFFFF69;  // feat= 9 thr= -0.0396 L= 255 R= 256 cls=1 pur=0.797 leaf=0
        rom[ 255] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 256] = 54'h304881101FFF69;  // feat= 9 thr= -0.0396 L= 257 R= 258 cls=1 pur=0.755 leaf=0
        rom[ 257] = 54'h284C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.627 leaf=1
        rom[ 258] = 54'h344882103FFF69;  // feat= 9 thr= -0.0396 L= 259 R= 260 cls=1 pur=0.818 leaf=0
        rom[ 259] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 260] = 54'h2A8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.662 leaf=1
        rom[ 261] = 54'h27DC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.619 leaf=1
        rom[ 262] = 54'h3A408C107FFF69;  // feat= 9 thr= -0.0396 L= 263 R= 280 cls=0 pur=0.910 leaf=0
        rom[ 263] = 54'h2F488B9080005B;  // feat=11 thr=  0.0183 L= 264 R= 279 cls=1 pur=0.740 leaf=0
        rom[ 264] = 54'h33488B109FFFE4;  // feat= 4 thr= -0.0082 L= 265 R= 278 cls=1 pur=0.801 leaf=0
        rom[ 265] = 54'h28888690AFFE8E;  // feat=14 thr= -0.0956 L= 266 R= 269 cls=1 pur=0.632 leaf=0
        rom[ 266] = 54'h35188610BFFC9B;  // feat=11 thr= -0.2131 L= 267 R= 268 cls=3 pur=0.830 leaf=0
        rom[ 267] = 54'h27DC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.619 leaf=1
        rom[ 268] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 269] = 54'h36888990EFFF69;  // feat= 9 thr= -0.0396 L= 270 R= 275 cls=1 pur=0.852 leaf=0
        rom[ 270] = 54'h3C088910FFFC8B;  // feat=11 thr= -0.2193 L= 271 R= 274 cls=1 pur=0.939 leaf=0
        rom[ 271] = 54'h3F0888910FFF69;  // feat= 9 thr= -0.0396 L= 272 R= 273 cls=1 pur=0.983 leaf=0
        rom[ 272] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 273] = 54'h3C0C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.937 leaf=1
        rom[ 274] = 54'h348C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.822 leaf=1
        rom[ 275] = 54'h21C08A914FFF69;  // feat= 9 thr= -0.0396 L= 276 R= 277 cls=0 pur=0.529 leaf=0
        rom[ 276] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 277] = 54'h2ADC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.667 leaf=1
        rom[ 278] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 279] = 54'h3E9C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.976 leaf=1
        rom[ 280] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 281] = 54'h148A0391AFFFE4;  // feat= 4 thr= -0.0078 L= 282 R=1031 cls=1 pur=0.319 leaf=0
        rom[ 282] = 54'h1660C211BFFF81;  // feat= 1 thr= -0.0312 L= 283 R= 388 cls=4 pur=0.348 leaf=0
        rom[ 283] = 54'h1C089691CFFF81;  // feat= 1 thr= -0.0314 L= 284 R= 301 cls=1 pur=0.439 leaf=0
        rom[ 284] = 54'h3A609611D00015;  // feat= 5 thr=  0.0026 L= 285 R= 300 cls=4 pur=0.909 leaf=0
        rom[ 285] = 54'h3BE08F91EFFF81;  // feat= 1 thr= -0.0315 L= 286 R= 287 cls=4 pur=0.932 leaf=0
        rom[ 286] = 54'h3464000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.817 leaf=1
        rom[ 287] = 54'h3CE094920FFF99;  // feat= 9 thr= -0.0258 L= 288 R= 297 cls=4 pur=0.949 leaf=0
        rom[ 288] = 54'h3BA091121FFF89;  // feat= 9 thr= -0.0332 L= 289 R= 290 cls=4 pur=0.930 leaf=0
        rom[ 289] = 54'h3EE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.980 leaf=1
        rom[ 290] = 54'h3AA093123FFF89;  // feat= 9 thr= -0.0324 L= 291 R= 294 cls=4 pur=0.912 leaf=0
        rom[ 291] = 54'h38A092924FFF81;  // feat= 1 thr= -0.0315 L= 292 R= 293 cls=4 pur=0.883 leaf=0
        rom[ 292] = 54'h3F24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.986 leaf=1
        rom[ 293] = 54'h3224000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.781 leaf=1
        rom[ 294] = 54'h3C60941270009E;  // feat=14 thr=  0.0366 L= 295 R= 296 cls=4 pur=0.941 leaf=0
        rom[ 295] = 54'h3864000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.877 leaf=1
        rom[ 296] = 54'h3F64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.988 leaf=1
        rom[ 297] = 54'h3FE09592AFFF81;  // feat= 1 thr= -0.0314 L= 298 R= 299 cls=4 pur=0.994 leaf=0
        rom[ 298] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 299] = 54'h3F64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.988 leaf=1
        rom[ 300] = 54'h1D8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.461 leaf=1
        rom[ 301] = 54'h1C48AF92E0019E;  // feat=14 thr=  0.0976 L= 302 R= 351 cls=1 pur=0.441 leaf=0
        rom[ 302] = 54'h1788A412F000DE;  // feat=14 thr=  0.0519 L= 303 R= 328 cls=1 pur=0.367 leaf=0
        rom[ 303] = 54'h1B48A393000015;  // feat= 5 thr=  0.0028 L= 304 R= 327 cls=1 pur=0.424 leaf=0
        rom[ 304] = 54'h1BC8A3131FFBF2;  // feat= 2 thr= -0.2543 L= 305 R= 326 cls=1 pur=0.432 leaf=0
        rom[ 305] = 54'h1B8899932FFF69;  // feat= 9 thr= -0.0386 L= 306 R= 307 cls=1 pur=0.429 leaf=0
        rom[ 306] = 54'h3B1C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.923 leaf=1
        rom[ 307] = 54'h1B88A0934FFFA9;  // feat= 9 thr= -0.0217 L= 308 R= 321 cls=1 pur=0.430 leaf=0
        rom[ 308] = 54'h1A889D135FFF79;  // feat= 9 thr= -0.0344 L= 309 R= 314 cls=1 pur=0.416 leaf=0
        rom[ 309] = 54'h1D889C936FFF79;  // feat= 9 thr= -0.0368 L= 310 R= 313 cls=1 pur=0.461 leaf=0
        rom[ 310] = 54'h1CC89C137FFF69;  // feat= 9 thr= -0.0374 L= 311 R= 312 cls=1 pur=0.448 leaf=0
        rom[ 311] = 54'h1E8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.478 leaf=1
        rom[ 312] = 54'h1A8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.416 leaf=1
        rom[ 313] = 54'h1F0C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.483 leaf=1
        rom[ 314] = 54'h1A489F13BFFF89;  // feat= 9 thr= -0.0301 L= 315 R= 318 cls=1 pur=0.411 leaf=0
        rom[ 315] = 54'h1AC89E93CFFF89;  // feat= 9 thr= -0.0324 L= 316 R= 317 cls=1 pur=0.418 leaf=0
        rom[ 316] = 54'h1A4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.412 leaf=1
        rom[ 317] = 54'h1BCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.432 leaf=1
        rom[ 318] = 54'h1A08A013FFFF99;  // feat= 9 thr= -0.0258 L= 319 R= 320 cls=1 pur=0.404 leaf=0
        rom[ 319] = 54'h198C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.398 leaf=1
        rom[ 320] = 54'h1A8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.413 leaf=1
        rom[ 321] = 54'h1DC8A294200029;  // feat= 9 thr=  0.0064 L= 322 R= 325 cls=1 pur=0.464 leaf=0
        rom[ 322] = 54'h1D48A2143FFFC9;  // feat= 9 thr= -0.0141 L= 323 R= 324 cls=1 pur=0.458 leaf=0
        rom[ 323] = 54'h1CCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.451 leaf=1
        rom[ 324] = 54'h21CC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.528 leaf=1
        rom[ 325] = 54'h1F0C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.483 leaf=1
        rom[ 326] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 327] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 328] = 54'h3A20AF14900029;  // feat= 9 thr=  0.0064 L= 329 R= 350 cls=4 pur=0.904 leaf=0
        rom[ 329] = 54'h3C20AA94AFFF89;  // feat= 9 thr= -0.0301 L= 330 R= 341 cls=4 pur=0.938 leaf=0
        rom[ 330] = 54'h3FA0A614BFFF89;  // feat= 9 thr= -0.0332 L= 331 R= 332 cls=4 pur=0.992 leaf=0
        rom[ 331] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 332] = 54'h3F60A814D0011E;  // feat=14 thr=  0.0671 L= 333 R= 336 cls=4 pur=0.990 leaf=0
        rom[ 333] = 54'h3FE0A794EFFF89;  // feat= 9 thr= -0.0324 L= 334 R= 335 cls=4 pur=0.995 leaf=0
        rom[ 334] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 335] = 54'h3FA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.991 leaf=1
        rom[ 336] = 54'h3F20A9151FFF81;  // feat= 1 thr= -0.0313 L= 337 R= 338 cls=4 pur=0.986 leaf=0
        rom[ 337] = 54'h3EA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.977 leaf=1
        rom[ 338] = 54'h3F60AA153FFF81;  // feat= 1 thr= -0.0313 L= 339 R= 340 cls=4 pur=0.989 leaf=0
        rom[ 339] = 54'h3FA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.991 leaf=1
        rom[ 340] = 54'h3F24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.986 leaf=1
        rom[ 341] = 54'h36E0AC956FFF81;  // feat= 1 thr= -0.0313 L= 342 R= 345 cls=4 pur=0.857 leaf=0
        rom[ 342] = 54'h3EA0AC1570011E;  // feat=14 thr=  0.0671 L= 343 R= 344 cls=4 pur=0.977 leaf=0
        rom[ 343] = 54'h3F64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.988 leaf=1
        rom[ 344] = 54'h3DE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.966 leaf=1
        rom[ 345] = 54'h3160AE95A0018E;  // feat=14 thr=  0.0926 L= 346 R= 349 cls=4 pur=0.769 leaf=0
        rom[ 346] = 54'h2D20AE15BFFF99;  // feat= 9 thr= -0.0284 L= 347 R= 348 cls=4 pur=0.702 leaf=0
        rom[ 347] = 54'h26A4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.602 leaf=1
        rom[ 348] = 54'h3124000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.765 leaf=1
        rom[ 349] = 54'h3F24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.983 leaf=1
        rom[ 350] = 54'h24DC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.575 leaf=1
        rom[ 351] = 54'h1C88BA960FFF89;  // feat= 9 thr= -0.0324 L= 352 R= 373 cls=1 pur=0.445 leaf=0
        rom[ 352] = 54'h1C08BA161FFF89;  // feat= 9 thr= -0.0332 L= 353 R= 372 cls=1 pur=0.436 leaf=0
        rom[ 353] = 54'h1AC8B4962FFF69;  // feat= 9 thr= -0.0376 L= 354 R= 361 cls=1 pur=0.419 leaf=0
        rom[ 354] = 54'h1D88B4163FFF69;  // feat= 9 thr= -0.0378 L= 355 R= 360 cls=1 pur=0.462 leaf=0
        rom[ 355] = 54'h1988B2964FFF69;  // feat= 9 thr= -0.0390 L= 356 R= 357 cls=1 pur=0.397 leaf=0
        rom[ 356] = 54'h15CC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.339 leaf=1
        rom[ 357] = 54'h1C08B3966FFF69;  // feat= 9 thr= -0.0381 L= 358 R= 359 cls=1 pur=0.436 leaf=0
        rom[ 358] = 54'h1F4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.488 leaf=1
        rom[ 359] = 54'h198C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.400 leaf=1
        rom[ 360] = 54'h238C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.553 leaf=1
        rom[ 361] = 54'h1AC8B596AFFF69;  // feat= 9 thr= -0.0373 L= 362 R= 363 cls=1 pur=0.417 leaf=0
        rom[ 362] = 54'h159C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.337 leaf=1
        rom[ 363] = 54'h1AC8B696CFFF79;  // feat= 9 thr= -0.0369 L= 364 R= 365 cls=1 pur=0.419 leaf=0
        rom[ 364] = 54'h208C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.507 leaf=1
        rom[ 365] = 54'h1AC8B796EFFF79;  // feat= 9 thr= -0.0363 L= 366 R= 367 cls=1 pur=0.418 leaf=0
        rom[ 366] = 54'h1D9C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.459 leaf=1
        rom[ 367] = 54'h1AC8B9970FFF79;  // feat= 9 thr= -0.0345 L= 368 R= 371 cls=1 pur=0.417 leaf=0
        rom[ 368] = 54'h17C8B9171FFF79;  // feat= 9 thr= -0.0357 L= 369 R= 370 cls=1 pur=0.372 leaf=0
        rom[ 369] = 54'h1A8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.416 leaf=1
        rom[ 370] = 54'h1D1C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.452 leaf=1
        rom[ 371] = 54'h1ACC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.419 leaf=1
        rom[ 372] = 54'h1C4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.440 leaf=1
        rom[ 373] = 54'h1D08BB976FFF89;  // feat= 9 thr= -0.0314 L= 374 R= 375 cls=1 pur=0.452 leaf=0
        rom[ 374] = 54'h1F4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.487 leaf=1
        rom[ 375] = 54'h1C88BD978FFF99;  // feat= 9 thr= -0.0284 L= 376 R= 379 cls=1 pur=0.443 leaf=0
        rom[ 376] = 54'h1B48BD179FFF89;  // feat= 9 thr= -0.0301 L= 377 R= 378 cls=1 pur=0.425 leaf=0
        rom[ 377] = 54'h1B4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.424 leaf=1
        rom[ 378] = 54'h1B4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.425 leaf=1
        rom[ 379] = 54'h1CC8C197C00029;  // feat= 9 thr=  0.0064 L= 380 R= 387 cls=1 pur=0.449 leaf=0
        rom[ 380] = 54'h1CC8BF17DFFF99;  // feat= 9 thr= -0.0258 L= 381 R= 382 cls=1 pur=0.449 leaf=0
        rom[ 381] = 54'h1C4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.442 leaf=1
        rom[ 382] = 54'h1CC8C117FFFFC9;  // feat= 9 thr= -0.0141 L= 383 R= 386 cls=1 pur=0.451 leaf=0
        rom[ 383] = 54'h1CC8C0980FFFA9;  // feat= 9 thr= -0.0217 L= 384 R= 385 cls=1 pur=0.450 leaf=0
        rom[ 384] = 54'h1CCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.449 leaf=1
        rom[ 385] = 54'h1D0C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.451 leaf=1
        rom[ 386] = 54'h1D8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.460 leaf=1
        rom[ 387] = 54'h1D0C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.455 leaf=1
        rom[ 388] = 54'h1EE122185FFF91;  // feat= 1 thr= -0.0283 L= 389 R= 580 cls=4 pur=0.480 leaf=0
        rom[ 389] = 54'h28910D986FFF91;  // feat= 1 thr= -0.0283 L= 390 R= 539 cls=2 pur=0.632 leaf=0
        rom[ 390] = 54'h2960F9187FFB7B;  // feat=11 thr= -0.2839 L= 391 R= 498 cls=4 pur=0.643 leaf=0
        rom[ 391] = 54'h30E0DF98800015;  // feat= 5 thr=  0.0027 L= 392 R= 447 cls=4 pur=0.763 leaf=0
        rom[ 392] = 54'h36A0CF189FFD5E;  // feat=14 thr= -0.1667 L= 393 R= 414 cls=4 pur=0.851 leaf=0
        rom[ 393] = 54'h2958CD98A00015;  // feat= 5 thr=  0.0027 L= 394 R= 411 cls=3 pur=0.645 leaf=0
        rom[ 394] = 54'h2FD8CB18BFFFE4;  // feat= 4 thr= -0.0083 L= 395 R= 406 cls=3 pur=0.745 leaf=0
        rom[ 395] = 54'h19C0C798C00015;  // feat= 5 thr=  0.0026 L= 396 R= 399 cls=0 pur=0.403 leaf=0
        rom[ 396] = 54'h2890C718D00015;  // feat= 5 thr=  0.0026 L= 397 R= 398 cls=2 pur=0.632 leaf=0
        rom[ 397] = 54'h298C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.649 leaf=1
        rom[ 398] = 54'h3794000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.868 leaf=1
        rom[ 399] = 54'h2240C999000015;  // feat= 5 thr=  0.0026 L= 400 R= 403 cls=0 pur=0.533 leaf=0
        rom[ 400] = 54'h2798C919100015;  // feat= 5 thr=  0.0026 L= 401 R= 402 cls=3 pur=0.616 leaf=0
        rom[ 401] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 402] = 54'h2E9C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.728 leaf=1
        rom[ 403] = 54'h2F40CA99400015;  // feat= 5 thr=  0.0026 L= 404 R= 405 cls=0 pur=0.739 leaf=0
        rom[ 404] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 405] = 54'h2644000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=0.598 leaf=1
        rom[ 406] = 54'h3B98CD197FFF69;  // feat= 9 thr= -0.0396 L= 407 R= 410 cls=3 pur=0.929 leaf=0
        rom[ 407] = 54'h3E58CC99800015;  // feat= 5 thr=  0.0027 L= 408 R= 409 cls=3 pur=0.971 leaf=0
        rom[ 408] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 409] = 54'h361C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.844 leaf=1
        rom[ 410] = 54'h2EDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.731 leaf=1
        rom[ 411] = 54'h3488CE99C00015;  // feat= 5 thr=  0.0027 L= 412 R= 413 cls=1 pur=0.822 leaf=0
        rom[ 412] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 413] = 54'h2CCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.697 leaf=1
        rom[ 414] = 54'h37A0DF19FFFFE4;  // feat= 4 thr= -0.0082 L= 415 R= 446 cls=4 pur=0.869 leaf=0
        rom[ 415] = 54'h37E0D79A0FFF91;  // feat= 1 thr= -0.0285 L= 416 R= 431 cls=4 pur=0.872 leaf=0
        rom[ 416] = 54'h3660D41A1FFF81;  // feat= 1 thr= -0.0294 L= 417 R= 424 cls=4 pur=0.849 leaf=0
        rom[ 417] = 54'h3C20D29A2FFF81;  // feat= 1 thr= -0.0307 L= 418 R= 421 cls=4 pur=0.937 leaf=0
        rom[ 418] = 54'h3E20D21A30025E;  // feat=14 thr=  0.1434 L= 419 R= 420 cls=4 pur=0.969 leaf=0
        rom[ 419] = 54'h3CA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.947 leaf=1
        rom[ 420] = 54'h3EE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.981 leaf=1
        rom[ 421] = 54'h39E0D39A6FFF81;  // feat= 1 thr= -0.0307 L= 422 R= 423 cls=4 pur=0.902 leaf=0
        rom[ 422] = 54'h2264000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.536 leaf=1
        rom[ 423] = 54'h3AE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.919 leaf=1
        rom[ 424] = 54'h32E0D61A9FFF91;  // feat= 1 thr= -0.0293 L= 425 R= 428 cls=4 pur=0.791 leaf=0
        rom[ 425] = 54'h1C20D59AAFFF91;  // feat= 1 thr= -0.0293 L= 426 R= 427 cls=4 pur=0.436 leaf=0
        rom[ 426] = 54'h32A4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.789 leaf=1
        rom[ 427] = 54'h23CC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.560 leaf=1
        rom[ 428] = 54'h33E0D71AD00DFE;  // feat=14 thr=  0.8705 L= 429 R= 430 cls=4 pur=0.809 leaf=0
        rom[ 429] = 54'h34A4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.820 leaf=1
        rom[ 430] = 54'h2A24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.657 leaf=1
        rom[ 431] = 54'h39A0DB9B000015;  // feat= 5 thr=  0.0026 L= 432 R= 439 cls=4 pur=0.897 leaf=0
        rom[ 432] = 54'h3D60DA1B100015;  // feat= 5 thr=  0.0026 L= 433 R= 436 cls=4 pur=0.958 leaf=0
        rom[ 433] = 54'h3DE0D99B2FFF91;  // feat= 1 thr= -0.0285 L= 434 R= 435 cls=4 pur=0.967 leaf=0
        rom[ 434] = 54'h3EA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.975 leaf=1
        rom[ 435] = 54'h3CE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.948 leaf=1
        rom[ 436] = 54'h3BA0DB1B500015;  // feat= 5 thr=  0.0026 L= 437 R= 438 cls=4 pur=0.931 leaf=0
        rom[ 437] = 54'h3264000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.784 leaf=1
        rom[ 438] = 54'h3DA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.961 leaf=1
        rom[ 439] = 54'h38E0DD9B800015;  // feat= 5 thr=  0.0026 L= 440 R= 443 cls=4 pur=0.887 leaf=0
        rom[ 440] = 54'h2A20DD1B9FFF69;  // feat= 9 thr= -0.0396 L= 441 R= 442 cls=4 pur=0.654 leaf=0
        rom[ 441] = 54'h3A24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.905 leaf=1
        rom[ 442] = 54'h2364000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.552 leaf=1
        rom[ 443] = 54'h3920DE9BCFFF91;  // feat= 1 thr= -0.0285 L= 444 R= 445 cls=4 pur=0.890 leaf=0
        rom[ 444] = 54'h3864000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.877 leaf=1
        rom[ 445] = 54'h3B24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.922 leaf=1
        rom[ 446] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 447] = 54'h1920EE9C0FFE3E;  // feat=14 thr= -0.1134 L= 448 R= 477 cls=4 pur=0.392 leaf=0
        rom[ 448] = 54'h3220E31C1FFD8E;  // feat=14 thr= -0.1566 L= 449 R= 454 cls=4 pur=0.781 leaf=0
        rom[ 449] = 54'h2100E19C2FFB2B;  // feat=11 thr= -0.3035 L= 450 R= 451 cls=0 pur=0.514 leaf=0
        rom[ 450] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 451] = 54'h2808E29C4FFFEC;  // feat=12 thr= -0.0076 L= 452 R= 453 cls=1 pur=0.624 leaf=0
        rom[ 452] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 453] = 54'h2C1C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.689 leaf=1
        rom[ 454] = 54'h39A0EA1C7FFF91;  // feat= 1 thr= -0.0285 L= 455 R= 468 cls=4 pur=0.899 leaf=0
        rom[ 455] = 54'h3360E69C800015;  // feat= 5 thr=  0.0028 L= 456 R= 461 cls=4 pur=0.803 leaf=0
        rom[ 456] = 54'h2420E61C9FFF91;  // feat= 1 thr= -0.0286 L= 457 R= 460 cls=4 pur=0.564 leaf=0
        rom[ 457] = 54'h2DE0E59CAFFF91;  // feat= 1 thr= -0.0287 L= 458 R= 459 cls=4 pur=0.714 leaf=0
        rom[ 458] = 54'h3A24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.906 leaf=1
        rom[ 459] = 54'h26E4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.606 leaf=1
        rom[ 460] = 54'h2854000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.629 leaf=1
        rom[ 461] = 54'h3EE0E89CE00035;  // feat= 5 thr=  0.0133 L= 462 R= 465 cls=4 pur=0.980 leaf=0
        rom[ 462] = 54'h3FA0E81CF00015;  // feat= 5 thr=  0.0030 L= 463 R= 464 cls=4 pur=0.991 leaf=0
        rom[ 463] = 54'h3DE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.966 leaf=1
        rom[ 464] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.996 leaf=1
        rom[ 465] = 54'h3BE0E99D200045;  // feat= 5 thr=  0.0157 L= 466 R= 467 cls=4 pur=0.935 leaf=0
        rom[ 466] = 54'h3A24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.905 leaf=1
        rom[ 467] = 54'h3D64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.956 leaf=1
        rom[ 468] = 54'h3CE0EB1D500015;  // feat= 5 thr=  0.0027 L= 469 R= 470 cls=4 pur=0.948 leaf=0
        rom[ 469] = 54'h3224000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.782 leaf=1
        rom[ 470] = 54'h3CE0ED1D7FFB7B;  // feat=11 thr= -0.2848 L= 471 R= 474 cls=4 pur=0.950 leaf=0
        rom[ 471] = 54'h3DA0EC9D800025;  // feat= 5 thr=  0.0082 L= 472 R= 473 cls=4 pur=0.960 leaf=0
        rom[ 472] = 54'h3CA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.947 leaf=1
        rom[ 473] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 474] = 54'h3AE0EE1DBFFF91;  // feat= 1 thr= -0.0283 L= 475 R= 476 cls=4 pur=0.916 leaf=0
        rom[ 475] = 54'h3BA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.931 leaf=1
        rom[ 476] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 477] = 54'h1908F79DE00035;  // feat= 5 thr=  0.0107 L= 478 R= 495 cls=1 pur=0.391 leaf=0
        rom[ 478] = 54'h19C8F31DF00015;  // feat= 5 thr=  0.0057 L= 479 R= 486 cls=1 pur=0.404 leaf=0
        rom[ 479] = 54'h1A48F09E0FFF81;  // feat= 1 thr= -0.0301 L= 480 R= 481 cls=1 pur=0.408 leaf=0
        rom[ 480] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 481] = 54'h1A48F19E200015;  // feat= 5 thr=  0.0027 L= 482 R= 483 cls=1 pur=0.411 leaf=0
        rom[ 482] = 54'h248C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.570 leaf=1
        rom[ 483] = 54'h19C8F29E4008AE;  // feat=14 thr=  0.5374 L= 484 R= 485 cls=1 pur=0.402 leaf=0
        rom[ 484] = 54'h198C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.397 leaf=1
        rom[ 485] = 54'h21CC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.527 leaf=1
        rom[ 486] = 54'h1888F61E700025;  // feat= 5 thr=  0.0097 L= 487 R= 492 cls=1 pur=0.381 leaf=0
        rom[ 487] = 54'h1860F59E800025;  // feat= 5 thr=  0.0061 L= 488 R= 491 cls=4 pur=0.379 leaf=0
        rom[ 488] = 54'h18C8F51E900025;  // feat= 5 thr=  0.0059 L= 489 R= 490 cls=1 pur=0.385 leaf=0
        rom[ 489] = 54'h1A0C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.405 leaf=1
        rom[ 490] = 54'h1E9C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.477 leaf=1
        rom[ 491] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 492] = 54'h2008F71EDFFF91;  // feat= 1 thr= -0.0291 L= 493 R= 494 cls=1 pur=0.500 leaf=0
        rom[ 493] = 54'h23CC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.561 leaf=1
        rom[ 494] = 54'h1C8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.444 leaf=1
        rom[ 495] = 54'h26E0F89F0FFFEE;  // feat=14 thr= -0.0066 L= 496 R= 497 cls=4 pur=0.604 leaf=0
        rom[ 496] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 497] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 498] = 54'h2908FB1F3FFFE4;  // feat= 4 thr= -0.0082 L= 499 R= 502 cls=1 pur=0.643 leaf=0
        rom[ 499] = 54'h3C40FA9F4FFB9B;  // feat=11 thr= -0.2768 L= 500 R= 501 cls=0 pur=0.942 leaf=0
        rom[ 500] = 54'h2A8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.662 leaf=1
        rom[ 501] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 502] = 54'h3449031F7FFF91;  // feat= 1 thr= -0.0288 L= 503 R= 518 cls=1 pur=0.816 leaf=0
        rom[ 503] = 54'h3DC8FD9F8FFD3E;  // feat=14 thr= -0.1769 L= 504 R= 507 cls=1 pur=0.964 leaf=0
        rom[ 504] = 54'h2D48FD1F9FFF69;  // feat= 9 thr= -0.0396 L= 505 R= 506 cls=1 pur=0.708 leaf=0
        rom[ 505] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 506] = 54'h2E94000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.728 leaf=1
        rom[ 507] = 54'h3F48FE9FCFFFE4;  // feat= 4 thr= -0.0082 L= 508 R= 509 cls=1 pur=0.986 leaf=0
        rom[ 508] = 54'h324C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.787 leaf=1
        rom[ 509] = 54'h3F49019FEFFBFB;  // feat=11 thr= -0.2522 L= 510 R= 515 cls=1 pur=0.989 leaf=0
        rom[ 510] = 54'h3DC9011FFFFFE4;  // feat= 4 thr= -0.0080 L= 511 R= 514 cls=1 pur=0.966 leaf=0
        rom[ 511] = 54'h3FC900A00FFFE4;  // feat= 4 thr= -0.0081 L= 512 R= 513 cls=1 pur=0.998 leaf=0
        rom[ 512] = 54'h3ACC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.917 leaf=1
        rom[ 513] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 514] = 54'h2BDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.684 leaf=1
        rom[ 515] = 54'h3FC902A0400015;  // feat= 5 thr=  0.0026 L= 516 R= 517 cls=1 pur=1.000 leaf=0
        rom[ 516] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 517] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 518] = 54'h1C890C207FFFE4;  // feat= 4 thr= -0.0081 L= 519 R= 536 cls=1 pur=0.445 leaf=0
        rom[ 519] = 54'h1DC906A08FFE0E;  // feat=14 thr= -0.1261 L= 520 R= 525 cls=1 pur=0.464 leaf=0
        rom[ 520] = 54'h364905209FFF91;  // feat= 1 thr= -0.0285 L= 521 R= 522 cls=1 pur=0.849 leaf=0
        rom[ 521] = 54'h22CC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.541 leaf=1
        rom[ 522] = 54'h3FC90620BFFB8B;  // feat=11 thr= -0.2810 L= 523 R= 524 cls=1 pur=1.000 leaf=0
        rom[ 523] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 524] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 525] = 54'h19C909A0EFFF69;  // feat= 9 thr= -0.0396 L= 526 R= 531 cls=1 pur=0.404 leaf=0
        rom[ 526] = 54'h1B490820F00015;  // feat= 5 thr=  0.0027 L= 527 R= 528 cls=1 pur=0.424 leaf=0
        rom[ 527] = 54'h17D4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.369 leaf=1
        rom[ 528] = 54'h1D090921100015;  // feat= 5 thr=  0.0028 L= 529 R= 530 cls=1 pur=0.454 leaf=0
        rom[ 529] = 54'h1F0C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.483 leaf=1
        rom[ 530] = 54'h1B0C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.423 leaf=1
        rom[ 531] = 54'h19090AA1400015;  // feat= 5 thr=  0.0026 L= 532 R= 533 cls=1 pur=0.390 leaf=0
        rom[ 532] = 54'h178C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.366 leaf=1
        rom[ 533] = 54'h19890BA1600015;  // feat= 5 thr=  0.0026 L= 534 R= 535 cls=1 pur=0.400 leaf=0
        rom[ 534] = 54'h1F8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.491 leaf=1
        rom[ 535] = 54'h188C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.381 leaf=1
        rom[ 536] = 54'h30190D219FFFE4;  // feat= 4 thr= -0.0080 L= 537 R= 538 cls=3 pur=0.749 leaf=0
        rom[ 537] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 538] = 54'h215C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.520 leaf=1
        rom[ 539] = 54'h3FD10FA1CFFFE4;  // feat= 4 thr= -0.0082 L= 540 R= 543 cls=2 pur=0.996 leaf=0
        rom[ 540] = 54'h39E10F21D00015;  // feat= 5 thr=  0.0026 L= 541 R= 542 cls=4 pur=0.901 leaf=0
        rom[ 541] = 54'h3DE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.966 leaf=1
        rom[ 542] = 54'h3524000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.826 leaf=1
        rom[ 543] = 54'h3FD110A2000015;  // feat= 5 thr=  0.0027 L= 544 R= 545 cls=2 pur=0.998 leaf=0
        rom[ 544] = 54'h200C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.498 leaf=1
        rom[ 545] = 54'h3FD118A2200015;  // feat= 5 thr=  0.0027 L= 546 R= 561 cls=2 pur=0.998 leaf=0
        rom[ 546] = 54'h3FD11822300015;  // feat= 5 thr=  0.0027 L= 547 R= 560 cls=2 pur=1.000 leaf=0
        rom[ 547] = 54'h3FD113A2400015;  // feat= 5 thr=  0.0027 L= 548 R= 551 cls=2 pur=0.999 leaf=0
        rom[ 548] = 54'h3FD11322500015;  // feat= 5 thr=  0.0027 L= 549 R= 550 cls=2 pur=1.000 leaf=0
        rom[ 549] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 550] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 551] = 54'h3FD116A2800015;  // feat= 5 thr=  0.0027 L= 552 R= 557 cls=2 pur=0.999 leaf=0
        rom[ 552] = 54'h3FD11622900015;  // feat= 5 thr=  0.0027 L= 553 R= 556 cls=2 pur=0.998 leaf=0
        rom[ 553] = 54'h3FD115A2A00015;  // feat= 5 thr=  0.0027 L= 554 R= 555 cls=2 pur=0.999 leaf=0
        rom[ 554] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.998 leaf=1
        rom[ 555] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.999 leaf=1
        rom[ 556] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.996 leaf=1
        rom[ 557] = 54'h3FD117A2E00015;  // feat= 5 thr=  0.0027 L= 558 R= 559 cls=2 pur=1.000 leaf=0
        rom[ 558] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 559] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.998 leaf=1
        rom[ 560] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 561] = 54'h3FD119A3200015;  // feat= 5 thr=  0.0027 L= 562 R= 563 cls=2 pur=0.996 leaf=0
        rom[ 562] = 54'h3C14000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.937 leaf=1
        rom[ 563] = 54'h3FD11CA3400015;  // feat= 5 thr=  0.0027 L= 564 R= 569 cls=2 pur=0.997 leaf=0
        rom[ 564] = 54'h3F111C23500015;  // feat= 5 thr=  0.0027 L= 565 R= 568 cls=2 pur=0.983 leaf=0
        rom[ 565] = 54'h3FD11BA3600015;  // feat= 5 thr=  0.0027 L= 566 R= 567 cls=2 pur=0.999 leaf=0
        rom[ 566] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 567] = 54'h3F94000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.992 leaf=1
        rom[ 568] = 54'h3C14000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.937 leaf=1
        rom[ 569] = 54'h3FD11FA3A00015;  // feat= 5 thr=  0.0029 L= 570 R= 575 cls=2 pur=0.997 leaf=0
        rom[ 570] = 54'h3FD11E23B00015;  // feat= 5 thr=  0.0027 L= 571 R= 572 cls=2 pur=0.998 leaf=0
        rom[ 571] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 572] = 54'h3FD11F23D00015;  // feat= 5 thr=  0.0027 L= 573 R= 574 cls=2 pur=0.997 leaf=0
        rom[ 573] = 54'h3D54000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.955 leaf=1
        rom[ 574] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.997 leaf=1
        rom[ 575] = 54'h3F5120A4000015;  // feat= 5 thr=  0.0029 L= 576 R= 577 cls=2 pur=0.989 leaf=0
        rom[ 576] = 54'h35D4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.838 leaf=1
        rom[ 577] = 54'h3FD121A4200015;  // feat= 5 thr=  0.0030 L= 578 R= 579 cls=2 pur=0.998 leaf=0
        rom[ 578] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=1.000 leaf=1
        rom[ 579] = 54'h3FD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.996 leaf=1
        rom[ 580] = 54'h2621B4245FFFE4;  // feat= 4 thr= -0.0081 L= 581 R= 872 cls=4 pur=0.592 leaf=0
        rom[ 581] = 54'h1E615BA46FFF91;  // feat= 1 thr= -0.0267 L= 582 R= 695 cls=4 pur=0.472 leaf=0
        rom[ 582] = 54'h346156247FFB7B;  // feat=11 thr= -0.2839 L= 583 R= 684 cls=4 pur=0.818 leaf=0
        rom[ 583] = 54'h37A13BA4800015;  // feat= 5 thr=  0.0026 L= 584 R= 631 cls=4 pur=0.867 leaf=0
        rom[ 584] = 54'h2EE12F2490139E;  // feat=14 thr=  1.2213 L= 585 R= 606 cls=4 pur=0.730 leaf=0
        rom[ 585] = 54'h29A12AA4A0136E;  // feat=14 thr=  1.2111 L= 586 R= 597 cls=4 pur=0.649 leaf=0
        rom[ 586] = 54'h31E12824BFFF91;  // feat= 1 thr= -0.0268 L= 587 R= 592 cls=4 pur=0.778 leaf=0
        rom[ 587] = 54'h35A126A4CFFDBE;  // feat=14 thr= -0.1464 L= 588 R= 589 cls=4 pur=0.836 leaf=0
        rom[ 588] = 54'h391C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.889 leaf=1
        rom[ 589] = 54'h366127A4EFFE9E;  // feat=14 thr= -0.0905 L= 590 R= 591 cls=4 pur=0.846 leaf=0
        rom[ 590] = 54'h29A4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.649 leaf=1
        rom[ 591] = 54'h3864000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.880 leaf=1
        rom[ 592] = 54'h21912A25100015;  // feat= 5 thr=  0.0026 L= 593 R= 596 cls=2 pur=0.522 leaf=0
        rom[ 593] = 54'h23E129A5200015;  // feat= 5 thr=  0.0026 L= 594 R= 595 cls=4 pur=0.559 leaf=0
        rom[ 594] = 54'h2494000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.572 leaf=1
        rom[ 595] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 596] = 54'h2D94000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.711 leaf=1
        rom[ 597] = 54'h1DC92CA56FFF99;  // feat= 9 thr= -0.0281 L= 598 R= 601 cls=1 pur=0.465 leaf=0
        rom[ 598] = 54'h26892C257FFF89;  // feat= 9 thr= -0.0324 L= 599 R= 600 cls=1 pur=0.601 leaf=0
        rom[ 599] = 54'h234C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.549 leaf=1
        rom[ 600] = 54'h2A8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.664 leaf=1
        rom[ 601] = 54'h17492DA5AFFFC9;  // feat= 9 thr= -0.0166 L= 602 R= 603 cls=1 pur=0.364 leaf=0
        rom[ 602] = 54'h161C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.342 leaf=1
        rom[ 603] = 54'h1C892EA5C00029;  // feat= 9 thr=  0.0064 L= 604 R= 605 cls=1 pur=0.446 leaf=0
        rom[ 604] = 54'h1D0C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.452 leaf=1
        rom[ 605] = 54'h1C0C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.439 leaf=1
        rom[ 606] = 54'h39A13625FFFF99;  // feat= 9 thr= -0.0258 L= 607 R= 620 cls=4 pur=0.897 leaf=0
        rom[ 607] = 54'h3C6132A600168E;  // feat=14 thr=  1.4043 L= 608 R= 613 cls=4 pur=0.940 leaf=0
        rom[ 608] = 54'h3AA1322610162E;  // feat=14 thr=  1.3840 L= 609 R= 612 cls=4 pur=0.913 leaf=0
        rom[ 609] = 54'h3BE131A62FFF91;  // feat= 1 thr= -0.0272 L= 610 R= 611 cls=4 pur=0.933 leaf=0
        rom[ 610] = 54'h3A24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.907 leaf=1
        rom[ 611] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.995 leaf=1
        rom[ 612] = 54'h28E4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.635 leaf=1
        rom[ 613] = 54'h3EE134A66017BE;  // feat=14 thr=  1.4806 L= 614 R= 617 cls=4 pur=0.980 leaf=0
        rom[ 614] = 54'h3DA134267FFF89;  // feat= 9 thr= -0.0324 L= 615 R= 616 cls=4 pur=0.960 leaf=0
        rom[ 615] = 54'h3CA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.945 leaf=1
        rom[ 616] = 54'h3F24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.983 leaf=1
        rom[ 617] = 54'h3F6135A6A0180E;  // feat=14 thr=  1.5009 L= 618 R= 619 cls=4 pur=0.990 leaf=0
        rom[ 618] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 619] = 54'h3DA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.960 leaf=1
        rom[ 620] = 54'h32A13A26D016FE;  // feat=14 thr=  1.4323 L= 621 R= 628 cls=4 pur=0.790 leaf=0
        rom[ 621] = 54'h2F6138A6E014DE;  // feat=14 thr=  1.3026 L= 622 R= 625 cls=4 pur=0.740 leaf=0
        rom[ 622] = 54'h34A13826FFFFA9;  // feat= 9 thr= -0.0217 L= 623 R= 624 cls=4 pur=0.820 leaf=0
        rom[ 623] = 54'h39A4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.899 leaf=1
        rom[ 624] = 54'h2DE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.716 leaf=1
        rom[ 625] = 54'h2AA139A72FFF91;  // feat= 1 thr= -0.0271 L= 626 R= 627 cls=4 pur=0.665 leaf=0
        rom[ 626] = 54'h28A4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.634 leaf=1
        rom[ 627] = 54'h2DA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.711 leaf=1
        rom[ 628] = 54'h38613B275FFF91;  // feat= 1 thr= -0.0267 L= 629 R= 630 cls=4 pur=0.881 leaf=0
        rom[ 629] = 54'h3E64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.974 leaf=1
        rom[ 630] = 54'h28E4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.635 leaf=1
        rom[ 631] = 54'h39614AA78FFFAE;  // feat=14 thr= -0.0244 L= 632 R= 661 cls=4 pur=0.895 leaf=0
        rom[ 632] = 54'h37E143279FFF91;  // feat= 1 thr= -0.0270 L= 633 R= 646 cls=4 pur=0.869 leaf=0
        rom[ 633] = 54'h3A2140A7AFFF91;  // feat= 1 thr= -0.0280 L= 634 R= 641 cls=4 pur=0.905 leaf=0
        rom[ 634] = 54'h3C213F27BFFF91;  // feat= 1 thr= -0.0281 L= 635 R= 638 cls=4 pur=0.939 leaf=0
        rom[ 635] = 54'h3BA13EA7CFFF91;  // feat= 1 thr= -0.0282 L= 636 R= 637 cls=4 pur=0.931 leaf=0
        rom[ 636] = 54'h3E24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.969 leaf=1
        rom[ 637] = 54'h3AA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.913 leaf=1
        rom[ 638] = 54'h3FA14027F00015;  // feat= 5 thr=  0.0027 L= 639 R= 640 cls=4 pur=0.992 leaf=0
        rom[ 639] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 640] = 54'h3F24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.985 leaf=1
        rom[ 641] = 54'h37E142A8200035;  // feat= 5 thr=  0.0121 L= 642 R= 645 cls=4 pur=0.869 leaf=0
        rom[ 642] = 54'h37E142283FFEAE;  // feat=14 thr= -0.0854 L= 643 R= 644 cls=4 pur=0.870 leaf=0
        rom[ 643] = 54'h35E4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.840 leaf=1
        rom[ 644] = 54'h39A4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.897 leaf=1
        rom[ 645] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 646] = 54'h206147287FFF91;  // feat= 1 thr= -0.0268 L= 647 R= 654 cls=4 pur=0.504 leaf=0
        rom[ 647] = 54'h27E145A8800015;  // feat= 5 thr=  0.0027 L= 648 R= 651 cls=4 pur=0.623 leaf=0
        rom[ 648] = 54'h2FE14528900015;  // feat= 5 thr=  0.0026 L= 649 R= 650 cls=4 pur=0.748 leaf=0
        rom[ 649] = 54'h2224000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.531 leaf=1
        rom[ 650] = 54'h33A4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.805 leaf=1
        rom[ 651] = 54'h1C6146A8CFFF91;  // feat= 1 thr= -0.0268 L= 652 R= 653 cls=4 pur=0.441 leaf=0
        rom[ 652] = 54'h2B54000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.676 leaf=1
        rom[ 653] = 54'h2DE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.714 leaf=1
        rom[ 654] = 54'h1C114928F00015;  // feat= 5 thr=  0.0028 L= 655 R= 658 cls=2 pur=0.439 leaf=0
        rom[ 655] = 54'h21D148A90FFF91;  // feat= 1 thr= -0.0268 L= 656 R= 657 cls=2 pur=0.526 leaf=0
        rom[ 656] = 54'h211C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.516 leaf=1
        rom[ 657] = 54'h24D4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.575 leaf=1
        rom[ 658] = 54'h32A14A293FFF91;  // feat= 1 thr= -0.0268 L= 659 R= 660 cls=4 pur=0.787 leaf=0
        rom[ 659] = 54'h2FA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.744 leaf=1
        rom[ 660] = 54'h35A4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.836 leaf=1
        rom[ 661] = 54'h3DE150A96FFF91;  // feat= 1 thr= -0.0267 L= 662 R= 673 cls=4 pur=0.963 leaf=0
        rom[ 662] = 54'h3EA14D29700015;  // feat= 5 thr=  0.0026 L= 663 R= 666 cls=4 pur=0.975 leaf=0
        rom[ 663] = 54'h31214CA9800015;  // feat= 5 thr=  0.0026 L= 664 R= 665 cls=4 pur=0.767 leaf=0
        rom[ 664] = 54'h3AA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.915 leaf=1
        rom[ 665] = 54'h2BE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.684 leaf=1
        rom[ 666] = 54'h3EE14F29B00015;  // feat= 5 thr=  0.0027 L= 667 R= 670 cls=4 pur=0.980 leaf=0
        rom[ 667] = 54'h3F614EA9CFFB7B;  // feat=11 thr= -0.2848 L= 668 R= 669 cls=4 pur=0.988 leaf=0
        rom[ 668] = 54'h3EE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.979 leaf=1
        rom[ 669] = 54'h3FA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.992 leaf=1
        rom[ 670] = 54'h3B215029F00015;  // feat= 5 thr=  0.0027 L= 671 R= 672 cls=4 pur=0.922 leaf=0
        rom[ 671] = 54'h2BE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.684 leaf=1
        rom[ 672] = 54'h3D24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.954 leaf=1
        rom[ 673] = 54'h34A154AA200015;  // feat= 5 thr=  0.0027 L= 674 R= 681 cls=4 pur=0.820 leaf=0
        rom[ 674] = 54'h3A61532A3FFF69;  // feat= 9 thr= -0.0396 L= 675 R= 678 cls=4 pur=0.911 leaf=0
        rom[ 675] = 54'h37A152AA400015;  // feat= 5 thr=  0.0026 L= 676 R= 677 cls=4 pur=0.868 leaf=0
        rom[ 676] = 54'h23E4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.557 leaf=1
        rom[ 677] = 54'h3A64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.911 leaf=1
        rom[ 678] = 54'h3E61542A700015;  // feat= 5 thr=  0.0026 L= 679 R= 680 cls=4 pur=0.973 leaf=0
        rom[ 679] = 54'h3BE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.935 leaf=1
        rom[ 680] = 54'h3F64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.990 leaf=1
        rom[ 681] = 54'h242155AAA00015;  // feat= 5 thr=  0.0027 L= 682 R= 683 cls=4 pur=0.562 leaf=0
        rom[ 682] = 54'h3114000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.764 leaf=1
        rom[ 683] = 54'h3F24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.983 leaf=1
        rom[ 684] = 54'h2F01572ADFFFE4;  // feat= 4 thr= -0.0082 L= 685 R= 686 cls=0 pur=0.733 leaf=0
        rom[ 685] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 686] = 54'h2CC95A2AFFFF69;  // feat= 9 thr= -0.0396 L= 687 R= 692 cls=1 pur=0.700 leaf=0
        rom[ 687] = 54'h318959AB0FFBF2;  // feat= 2 thr= -0.2543 L= 688 R= 691 cls=1 pur=0.772 leaf=0
        rom[ 688] = 54'h2B09592B1FFD9B;  // feat=11 thr= -0.1518 L= 689 R= 690 cls=1 pur=0.672 leaf=0
        rom[ 689] = 54'h260C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.593 leaf=1
        rom[ 690] = 54'h2E4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.723 leaf=1
        rom[ 691] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 692] = 54'h23D95B2B5FFF69;  // feat= 9 thr= -0.0396 L= 693 R= 694 cls=3 pur=0.559 leaf=0
        rom[ 693] = 54'h389C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.884 leaf=1
        rom[ 694] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 695] = 54'h182184AB8002AE;  // feat=14 thr=  0.1637 L= 696 R= 777 cls=4 pur=0.376 leaf=0
        rom[ 696] = 54'h2211712B9FFFA1;  // feat= 1 thr= -0.0246 L= 697 R= 738 cls=2 pur=0.530 leaf=0
        rom[ 697] = 54'h2A5164ABAFFF91;  // feat= 1 thr= -0.0258 L= 698 R= 713 cls=2 pur=0.658 leaf=0
        rom[ 698] = 54'h31D1642BBFFFE4;  // feat= 4 thr= -0.0082 L= 699 R= 712 cls=2 pur=0.776 leaf=0
        rom[ 699] = 54'h325161ABC00015;  // feat= 5 thr=  0.0031 L= 700 R= 707 cls=2 pur=0.784 leaf=0
        rom[ 700] = 54'h32D1602BDFFF91;  // feat= 1 thr= -0.0265 L= 701 R= 704 cls=2 pur=0.792 leaf=0
        rom[ 701] = 54'h2DD15FABE00015;  // feat= 5 thr=  0.0026 L= 702 R= 703 cls=2 pur=0.715 leaf=0
        rom[ 702] = 54'h3594000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.836 leaf=1
        rom[ 703] = 54'h2854000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.630 leaf=1
        rom[ 704] = 54'h3391612C1FFF91;  // feat= 1 thr= -0.0259 L= 705 R= 706 cls=2 pur=0.803 leaf=0
        rom[ 705] = 54'h3454000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.816 leaf=1
        rom[ 706] = 54'h2F54000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.739 leaf=1
        rom[ 707] = 54'h136163AC4FFFEC;  // feat=12 thr= -0.0076 L= 708 R= 711 cls=4 pur=0.300 leaf=0
        rom[ 708] = 54'h1999632C500025;  // feat= 5 thr=  0.0067 L= 709 R= 710 cls=3 pur=0.400 leaf=0
        rom[ 709] = 54'h1ADC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.418 leaf=1
        rom[ 710] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 711] = 54'h2EE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.731 leaf=1
        rom[ 712] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 713] = 54'h241169ACA0006E;  // feat=14 thr=  0.0239 L= 714 R= 723 cls=2 pur=0.562 leaf=0
        rom[ 714] = 54'h1F49682CBFFF69;  // feat= 9 thr= -0.0396 L= 715 R= 720 cls=1 pur=0.489 leaf=0
        rom[ 715] = 54'h190967ACCFFD9E;  // feat=14 thr= -0.1540 L= 716 R= 719 cls=1 pur=0.392 leaf=0
        rom[ 716] = 54'h1D49672CD00015;  // feat= 5 thr=  0.0032 L= 717 R= 718 cls=1 pur=0.457 leaf=0
        rom[ 717] = 54'h1D4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.457 leaf=1
        rom[ 718] = 54'h1D4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.457 leaf=1
        rom[ 719] = 54'h3AA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.915 leaf=1
        rom[ 720] = 54'h3989692D1FFFBE;  // feat=14 thr= -0.0193 L= 721 R= 722 cls=1 pur=0.898 leaf=0
        rom[ 721] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 722] = 54'h254C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.580 leaf=1
        rom[ 723] = 54'h25116DAD40012E;  // feat=14 thr=  0.0722 L= 724 R= 731 cls=2 pur=0.579 leaf=0
        rom[ 724] = 54'h27916C2D500015;  // feat= 5 thr=  0.0026 L= 725 R= 728 cls=2 pur=0.619 leaf=0
        rom[ 725] = 54'h29D16BAD600015;  // feat= 5 thr=  0.0026 L= 726 R= 727 cls=2 pur=0.651 leaf=0
        rom[ 726] = 54'h2B54000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.674 leaf=1
        rom[ 727] = 54'h2614000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.595 leaf=1
        rom[ 728] = 54'h25D16D2D9FFF91;  // feat= 1 thr= -0.0256 L= 729 R= 730 cls=2 pur=0.588 leaf=0
        rom[ 729] = 54'h2A54000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.661 leaf=1
        rom[ 730] = 54'h2294000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.541 leaf=1
        rom[ 731] = 54'h20116FADC00015;  // feat= 5 thr=  0.0031 L= 732 R= 735 cls=2 pur=0.500 leaf=0
        rom[ 732] = 54'h20916F2DD00015;  // feat= 5 thr=  0.0026 L= 733 R= 734 cls=2 pur=0.509 leaf=0
        rom[ 733] = 54'h2614000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.595 leaf=1
        rom[ 734] = 54'h1DD4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.465 leaf=1
        rom[ 735] = 54'h2C0970AE000015;  // feat= 5 thr=  0.0032 L= 736 R= 737 cls=1 pur=0.687 leaf=0
        rom[ 736] = 54'h26CC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.607 leaf=1
        rom[ 737] = 54'h3C0C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.937 leaf=1
        rom[ 738] = 54'h1F49802E300051;  // feat= 1 thr=  0.0194 L= 739 R= 768 cls=1 pur=0.487 leaf=0
        rom[ 739] = 54'h210979AE4FFFA1;  // feat= 1 thr= -0.0245 L= 740 R= 755 cls=1 pur=0.515 leaf=0
        rom[ 740] = 54'h27A1762E500015;  // feat= 5 thr=  0.0026 L= 741 R= 748 cls=4 pur=0.619 leaf=0
        rom[ 741] = 54'h21C974AE600015;  // feat= 5 thr=  0.0026 L= 742 R= 745 cls=1 pur=0.526 leaf=0
        rom[ 742] = 54'h2561742E7FFFA1;  // feat= 1 thr= -0.0245 L= 743 R= 744 cls=4 pur=0.583 leaf=0
        rom[ 743] = 54'h230C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.547 leaf=1
        rom[ 744] = 54'h2D24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.703 leaf=1
        rom[ 745] = 54'h2DC975AEA00015;  // feat= 5 thr=  0.0026 L= 746 R= 747 cls=1 pur=0.716 leaf=0
        rom[ 746] = 54'h284C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.627 leaf=1
        rom[ 747] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 748] = 54'h2E61782ED001CE;  // feat=14 thr=  0.1078 L= 749 R= 752 cls=4 pur=0.723 leaf=0
        rom[ 749] = 54'h362177AEE00015;  // feat= 5 thr=  0.0027 L= 750 R= 751 cls=4 pur=0.844 leaf=0
        rom[ 750] = 54'h2BE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.684 leaf=1
        rom[ 751] = 54'h3924000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.891 leaf=1
        rom[ 752] = 54'h1FE1792F1FFFA1;  // feat= 1 thr= -0.0245 L= 753 R= 754 cls=4 pur=0.498 leaf=0
        rom[ 753] = 54'h1D8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.462 leaf=1
        rom[ 754] = 54'h2EE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.730 leaf=1
        rom[ 755] = 54'h22097DAF4FF913;  // feat= 3 thr= -0.4332 L= 756 R= 763 cls=1 pur=0.533 leaf=0
        rom[ 756] = 54'h1C897C2F500031;  // feat= 1 thr=  0.0104 L= 757 R= 760 cls=1 pur=0.446 leaf=0
        rom[ 757] = 54'h1D497BAF6FFF69;  // feat= 9 thr= -0.0396 L= 758 R= 759 cls=1 pur=0.459 leaf=0
        rom[ 758] = 54'h1D4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.458 leaf=1
        rom[ 759] = 54'h1DCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.464 leaf=1
        rom[ 760] = 54'h16497D2F9001CE;  // feat=14 thr=  0.1103 L= 761 R= 762 cls=1 pur=0.349 leaf=0
        rom[ 761] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 762] = 54'h1B4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.424 leaf=1
        rom[ 763] = 54'h2E097FAFCFFB8B;  // feat=11 thr= -0.2810 L= 764 R= 767 cls=1 pur=0.720 leaf=0
        rom[ 764] = 54'h2EC97F2FDFFFA1;  // feat= 1 thr= -0.0240 L= 765 R= 766 cls=1 pur=0.731 leaf=0
        rom[ 765] = 54'h2BCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.684 leaf=1
        rom[ 766] = 54'h370C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.860 leaf=1
        rom[ 767] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 768] = 54'h3061833010021E;  // feat=14 thr=  0.1281 L= 769 R= 774 cls=4 pur=0.753 leaf=0
        rom[ 769] = 54'h3CE181B02FFEDE;  // feat=14 thr= -0.0752 L= 770 R= 771 cls=4 pur=0.949 leaf=0
        rom[ 770] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 771] = 54'h3FE182B04FFF69;  // feat= 9 thr= -0.0396 L= 772 R= 773 cls=4 pur=1.000 leaf=0
        rom[ 772] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 773] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 774] = 54'h2CC98430700015;  // feat= 5 thr=  0.0033 L= 775 R= 776 cls=1 pur=0.698 leaf=0
        rom[ 775] = 54'h294C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.645 leaf=1
        rom[ 776] = 54'h304C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.755 leaf=1
        rom[ 777] = 54'h276198B0AFFF69;  // feat= 9 thr= -0.0386 L= 778 R= 817 cls=4 pur=0.614 leaf=0
        rom[ 778] = 54'h1F218930BFFFA1;  // feat= 1 thr= -0.0247 L= 779 R= 786 cls=4 pur=0.484 leaf=0
        rom[ 779] = 54'h33C187B0CFFFE4;  // feat= 4 thr= -0.0083 L= 780 R= 783 cls=0 pur=0.810 leaf=0
        rom[ 780] = 54'h3FC18730D006CE;  // feat=14 thr=  0.4230 L= 781 R= 782 cls=0 pur=1.000 leaf=0
        rom[ 781] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 782] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 783] = 54'h238988B10FFF91;  // feat= 1 thr= -0.0261 L= 784 R= 785 cls=1 pur=0.556 leaf=0
        rom[ 784] = 54'h254C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.580 leaf=1
        rom[ 785] = 54'h208C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.508 leaf=1
        rom[ 786] = 54'h1FE19131300015;  // feat= 5 thr=  0.0026 L= 787 R= 802 cls=4 pur=0.495 leaf=0
        rom[ 787] = 54'h22098DB14FFB9B;  // feat=11 thr= -0.2781 L= 788 R= 795 cls=1 pur=0.530 leaf=0
        rom[ 788] = 54'h24098C315001C1;  // feat= 1 thr=  0.1082 L= 789 R= 792 cls=1 pur=0.561 leaf=0
        rom[ 789] = 54'h29098BB16FFFB1;  // feat= 1 thr= -0.0196 L= 790 R= 791 cls=1 pur=0.639 leaf=0
        rom[ 790] = 54'h214C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.519 leaf=1
        rom[ 791] = 54'h2E0C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.718 leaf=1
        rom[ 792] = 54'h1F618D319001C1;  // feat= 1 thr=  0.1098 L= 793 R= 794 cls=4 pur=0.488 leaf=0
        rom[ 793] = 54'h3D24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.953 leaf=1
        rom[ 794] = 54'h224C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.534 leaf=1
        rom[ 795] = 54'h2DC18FB1C000A1;  // feat= 1 thr=  0.0399 L= 796 R= 799 cls=0 pur=0.716 leaf=0
        rom[ 796] = 54'h3D898F31DFFFB1;  // feat= 1 thr= -0.0194 L= 797 R= 798 cls=1 pur=0.960 leaf=0
        rom[ 797] = 54'h324C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.787 leaf=1
        rom[ 798] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 799] = 54'h3F0190B2000015;  // feat= 5 thr=  0.0026 L= 800 R= 801 cls=0 pur=0.986 leaf=0
        rom[ 800] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 801] = 54'h3A84000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=0.914 leaf=1
        rom[ 802] = 54'h23219532300F5E;  // feat=14 thr=  0.9569 L= 803 R= 810 cls=4 pur=0.547 leaf=0
        rom[ 803] = 54'h29A193B2400DFE;  // feat=14 thr=  0.8705 L= 804 R= 807 cls=4 pur=0.647 leaf=0
        rom[ 804] = 54'h23A19332500001;  // feat= 1 thr=  0.0012 L= 805 R= 806 cls=4 pur=0.554 leaf=0
        rom[ 805] = 54'h2124000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.514 leaf=1
        rom[ 806] = 54'h3FA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.993 leaf=1
        rom[ 807] = 54'h38A194B28FFFE4;  // feat= 4 thr= -0.0082 L= 808 R= 809 cls=4 pur=0.883 leaf=0
        rom[ 808] = 54'h3924000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.890 leaf=1
        rom[ 809] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 810] = 54'h19619732B00FDE;  // feat=14 thr=  0.9874 L= 811 R= 814 cls=4 pur=0.396 leaf=0
        rom[ 811] = 54'h1BC996B2C00015;  // feat= 5 thr=  0.0041 L= 812 R= 813 cls=1 pur=0.435 leaf=0
        rom[ 812] = 54'h1CCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.450 leaf=1
        rom[ 813] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 814] = 54'h1F219832F00015;  // feat= 5 thr=  0.0041 L= 815 R= 816 cls=4 pur=0.484 leaf=0
        rom[ 815] = 54'h1CE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.450 leaf=1
        rom[ 816] = 54'h3E24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.967 leaf=1
        rom[ 817] = 54'h36A1A4B32FFFA1;  // feat= 1 thr= -0.0241 L= 818 R= 841 cls=4 pur=0.853 leaf=0
        rom[ 818] = 54'h3AE19E333FFFA1;  // feat= 1 thr= -0.0243 L= 819 R= 828 cls=4 pur=0.917 leaf=0
        rom[ 819] = 54'h37E19DB34FFFA1;  // feat= 1 thr= -0.0244 L= 820 R= 827 cls=4 pur=0.872 leaf=0
        rom[ 820] = 54'h38A19C335FFFA1;  // feat= 1 thr= -0.0247 L= 821 R= 824 cls=4 pur=0.882 leaf=0
        rom[ 821] = 54'h39219BB36FFF91;  // feat= 1 thr= -0.0259 L= 822 R= 823 cls=4 pur=0.891 leaf=0
        rom[ 822] = 54'h36A4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.852 leaf=1
        rom[ 823] = 54'h3B24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.922 leaf=1
        rom[ 824] = 54'h33A19D3390225E;  // feat=14 thr=  2.1441 L= 825 R= 826 cls=4 pur=0.804 leaf=0
        rom[ 825] = 54'h1E8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.476 leaf=1
        rom[ 826] = 54'h3764000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.862 leaf=1
        rom[ 827] = 54'h3ACC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.917 leaf=1
        rom[ 828] = 54'h3BA1A133DFFF89;  // feat= 9 thr= -0.0332 L= 829 R= 834 cls=4 pur=0.930 leaf=0
        rom[ 829] = 54'h3AE1A0B3E00045;  // feat= 5 thr=  0.0173 L= 830 R= 833 cls=4 pur=0.918 leaf=0
        rom[ 830] = 54'h3AA1A033F024BE;  // feat=14 thr=  2.2915 L= 831 R= 832 cls=4 pur=0.915 leaf=0
        rom[ 831] = 54'h3D64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.956 leaf=1
        rom[ 832] = 54'h3AA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.914 leaf=1
        rom[ 833] = 54'h3F64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.990 leaf=1
        rom[ 834] = 54'h3C21A3343FFF89;  // feat= 9 thr= -0.0314 L= 835 R= 838 cls=4 pur=0.937 leaf=0
        rom[ 835] = 54'h3DA1A2B44FFF89;  // feat= 9 thr= -0.0324 L= 836 R= 837 cls=4 pur=0.959 leaf=0
        rom[ 836] = 54'h3D64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.956 leaf=1
        rom[ 837] = 54'h3DE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.966 leaf=1
        rom[ 838] = 54'h3BE1A4347FFF99;  // feat= 9 thr= -0.0284 L= 839 R= 840 cls=4 pur=0.933 leaf=0
        rom[ 839] = 54'h3A24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.907 leaf=1
        rom[ 840] = 54'h3C64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.940 leaf=1
        rom[ 841] = 54'h33A1ACB4AFFFB1;  // feat= 1 thr= -0.0210 L= 842 R= 857 cls=4 pur=0.803 leaf=0
        rom[ 842] = 54'h2BA1A934B0282E;  // feat=14 thr=  2.5076 L= 843 R= 850 cls=4 pur=0.678 leaf=0
        rom[ 843] = 54'h3261A7B4C025AE;  // feat=14 thr=  2.3525 L= 844 R= 847 cls=4 pur=0.786 leaf=0
        rom[ 844] = 54'h2261A734D0256E;  // feat=14 thr=  2.3347 L= 845 R= 846 cls=4 pur=0.537 leaf=0
        rom[ 845] = 54'h2D64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.706 leaf=1
        rom[ 846] = 54'h1D4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.456 leaf=1
        rom[ 847] = 54'h3961A8B500267E;  // feat=14 thr=  2.4008 L= 848 R= 849 cls=4 pur=0.895 leaf=0
        rom[ 848] = 54'h36A4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.851 leaf=1
        rom[ 849] = 54'h3DE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.965 leaf=1
        rom[ 850] = 54'h26E1AB3530287E;  // feat=14 thr=  2.5279 L= 851 R= 854 cls=4 pur=0.606 leaf=0
        rom[ 851] = 54'h1ED9AAB54FFF89;  // feat= 9 thr= -0.0327 L= 852 R= 853 cls=3 pur=0.481 leaf=0
        rom[ 852] = 54'h1A0C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.407 leaf=1
        rom[ 853] = 54'h281C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.626 leaf=1
        rom[ 854] = 54'h2A61AC357FFF79;  // feat= 9 thr= -0.0338 L= 855 R= 856 cls=4 pur=0.662 leaf=0
        rom[ 855] = 54'h1B64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.425 leaf=1
        rom[ 856] = 54'h2FA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.744 leaf=1
        rom[ 857] = 54'h37E1B0B5A0530E;  // feat=14 thr=  5.1870 L= 858 R= 865 cls=4 pur=0.873 leaf=0
        rom[ 858] = 54'h39E1AF35BFFFC1;  // feat= 1 thr= -0.0154 L= 859 R= 862 cls=4 pur=0.902 leaf=0
        rom[ 859] = 54'h3861AEB5CFFF79;  // feat= 9 thr= -0.0363 L= 860 R= 861 cls=4 pur=0.879 leaf=0
        rom[ 860] = 54'h2364000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.552 leaf=1
        rom[ 861] = 54'h38A4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.885 leaf=1
        rom[ 862] = 54'h3FA1B035F051CE;  // feat=14 thr=  5.1082 L= 863 R= 864 cls=4 pur=0.993 leaf=0
        rom[ 863] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.997 leaf=1
        rom[ 864] = 54'h3D64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.958 leaf=1
        rom[ 865] = 54'h3161B2B620626E;  // feat=14 thr=  6.1480 L= 866 R= 869 cls=4 pur=0.769 leaf=0
        rom[ 866] = 54'h30C9B2363FFFC1;  // feat= 1 thr= -0.0147 L= 867 R= 868 cls=1 pur=0.764 leaf=0
        rom[ 867] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 868] = 54'h284C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.628 leaf=1
        rom[ 869] = 54'h37E1B3B66FFFE1;  // feat= 1 thr= -0.0092 L= 870 R= 871 cls=4 pur=0.872 leaf=0
        rom[ 870] = 54'h30E4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.762 leaf=1
        rom[ 871] = 54'h3D64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.957 leaf=1
        rom[ 872] = 54'h36A1E9369FFC2B;  // feat=11 thr= -0.2406 L= 873 R= 978 cls=4 pur=0.851 leaf=0
        rom[ 873] = 54'h3861C8B6AFFF91;  // feat= 1 thr= -0.0272 L= 874 R= 913 cls=4 pur=0.881 leaf=0
        rom[ 874] = 54'h2149BF36BFFBAB;  // feat=11 thr= -0.2718 L= 875 R= 894 cls=1 pur=0.518 leaf=0
        rom[ 875] = 54'h36A1B7B6CFFFE4;  // feat= 4 thr= -0.0080 L= 876 R= 879 cls=4 pur=0.850 leaf=0
        rom[ 876] = 54'h3EC9B736DFFE1E;  // feat=14 thr= -0.1210 L= 877 R= 878 cls=1 pur=0.981 leaf=0
        rom[ 877] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 878] = 54'h3ACC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.917 leaf=1
        rom[ 879] = 54'h3AA1BEB70FFF91;  // feat= 1 thr= -0.0274 L= 880 R= 893 cls=4 pur=0.912 leaf=0
        rom[ 880] = 54'h3BA1BC371FFDAE;  // feat=14 thr= -0.1490 L= 881 R= 888 cls=4 pur=0.929 leaf=0
        rom[ 881] = 54'h3DE1BAB72FFF69;  // feat= 9 thr= -0.0396 L= 882 R= 885 cls=4 pur=0.966 leaf=0
        rom[ 882] = 54'h3E61BA37300015;  // feat= 5 thr=  0.0028 L= 883 R= 884 cls=4 pur=0.974 leaf=0
        rom[ 883] = 54'h3DE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.966 leaf=1
        rom[ 884] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 885] = 54'h39E1BBB76FFF69;  // feat= 9 thr= -0.0396 L= 886 R= 887 cls=4 pur=0.901 leaf=0
        rom[ 886] = 54'h2FA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.741 leaf=1
        rom[ 887] = 54'h3BE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.935 leaf=1
        rom[ 888] = 54'h36A1BE37900015;  // feat= 5 thr=  0.0027 L= 889 R= 892 cls=4 pur=0.853 leaf=0
        rom[ 889] = 54'h3861BDB7A00015;  // feat= 5 thr=  0.0027 L= 890 R= 891 cls=4 pur=0.877 leaf=0
        rom[ 890] = 54'h34E4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.822 leaf=1
        rom[ 891] = 54'h3BA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.930 leaf=1
        rom[ 892] = 54'h2CA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.696 leaf=1
        rom[ 893] = 54'h2064000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.505 leaf=1
        rom[ 894] = 54'h3789C037FFFFFC;  // feat=12 thr= -0.0052 L= 895 R= 896 cls=1 pur=0.868 leaf=0
        rom[ 895] = 54'h3214000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.781 leaf=1
        rom[ 896] = 54'h39C9C438100015;  // feat= 5 thr=  0.0027 L= 897 R= 904 cls=1 pur=0.904 leaf=0
        rom[ 897] = 54'h35C9C3B82FFF91;  // feat= 1 thr= -0.0272 L= 898 R= 903 cls=1 pur=0.839 leaf=0
        rom[ 898] = 54'h3709C2383FFE5E;  // feat=14 thr= -0.1057 L= 899 R= 900 cls=1 pur=0.858 leaf=0
        rom[ 899] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 900] = 54'h3589C338500015;  // feat= 5 thr=  0.0027 L= 901 R= 902 cls=1 pur=0.835 leaf=0
        rom[ 901] = 54'h2ECC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.729 leaf=1
        rom[ 902] = 54'h388C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.883 leaf=1
        rom[ 903] = 54'h171C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.358 leaf=1
        rom[ 904] = 54'h3C09C5389FFF91;  // feat= 1 thr= -0.0280 L= 905 R= 906 cls=1 pur=0.937 leaf=0
        rom[ 905] = 54'h324C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.787 leaf=1
        rom[ 906] = 54'h3C49C738B00015;  // feat= 5 thr=  0.0027 L= 907 R= 910 cls=1 pur=0.942 leaf=0
        rom[ 907] = 54'h39C9C6B8C00015;  // feat= 5 thr=  0.0027 L= 908 R= 909 cls=1 pur=0.901 leaf=0
        rom[ 908] = 54'h3A8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.913 leaf=1
        rom[ 909] = 54'h328C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.787 leaf=1
        rom[ 910] = 54'h3D89C838F00015;  // feat= 5 thr=  0.0028 L= 911 R= 912 cls=1 pur=0.962 leaf=0
        rom[ 911] = 54'h3CCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.950 leaf=1
        rom[ 912] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.995 leaf=1
        rom[ 913] = 54'h3A61CDB9200015;  // feat= 5 thr=  0.0026 L= 914 R= 923 cls=4 pur=0.910 leaf=0
        rom[ 914] = 54'h2FC1CB39302DEE;  // feat=14 thr=  2.8660 L= 915 R= 918 cls=0 pur=0.745 leaf=0
        rom[ 915] = 54'h3FC1CAB940040E;  // feat=14 thr=  0.2502 L= 916 R= 917 cls=0 pur=1.000 leaf=0
        rom[ 916] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 917] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 918] = 54'h35C9CD397FFF69;  // feat= 9 thr= -0.0396 L= 919 R= 922 cls=1 pur=0.841 leaf=0
        rom[ 919] = 54'h3AC9CCB9805C2E;  // feat=14 thr=  5.7590 L= 920 R= 921 cls=1 pur=0.917 leaf=0
        rom[ 920] = 54'h348C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.822 leaf=1
        rom[ 921] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 922] = 54'h2B4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.674 leaf=1
        rom[ 923] = 54'h3AE1DDB9CFFBEB;  // feat=11 thr= -0.2572 L= 924 R= 955 cls=4 pur=0.919 leaf=0
        rom[ 924] = 54'h3721D639DFFBAB;  // feat=11 thr= -0.2731 L= 925 R= 940 cls=4 pur=0.859 leaf=0
        rom[ 925] = 54'h3961D2B9E00871;  // feat= 1 thr=  0.5292 L= 926 R= 933 cls=4 pur=0.895 leaf=0
        rom[ 926] = 54'h3A21D139FFFFFC;  // feat=12 thr= -0.0029 L= 927 R= 930 cls=4 pur=0.907 leaf=0
        rom[ 927] = 54'h3461D0BA0FFEEE;  // feat=14 thr= -0.0701 L= 928 R= 929 cls=4 pur=0.818 leaf=0
        rom[ 928] = 54'h3BA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.931 leaf=1
        rom[ 929] = 54'h1A24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.405 leaf=1
        rom[ 930] = 54'h3B21D23A3FFB7B;  // feat=11 thr= -0.2839 L= 931 R= 932 cls=4 pur=0.921 leaf=0
        rom[ 931] = 54'h3D24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.952 leaf=1
        rom[ 932] = 54'h39A4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.898 leaf=1
        rom[ 933] = 54'h3061D4BA605ADE;  // feat=14 thr=  5.6751 L= 934 R= 937 cls=4 pur=0.754 leaf=0
        rom[ 934] = 54'h2161D43A700015;  // feat= 5 thr=  0.0026 L= 935 R= 936 cls=4 pur=0.520 leaf=0
        rom[ 935] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 936] = 54'h2F24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.733 leaf=1
        rom[ 937] = 54'h33A1D5BAA01251;  // feat= 1 thr=  1.1460 L= 938 R= 939 cls=4 pur=0.805 leaf=0
        rom[ 938] = 54'h30E4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.760 leaf=1
        rom[ 939] = 54'h3FA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.991 leaf=1
        rom[ 940] = 54'h22A1DA3ADFFFE4;  // feat= 4 thr= -0.0079 L= 941 R= 948 cls=4 pur=0.540 leaf=0
        rom[ 941] = 54'h3609D8BAEFFF91;  // feat= 1 thr= -0.0265 L= 942 R= 945 cls=1 pur=0.844 leaf=0
        rom[ 942] = 54'h2419D83AFFFE5E;  // feat=14 thr= -0.1057 L= 943 R= 944 cls=3 pur=0.561 leaf=0
        rom[ 943] = 54'h1B0C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.422 leaf=1
        rom[ 944] = 54'h361C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.844 leaf=1
        rom[ 945] = 54'h3A09D9BB20000C;  // feat=12 thr= -0.0005 L= 946 R= 947 cls=1 pur=0.907 leaf=0
        rom[ 946] = 54'h3BCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.932 leaf=1
        rom[ 947] = 54'h1CE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.451 leaf=1
        rom[ 948] = 54'h3421DC3B5FFBCB;  // feat=11 thr= -0.2648 L= 949 R= 952 cls=4 pur=0.811 leaf=0
        rom[ 949] = 54'h2989DBBB6FFFA1;  // feat= 1 thr= -0.0245 L= 950 R= 951 cls=1 pur=0.648 leaf=0
        rom[ 950] = 54'h2A1C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.655 leaf=1
        rom[ 951] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 952] = 54'h38E1DD3B900171;  // feat= 1 thr=  0.0901 L= 953 R= 954 cls=4 pur=0.888 leaf=0
        rom[ 953] = 54'h2EA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.726 leaf=1
        rom[ 954] = 54'h3FA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.991 leaf=1
        rom[ 955] = 54'h3E61E2BBCFFFE4;  // feat= 4 thr= -0.0079 L= 956 R= 965 cls=4 pur=0.973 leaf=0
        rom[ 956] = 54'h3F21E03BDFFFA1;  // feat= 1 thr= -0.0249 L= 957 R= 960 cls=4 pur=0.983 leaf=0
        rom[ 957] = 54'h24C9DFBBEFFF91;  // feat= 1 thr= -0.0267 L= 958 R= 959 cls=1 pur=0.573 leaf=0
        rom[ 958] = 54'h348C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.822 leaf=1
        rom[ 959] = 54'h2F9C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.741 leaf=1
        rom[ 960] = 54'h3F21E13C1FFFE4;  // feat= 4 thr= -0.0080 L= 961 R= 962 cls=4 pur=0.985 leaf=0
        rom[ 961] = 54'h2424000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.563 leaf=1
        rom[ 962] = 54'h3F21E23C3FFAE8;  // feat= 8 thr= -0.3222 L= 963 R= 964 cls=4 pur=0.986 leaf=0
        rom[ 963] = 54'h3F24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.986 leaf=1
        rom[ 964] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[ 965] = 54'h1D89E5BC6FFBFB;  // feat=11 thr= -0.2552 L= 966 R= 971 cls=1 pur=0.459 leaf=0
        rom[ 966] = 54'h3961E53C7FFF69;  // feat= 9 thr= -0.0396 L= 967 R= 970 cls=4 pur=0.895 leaf=0
        rom[ 967] = 54'h3DE1E4BC8FFBEB;  // feat=11 thr= -0.2564 L= 968 R= 969 cls=4 pur=0.967 leaf=0
        rom[ 968] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[ 969] = 54'h38E4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.886 leaf=1
        rom[ 970] = 54'h29E4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.653 leaf=1
        rom[ 971] = 54'h3589E7BCCFFFC1;  // feat= 1 thr= -0.0157 L= 972 R= 975 cls=1 pur=0.835 leaf=0
        rom[ 972] = 54'h27D9E73CDFFFE4;  // feat= 4 thr= -0.0079 L= 973 R= 974 cls=3 pur=0.619 leaf=0
        rom[ 973] = 54'h341C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.813 leaf=1
        rom[ 974] = 54'h254C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.580 leaf=1
        rom[ 975] = 54'h3FC9E8BD000ABE;  // feat=14 thr=  0.6696 L= 976 R= 977 cls=1 pur=1.000 leaf=0
        rom[ 976] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 977] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[ 978] = 54'h2489FA3D3FFFA1;  // feat= 1 thr= -0.0254 L= 979 R=1012 cls=1 pur=0.572 leaf=0
        rom[ 979] = 54'h2359EEBD4FFF91;  // feat= 1 thr= -0.0264 L= 980 R= 989 cls=3 pur=0.552 leaf=0
        rom[ 980] = 54'h32D9EB3D5FFFE4;  // feat= 4 thr= -0.0079 L= 981 R= 982 cls=3 pur=0.794 leaf=0
        rom[ 981] = 54'h224C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.535 leaf=1
        rom[ 982] = 54'h3899ED3D7FFFE4;  // feat= 4 thr= -0.0078 L= 983 R= 986 cls=3 pur=0.884 leaf=0
        rom[ 983] = 54'h2F99ECBD8FFFE4;  // feat= 4 thr= -0.0078 L= 984 R= 985 cls=3 pur=0.743 leaf=0
        rom[ 984] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 985] = 54'h254C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.580 leaf=1
        rom[ 986] = 54'h3D59EE3DBFFFAE;  // feat=14 thr= -0.0244 L= 987 R= 988 cls=3 pur=0.956 leaf=0
        rom[ 987] = 54'h341C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.813 leaf=1
        rom[ 988] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 989] = 54'h1E49F5BDEFFC8B;  // feat=11 thr= -0.2189 L= 990 R=1003 cls=1 pur=0.474 leaf=0
        rom[ 990] = 54'h2719F33DFFFF69;  // feat= 9 thr= -0.0396 L= 991 R= 998 cls=3 pur=0.610 leaf=0
        rom[ 991] = 54'h2D59F0BE000015;  // feat= 5 thr=  0.0026 L= 992 R= 993 cls=3 pur=0.706 leaf=0
        rom[ 992] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[ 993] = 54'h2619F1BE2FFC3B;  // feat=11 thr= -0.2381 L= 994 R= 995 cls=3 pur=0.595 leaf=0
        rom[ 994] = 54'h324C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.787 leaf=1
        rom[ 995] = 54'h2A59F2BE4FFFE4;  // feat= 4 thr= -0.0079 L= 996 R= 997 cls=3 pur=0.661 leaf=0
        rom[ 996] = 54'h2CCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.697 leaf=1
        rom[ 997] = 54'h31DC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.776 leaf=1
        rom[ 998] = 54'h2689F53E70002E;  // feat=14 thr=  0.0061 L= 999 R=1002 cls=1 pur=0.600 leaf=0
        rom[ 999] = 54'h23D9F4BE80000E;  // feat=14 thr=  0.0010 L=1000 R=1001 cls=3 pur=0.559 leaf=0
        rom[1000] = 54'h2CCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.697 leaf=1
        rom[1001] = 54'h361C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.844 leaf=1
        rom[1002] = 54'h378C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.866 leaf=1
        rom[1003] = 54'h2449F9BECFFF91;  // feat= 1 thr= -0.0259 L=1004 R=1011 cls=1 pur=0.565 leaf=0
        rom[1004] = 54'h29C9F73EDFFF69;  // feat= 9 thr= -0.0396 L=1005 R=1006 cls=1 pur=0.651 leaf=0
        rom[1005] = 54'h1C8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.446 leaf=1
        rom[1006] = 54'h3189F93EF00015;  // feat= 5 thr=  0.0026 L=1007 R=1010 cls=1 pur=0.774 leaf=0
        rom[1007] = 54'h2C49F8BF0FFFE4;  // feat= 4 thr= -0.0078 L=1008 R=1009 cls=1 pur=0.691 leaf=0
        rom[1008] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1009] = 54'h274C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.612 leaf=1
        rom[1010] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1011] = 54'h22DC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.543 leaf=1
        rom[1012] = 54'h3489FC3F5FFC8B;  // feat=11 thr= -0.2168 L=1013 R=1016 cls=1 pur=0.821 leaf=0
        rom[1013] = 54'h3D89FBBF600015;  // feat= 5 thr=  0.0027 L=1014 R=1015 cls=1 pur=0.961 leaf=0
        rom[1014] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1015] = 54'h2CCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.697 leaf=1
        rom[1016] = 54'h2C4A023F9FFF5B;  // feat=11 thr= -0.0430 L=1017 R=1028 cls=1 pur=0.692 leaf=0
        rom[1017] = 54'h3089FEBFA0026E;  // feat=14 thr=  0.1485 L=1018 R=1021 cls=1 pur=0.759 leaf=0
        rom[1018] = 54'h20D9FE3FBFFFA1;  // feat= 1 thr= -0.0251 L=1019 R=1020 cls=3 pur=0.514 leaf=0
        rom[1019] = 54'h27DC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.619 leaf=1
        rom[1020] = 54'h244C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.566 leaf=1
        rom[1021] = 54'h3609FFBFE00015;  // feat= 5 thr=  0.0026 L=1022 R=1023 cls=1 pur=0.844 leaf=0
        rom[1022] = 54'h26CC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.606 leaf=1
        rom[1023] = 54'h3A8A01C0001A9E;  // feat=14 thr=  1.6585 L=1024 R=1027 cls=1 pur=0.916 leaf=0
        rom[1024] = 54'h3F8A014010030E;  // feat=14 thr=  0.1892 L=1025 R=1026 cls=1 pur=0.994 leaf=0
        rom[1025] = 54'h3E8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.978 leaf=1
        rom[1026] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1027] = 54'h254C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.580 leaf=1
        rom[1028] = 54'h215A03405FFFE4;  // feat= 4 thr= -0.0080 L=1029 R=1030 cls=3 pur=0.520 leaf=0
        rom[1029] = 54'h27DC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.619 leaf=1
        rom[1030] = 54'h224C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.535 leaf=1
        rom[1031] = 54'h2ACAE8C08FFF69;  // feat= 9 thr= -0.0396 L=1032 R=1489 cls=1 pur=0.666 leaf=0
        rom[1032] = 54'h308A57409FFFB1;  // feat= 1 thr= -0.0208 L=1033 R=1198 cls=1 pur=0.757 leaf=0
        rom[1033] = 54'h364A07C0AFFF81;  // feat= 1 thr= -0.0301 L=1034 R=1039 cls=1 pur=0.846 leaf=0
        rom[1034] = 54'h3D820640B00015;  // feat= 5 thr=  0.0027 L=1035 R=1036 cls=0 pur=0.963 leaf=0
        rom[1035] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1036] = 54'h31020740D00015;  // feat= 5 thr=  0.0027 L=1037 R=1038 cls=0 pur=0.764 leaf=0
        rom[1037] = 54'h354C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.832 leaf=1
        rom[1038] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1039] = 54'h368A26C10FFFAE;  // feat=14 thr= -0.0244 L=1040 R=1101 cls=1 pur=0.853 leaf=0
        rom[1040] = 54'h3C0A1141100015;  // feat= 5 thr=  0.0026 L=1041 R=1058 cls=1 pur=0.938 leaf=0
        rom[1041] = 54'h32CA09C12FFF91;  // feat= 1 thr= -0.0292 L=1042 R=1043 cls=1 pur=0.792 leaf=0
        rom[1042] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1043] = 54'h3C8A0AC1400015;  // feat= 5 thr=  0.0026 L=1044 R=1045 cls=1 pur=0.944 leaf=0
        rom[1044] = 54'h201C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.501 leaf=1
        rom[1045] = 54'h3D4A0BC16FFF91;  // feat= 1 thr= -0.0285 L=1046 R=1047 cls=1 pur=0.959 leaf=0
        rom[1046] = 54'h264C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.596 leaf=1
        rom[1047] = 54'h3E0A0EC18009EB;  // feat=11 thr=  0.6190 L=1048 R=1053 cls=1 pur=0.967 leaf=0
        rom[1048] = 54'h3F4A0D419FFF91;  // feat= 1 thr= -0.0255 L=1049 R=1050 cls=1 pur=0.987 leaf=0
        rom[1049] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1050] = 54'h3B4A0E41BFFFA1;  // feat= 1 thr= -0.0249 L=1051 R=1052 cls=1 pur=0.925 leaf=0
        rom[1051] = 54'h2D8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.711 leaf=1
        rom[1052] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1053] = 54'h3B8A10C1E00064;  // feat= 4 thr=  0.0239 L=1054 R=1057 cls=1 pur=0.930 leaf=0
        rom[1054] = 54'h37CA1041FFFFA1;  // feat= 1 thr= -0.0248 L=1055 R=1056 cls=1 pur=0.871 leaf=0
        rom[1055] = 54'h3C8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.946 leaf=1
        rom[1056] = 54'h254C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.580 leaf=1
        rom[1057] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1058] = 54'h3C8A2642300015;  // feat= 5 thr=  0.0039 L=1059 R=1100 cls=1 pur=0.947 leaf=0
        rom[1059] = 54'h3CCA1FC2400ADB;  // feat=11 thr=  0.6740 L=1060 R=1087 cls=1 pur=0.948 leaf=0
        rom[1060] = 54'h3D0A18425FFBEB;  // feat=11 thr= -0.2581 L=1061 R=1072 cls=1 pur=0.953 leaf=0
        rom[1061] = 54'h3FCA16C26FFFE4;  // feat= 4 thr= -0.0074 L=1062 R=1069 cls=1 pur=0.995 leaf=0
        rom[1062] = 54'h3FCA15427FFBDB;  // feat=11 thr= -0.2623 L=1063 R=1066 cls=1 pur=0.998 leaf=0
        rom[1063] = 54'h3E0A14C28FFFE4;  // feat= 4 thr= -0.0074 L=1064 R=1065 cls=1 pur=0.968 leaf=0
        rom[1064] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1065] = 54'h308C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.756 leaf=1
        rom[1066] = 54'h3FCA1642BFFE0E;  // feat=14 thr= -0.1261 L=1067 R=1068 cls=1 pur=1.000 leaf=0
        rom[1067] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1068] = 54'h3E4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.974 leaf=1
        rom[1069] = 54'h370A17C2EFFF69;  // feat= 9 thr= -0.0396 L=1070 R=1071 cls=1 pur=0.859 leaf=0
        rom[1070] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1071] = 54'h205C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.504 leaf=1
        rom[1072] = 54'h3BCA1C431FFCBB;  // feat=11 thr= -0.2072 L=1073 R=1080 cls=1 pur=0.933 leaf=0
        rom[1073] = 54'h2D4A1AC32FFFA1;  // feat= 1 thr= -0.0245 L=1074 R=1077 cls=1 pur=0.708 leaf=0
        rom[1074] = 54'h30CA1A433FFF7E;  // feat=14 thr= -0.0346 L=1075 R=1076 cls=1 pur=0.762 leaf=0
        rom[1075] = 54'h36CC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.855 leaf=1
        rom[1076] = 54'h220C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.532 leaf=1
        rom[1077] = 54'h215A1BC36FFFA1;  // feat= 1 thr= -0.0237 L=1078 R=1079 cls=3 pur=0.520 leaf=0
        rom[1078] = 54'h2EDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.731 leaf=1
        rom[1079] = 54'h324C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.787 leaf=1
        rom[1080] = 54'h3C4A1E439FFFFC;  // feat=12 thr= -0.0029 L=1081 R=1084 cls=1 pur=0.940 leaf=0
        rom[1081] = 54'h3F8A1DC3AFFF91;  // feat= 1 thr= -0.0289 L=1082 R=1083 cls=1 pur=0.991 leaf=0
        rom[1082] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.999 leaf=1
        rom[1083] = 54'h3C4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.943 leaf=1
        rom[1084] = 54'h3ACA1F43DFFF81;  // feat= 1 thr= -0.0294 L=1085 R=1086 cls=1 pur=0.919 leaf=0
        rom[1085] = 54'h234C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.552 leaf=1
        rom[1086] = 54'h3C4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.941 leaf=1
        rom[1087] = 54'h2F0A24C4000114;  // feat= 4 thr=  0.0673 L=1088 R=1097 cls=1 pur=0.736 leaf=0
        rom[1088] = 54'h320A2144100ADB;  // feat=11 thr=  0.6748 L=1089 R=1090 cls=1 pur=0.782 leaf=0
        rom[1089] = 54'h254C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.584 leaf=1
        rom[1090] = 54'h344A234430017C;  // feat=12 thr=  0.0912 L=1091 R=1094 cls=1 pur=0.817 leaf=0
        rom[1091] = 54'h2ECA22C44000C4;  // feat= 4 thr=  0.0456 L=1092 R=1093 cls=1 pur=0.731 leaf=0
        rom[1092] = 54'h37CC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.872 leaf=1
        rom[1093] = 54'h361C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.844 leaf=1
        rom[1094] = 54'h3F8A2444700114;  // feat= 4 thr=  0.0664 L=1095 R=1096 cls=1 pur=0.992 leaf=0
        rom[1095] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1096] = 54'h3E0C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.967 leaf=1
        rom[1097] = 54'h215A25C4A00BBB;  // feat=11 thr=  0.7290 L=1098 R=1099 cls=3 pur=0.520 leaf=0
        rom[1098] = 54'h341C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.813 leaf=1
        rom[1099] = 54'h324C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.787 leaf=1
        rom[1100] = 54'h2CE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.698 leaf=1
        rom[1101] = 54'h31CA47C4EFFE9B;  // feat=11 thr= -0.0888 L=1102 R=1167 cls=1 pur=0.779 leaf=0
        rom[1102] = 54'h2CCA4444F0000C;  // feat=12 thr= -0.0005 L=1103 R=1160 cls=1 pur=0.699 leaf=0
        rom[1103] = 54'h2D4A37C50000DE;  // feat=14 thr=  0.0519 L=1104 R=1135 cls=1 pur=0.707 leaf=0
        rom[1104] = 54'h2E0A30451FFFE4;  // feat= 4 thr= -0.0076 L=1105 R=1120 cls=1 pur=0.718 leaf=0
        rom[1105] = 54'h2A8A2CC52FFF91;  // feat= 1 thr= -0.0264 L=1106 R=1113 cls=1 pur=0.664 leaf=0
        rom[1106] = 54'h218A2B453FFD0B;  // feat=11 thr= -0.1889 L=1107 R=1110 cls=1 pur=0.523 leaf=0
        rom[1107] = 54'h1E1A2AC5400015;  // feat= 5 thr=  0.0027 L=1108 R=1109 cls=3 pur=0.470 leaf=0
        rom[1108] = 54'h260C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.592 leaf=1
        rom[1109] = 54'h239C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.555 leaf=1
        rom[1110] = 54'h3D0A2C45700015;  // feat= 5 thr=  0.0027 L=1111 R=1112 cls=1 pur=0.955 leaf=0
        rom[1111] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1112] = 54'h324C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.787 leaf=1
        rom[1113] = 54'h2BCA2EC5A00015;  // feat= 5 thr=  0.0026 L=1114 R=1117 cls=1 pur=0.683 leaf=0
        rom[1114] = 54'h270A2E45B00015;  // feat= 5 thr=  0.0026 L=1115 R=1116 cls=1 pur=0.609 leaf=0
        rom[1115] = 54'h2C4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.690 leaf=1
        rom[1116] = 54'h1914000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.391 leaf=1
        rom[1117] = 54'h2D0A2FC5EFFFE4;  // feat= 4 thr= -0.0077 L=1118 R=1119 cls=1 pur=0.703 leaf=0
        rom[1118] = 54'h304C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.753 leaf=1
        rom[1119] = 54'h2A8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.662 leaf=1
        rom[1120] = 54'h33CA34461FFE2B;  // feat=11 thr= -0.1155 L=1121 R=1128 cls=1 pur=0.807 leaf=0
        rom[1121] = 54'h354A32C62FFFE4;  // feat= 4 thr= -0.0074 L=1122 R=1125 cls=1 pur=0.831 leaf=0
        rom[1122] = 54'h328A32463FFFE4;  // feat= 4 thr= -0.0075 L=1123 R=1124 cls=1 pur=0.790 leaf=0
        rom[1123] = 54'h360C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.843 leaf=1
        rom[1124] = 54'h2F4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.739 leaf=1
        rom[1125] = 54'h3BCA33C66FFF91;  // feat= 1 thr= -0.0260 L=1126 R=1127 cls=1 pur=0.932 leaf=0
        rom[1126] = 54'h3E8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.978 leaf=1
        rom[1127] = 54'h364C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.848 leaf=1
        rom[1128] = 54'h2B0A3646900015;  // feat= 5 thr=  0.0027 L=1129 R=1132 cls=1 pur=0.673 leaf=0
        rom[1129] = 54'h230A35C6AFFFE4;  // feat= 4 thr= -0.0073 L=1130 R=1131 cls=1 pur=0.547 leaf=0
        rom[1130] = 54'h299C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.649 leaf=1
        rom[1131] = 54'h2A4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.659 leaf=1
        rom[1132] = 54'h308A3746DFFF69;  // feat= 9 thr= -0.0396 L=1133 R=1134 cls=1 pur=0.756 leaf=0
        rom[1133] = 54'h22CC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.542 leaf=1
        rom[1134] = 54'h374C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.863 leaf=1
        rom[1135] = 54'h294A3DC70FFCEB;  // feat=11 thr= -0.1964 L=1136 R=1147 cls=1 pur=0.646 leaf=0
        rom[1136] = 54'h35CA3C471FFFA1;  // feat= 1 thr= -0.0233 L=1137 R=1144 cls=1 pur=0.840 leaf=0
        rom[1137] = 54'h308A3AC72FFFA1;  // feat= 1 thr= -0.0234 L=1138 R=1141 cls=1 pur=0.759 leaf=0
        rom[1138] = 54'h350A3A473FFF69;  // feat= 9 thr= -0.0396 L=1139 R=1140 cls=1 pur=0.828 leaf=0
        rom[1139] = 54'h3BCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.933 leaf=1
        rom[1140] = 54'h23CC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.559 leaf=1
        rom[1141] = 54'h2A1A3BC76FFFE4;  // feat= 4 thr= -0.0077 L=1142 R=1143 cls=3 pur=0.655 leaf=0
        rom[1142] = 54'h324C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.787 leaf=1
        rom[1143] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[1144] = 54'h3E8A3D479FFCCB;  // feat=11 thr= -0.2035 L=1145 R=1146 cls=1 pur=0.977 leaf=0
        rom[1145] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1146] = 54'h384C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.881 leaf=1
        rom[1147] = 54'h20CA41C7CFFFA1;  // feat= 1 thr= -0.0228 L=1148 R=1155 cls=1 pur=0.513 leaf=0
        rom[1148] = 54'h221A4047DFFE2B;  // feat=11 thr= -0.1184 L=1149 R=1152 cls=3 pur=0.532 leaf=0
        rom[1149] = 54'h1E5A3FC7E00015;  // feat= 5 thr=  0.0026 L=1150 R=1151 cls=3 pur=0.474 leaf=0
        rom[1150] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1151] = 54'h205C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.505 leaf=1
        rom[1152] = 54'h385A41481FFFE4;  // feat= 4 thr= -0.0072 L=1153 R=1154 cls=3 pur=0.879 leaf=0
        rom[1153] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[1154] = 54'h2C5C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.692 leaf=1
        rom[1155] = 54'h2B4A43C84FFFB1;  // feat= 1 thr= -0.0212 L=1156 R=1159 cls=1 pur=0.677 leaf=0
        rom[1156] = 54'h2F0A434850044E;  // feat=14 thr=  0.2654 L=1157 R=1158 cls=1 pur=0.736 leaf=0
        rom[1157] = 54'h328C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.788 leaf=1
        rom[1158] = 54'h295C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.644 leaf=1
        rom[1159] = 54'h379C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.867 leaf=1
        rom[1160] = 54'h29A246489FFFE4;  // feat= 4 thr= -0.0076 L=1161 R=1164 cls=4 pur=0.647 leaf=0
        rom[1161] = 54'h3E6245C8AFFFA1;  // feat= 1 thr= -0.0224 L=1162 R=1163 cls=4 pur=0.974 leaf=0
        rom[1162] = 54'h3D64000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.956 leaf=1
        rom[1163] = 54'h3F24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.986 leaf=1
        rom[1164] = 54'h2F824748D0001C;  // feat=12 thr=  0.0043 L=1165 R=1166 cls=0 pur=0.740 leaf=0
        rom[1165] = 54'h1C1C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.436 leaf=1
        rom[1166] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1167] = 54'h38CA55C90003FE;  // feat=14 thr=  0.2476 L=1168 R=1195 cls=1 pur=0.886 leaf=0
        rom[1168] = 54'h390A554910007C;  // feat=12 thr=  0.0257 L=1169 R=1194 cls=1 pur=0.892 leaf=0
        rom[1169] = 54'h394A4DC92FFFE4;  // feat= 4 thr= -0.0061 L=1170 R=1179 cls=1 pur=0.894 leaf=0
        rom[1170] = 54'h358A4D493FFFE4;  // feat= 4 thr= -0.0061 L=1171 R=1178 cls=1 pur=0.837 leaf=0
        rom[1171] = 54'h360A4BC94FFFE4;  // feat= 4 thr= -0.0062 L=1172 R=1175 cls=1 pur=0.845 leaf=0
        rom[1172] = 54'h36CA4B495002FE;  // feat=14 thr=  0.1841 L=1173 R=1174 cls=1 pur=0.857 leaf=0
        rom[1173] = 54'h374C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.865 leaf=1
        rom[1174] = 54'h280C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.624 leaf=1
        rom[1175] = 54'h2C4A4CC98FFFE4;  // feat= 4 thr= -0.0061 L=1176 R=1177 cls=1 pur=0.693 leaf=0
        rom[1176] = 54'h289C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.634 leaf=1
        rom[1177] = 54'h3C4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.940 leaf=1
        rom[1178] = 54'h1D54000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.458 leaf=1
        rom[1179] = 54'h3ACA51C9C0010B;  // feat=11 thr=  0.0629 L=1180 R=1187 cls=1 pur=0.918 leaf=0
        rom[1180] = 54'h3ECA5049DFFFCB;  // feat=11 thr= -0.0155 L=1181 R=1184 cls=1 pur=0.979 leaf=0
        rom[1181] = 54'h3A8A4FC9EFFF91;  // feat= 1 thr= -0.0265 L=1182 R=1183 cls=1 pur=0.914 leaf=0
        rom[1182] = 54'h344C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.818 leaf=1
        rom[1183] = 54'h3DCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.966 leaf=1
        rom[1184] = 54'h3FCA514A1FFFE4;  // feat= 4 thr= -0.0060 L=1185 R=1186 cls=1 pur=0.999 leaf=0
        rom[1185] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.997 leaf=1
        rom[1186] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1187] = 54'h39CA53CA4002BE;  // feat=14 thr=  0.1688 L=1188 R=1191 cls=1 pur=0.901 leaf=0
        rom[1188] = 54'h3A0A534A5FFF69;  // feat= 9 thr= -0.0396 L=1189 R=1190 cls=1 pur=0.907 leaf=0
        rom[1189] = 54'h3A8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.914 leaf=1
        rom[1190] = 54'h2FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.747 leaf=1
        rom[1191] = 54'h1F4A54CA8FFFA1;  // feat= 1 thr= -0.0215 L=1192 R=1193 cls=1 pur=0.489 leaf=0
        rom[1192] = 54'h265C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.597 leaf=1
        rom[1193] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1194] = 54'h2F9C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.741 leaf=1
        rom[1195] = 54'h349A56CAC0005B;  // feat=11 thr=  0.0179 L=1196 R=1197 cls=3 pur=0.821 leaf=0
        rom[1196] = 54'h205C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.504 leaf=1
        rom[1197] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[1198] = 54'h28CA9F4AF0044E;  // feat=14 thr=  0.2654 L=1199 R=1342 cls=1 pur=0.638 leaf=0
        rom[1199] = 54'h1D4A7ACB00075B;  // feat=11 thr=  0.4572 L=1200 R=1269 cls=1 pur=0.456 leaf=0
        rom[1200] = 54'h28C26F4B1FFFE4;  // feat= 4 thr= -0.0063 L=1201 R=1246 cls=0 pur=0.637 leaf=0
        rom[1201] = 54'h184A68CB200015;  // feat= 5 thr=  0.0036 L=1202 R=1233 cls=1 pur=0.378 leaf=0
        rom[1202] = 54'h1ECA614B30016E;  // feat=14 thr=  0.0849 L=1203 R=1218 cls=1 pur=0.481 leaf=0
        rom[1203] = 54'h2E825CCB4FFC1B;  // feat=11 thr= -0.2464 L=1204 R=1209 cls=0 pur=0.728 leaf=0
        rom[1204] = 54'h324A5C4B50006C;  // feat=12 thr=  0.0233 L=1205 R=1208 cls=1 pur=0.787 leaf=0
        rom[1205] = 54'h3B8A5BCB6FFFE4;  // feat= 4 thr= -0.0075 L=1206 R=1207 cls=1 pur=0.931 leaf=0
        rom[1206] = 54'h2ECC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.729 leaf=1
        rom[1207] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1208] = 54'h2B1C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.670 leaf=1
        rom[1209] = 54'h3A425DCBAFFEEE;  // feat=14 thr= -0.0701 L=1210 R=1211 cls=0 pur=0.908 leaf=0
        rom[1210] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1211] = 54'h3D025FCBC00015;  // feat= 5 thr=  0.0028 L=1212 R=1215 cls=0 pur=0.952 leaf=0
        rom[1212] = 54'h3E825F4BDFFC6B;  // feat=11 thr= -0.2252 L=1213 R=1214 cls=0 pur=0.978 leaf=0
        rom[1213] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1214] = 54'h3784000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=0.867 leaf=1
        rom[1215] = 54'h298260CC000015;  // feat= 5 thr=  0.0028 L=1216 R=1217 cls=0 pur=0.649 leaf=0
        rom[1216] = 54'h254C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.581 leaf=1
        rom[1217] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1218] = 54'h2D0A674C30003C;  // feat=12 thr=  0.0114 L=1219 R=1230 cls=1 pur=0.701 leaf=0
        rom[1219] = 54'h2F4A65CC4FFFE4;  // feat= 4 thr= -0.0071 L=1220 R=1227 cls=1 pur=0.738 leaf=0
        rom[1220] = 54'h2ACA644C5FFC7B;  // feat=11 thr= -0.2226 L=1221 R=1224 cls=1 pur=0.667 leaf=0
        rom[1221] = 54'h328A63CC6FFBFB;  // feat=11 thr= -0.2539 L=1222 R=1223 cls=1 pur=0.789 leaf=0
        rom[1222] = 54'h25CC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.592 leaf=1
        rom[1223] = 54'h364C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.847 leaf=1
        rom[1224] = 54'h2BDA654C900015;  // feat= 5 thr=  0.0026 L=1225 R=1226 cls=3 pur=0.684 leaf=0
        rom[1225] = 54'h2F0C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.734 leaf=1
        rom[1226] = 54'h369C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.853 leaf=1
        rom[1227] = 54'h3E0A66CCC0036E;  // feat=14 thr=  0.2095 L=1228 R=1229 cls=1 pur=0.968 leaf=0
        rom[1228] = 54'h324C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.787 leaf=1
        rom[1229] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1230] = 54'h2A5A684CFFFF69;  // feat= 9 thr= -0.0396 L=1231 R=1232 cls=3 pur=0.661 leaf=0
        rom[1231] = 54'h324C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.787 leaf=1
        rom[1232] = 54'h399C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.897 leaf=1
        rom[1233] = 54'h36A26DCD2FFCDB;  // feat=11 thr= -0.2001 L=1234 R=1243 cls=4 pur=0.852 leaf=0
        rom[1234] = 54'h3D226A4D3FFFE4;  // feat= 4 thr= -0.0077 L=1235 R=1236 cls=4 pur=0.955 leaf=0
        rom[1235] = 54'h2D8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.712 leaf=1
        rom[1236] = 54'h3EE26D4D500015;  // feat= 5 thr=  0.0049 L=1237 R=1242 cls=4 pur=0.981 leaf=0
        rom[1237] = 54'h3F626CCD6FFFE4;  // feat= 4 thr= -0.0072 L=1238 R=1241 cls=4 pur=0.988 leaf=0
        rom[1238] = 54'h3FA26C4D7FFBAB;  // feat=11 thr= -0.2752 L=1239 R=1240 cls=4 pur=0.993 leaf=0
        rom[1239] = 54'h3A24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.905 leaf=1
        rom[1240] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.997 leaf=1
        rom[1241] = 54'h3224000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.782 leaf=1
        rom[1242] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1243] = 54'h3FCA6ECDCFFCEB;  // feat=11 thr= -0.1960 L=1244 R=1245 cls=1 pur=1.000 leaf=0
        rom[1244] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1245] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1246] = 54'h3BC2714DF0001C;  // feat=12 thr=  0.0043 L=1247 R=1250 cls=0 pur=0.932 leaf=0
        rom[1247] = 54'h324A70CE00029E;  // feat=14 thr=  0.1587 L=1248 R=1249 cls=1 pur=0.787 leaf=0
        rom[1248] = 54'h254C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.580 leaf=1
        rom[1249] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1250] = 54'h3CC2724E3FFBF2;  // feat= 2 thr= -0.2543 L=1251 R=1252 cls=0 pur=0.950 leaf=0
        rom[1251] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1252] = 54'h3D82784E50028B;  // feat=11 thr=  0.1550 L=1253 R=1264 cls=0 pur=0.960 leaf=0
        rom[1253] = 54'h3F0275CE600015;  // feat= 5 thr=  0.0027 L=1254 R=1259 cls=0 pur=0.984 leaf=0
        rom[1254] = 54'h3F82754E7FFFE4;  // feat= 4 thr= -0.0061 L=1255 R=1258 cls=0 pur=0.992 leaf=0
        rom[1255] = 54'h3C0274CE800015;  // feat= 5 thr=  0.0027 L=1256 R=1257 cls=0 pur=0.936 leaf=0
        rom[1256] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1257] = 54'h210C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.514 leaf=1
        rom[1258] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1259] = 54'h33C276CECFFFD1;  // feat= 1 thr= -0.0117 L=1260 R=1261 cls=0 pur=0.808 leaf=0
        rom[1260] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1261] = 54'h228A77CEE0000E;  // feat=14 thr= -0.0015 L=1262 R=1263 cls=1 pur=0.539 leaf=0
        rom[1262] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1263] = 54'h2C0C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.689 leaf=1
        rom[1264] = 54'h2A82794F10008E;  // feat=14 thr=  0.0315 L=1265 R=1266 cls=0 pur=0.664 leaf=0
        rom[1265] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1266] = 54'h3ACA7A4F300015;  // feat= 5 thr=  0.0027 L=1267 R=1268 cls=1 pur=0.917 leaf=0
        rom[1267] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1268] = 54'h324C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.787 leaf=1
        rom[1269] = 54'h2E8A99CF600101;  // feat= 1 thr=  0.0641 L=1270 R=1331 cls=1 pur=0.727 leaf=0
        rom[1270] = 54'h358A924F700C9B;  // feat=11 thr=  0.7845 L=1271 R=1316 cls=1 pur=0.836 leaf=0
        rom[1271] = 54'h378A87CF8FFDBE;  // feat=14 thr= -0.1464 L=1272 R=1295 cls=1 pur=0.868 leaf=0
        rom[1272] = 54'h3B0A824F900C2B;  // feat=11 thr=  0.7590 L=1273 R=1284 cls=1 pur=0.920 leaf=0
        rom[1273] = 54'h3C8A7FCFA00244;  // feat= 4 thr=  0.1421 L=1274 R=1279 cls=1 pur=0.947 leaf=0
        rom[1274] = 54'h3B4A7F4FB003DC;  // feat=12 thr=  0.2364 L=1275 R=1278 cls=1 pur=0.925 leaf=0
        rom[1275] = 54'h3DCA7ECFC00A2B;  // feat=11 thr=  0.6323 L=1276 R=1277 cls=1 pur=0.966 leaf=0
        rom[1276] = 54'h3A4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.910 leaf=1
        rom[1277] = 54'h3F8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.993 leaf=1
        rom[1278] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[1279] = 54'h3E8A80D00FFD8E;  // feat=14 thr= -0.1566 L=1280 R=1281 cls=1 pur=0.978 leaf=0
        rom[1280] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1281] = 54'h380A81D02FFFD1;  // feat= 1 thr= -0.0111 L=1282 R=1283 cls=1 pur=0.875 leaf=0
        rom[1282] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1283] = 54'h254C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.584 leaf=1
        rom[1284] = 54'h330A86505FFD7E;  // feat=14 thr= -0.1617 L=1285 R=1292 cls=1 pur=0.798 leaf=0
        rom[1285] = 54'h380A84D06FFF69;  // feat= 9 thr= -0.0396 L=1286 R=1289 cls=1 pur=0.877 leaf=0
        rom[1286] = 54'h3D0A8450700021;  // feat= 1 thr=  0.0096 L=1287 R=1288 cls=1 pur=0.952 leaf=0
        rom[1287] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1288] = 54'h2B4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.674 leaf=1
        rom[1289] = 54'h318A85D0A00015;  // feat= 5 thr=  0.0026 L=1290 R=1291 cls=1 pur=0.772 leaf=0
        rom[1290] = 54'h3C4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.940 leaf=1
        rom[1291] = 54'h215C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.520 leaf=1
        rom[1292] = 54'h200A8750DFFF69;  // feat= 9 thr= -0.0396 L=1293 R=1294 cls=1 pur=0.498 leaf=0
        rom[1293] = 54'h25A4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.587 leaf=1
        rom[1294] = 54'h2F0C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.734 leaf=1
        rom[1295] = 54'h304A8FD10FFF69;  // feat= 9 thr= -0.0396 L=1296 R=1311 cls=1 pur=0.754 leaf=0
        rom[1296] = 54'h338A8C511FFFC1;  // feat= 1 thr= -0.0138 L=1297 R=1304 cls=1 pur=0.803 leaf=0
        rom[1297] = 54'h2C8A8AD120039C;  // feat=12 thr=  0.2209 L=1298 R=1301 cls=1 pur=0.693 leaf=0
        rom[1298] = 54'h2D8A8A513FFF69;  // feat= 9 thr= -0.0396 L=1299 R=1300 cls=1 pur=0.711 leaf=0
        rom[1299] = 54'h31CC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.779 leaf=1
        rom[1300] = 54'h27DC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.619 leaf=1
        rom[1301] = 54'h250A8BD1600C1B;  // feat=11 thr=  0.7536 L=1302 R=1303 cls=1 pur=0.580 leaf=0
        rom[1302] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1303] = 54'h2FA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.744 leaf=1
        rom[1304] = 54'h3ACA8E519FFFF1;  // feat= 1 thr= -0.0043 L=1305 R=1308 cls=1 pur=0.919 leaf=0
        rom[1305] = 54'h3E4A8DD1A00234;  // feat= 4 thr=  0.1359 L=1306 R=1307 cls=1 pur=0.972 leaf=0
        rom[1306] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.995 leaf=1
        rom[1307] = 54'h298C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.648 leaf=1
        rom[1308] = 54'h25428F51D00015;  // feat= 5 thr=  0.0027 L=1309 R=1310 cls=0 pur=0.584 leaf=0
        rom[1309] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1310] = 54'h234C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.552 leaf=1
        rom[1311] = 54'h2CDA91D20FFFE1;  // feat= 1 thr= -0.0063 L=1312 R=1315 cls=3 pur=0.698 leaf=0
        rom[1312] = 54'h32DA9152100BEB;  // feat=11 thr=  0.7436 L=1313 R=1314 cls=3 pur=0.792 leaf=0
        rom[1313] = 54'h3F1C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.985 leaf=1
        rom[1314] = 54'h215C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.520 leaf=1
        rom[1315] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1316] = 54'h24CA93525FFFD1;  // feat= 1 thr= -0.0122 L=1317 R=1318 cls=1 pur=0.574 leaf=0
        rom[1317] = 54'h2FA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.744 leaf=1
        rom[1318] = 54'h26CA9552700414;  // feat= 4 thr=  0.2537 L=1319 R=1322 cls=1 pur=0.606 leaf=0
        rom[1319] = 54'h3ACA94D28FFF69;  // feat= 9 thr= -0.0396 L=1320 R=1321 cls=1 pur=0.917 leaf=0
        rom[1320] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1321] = 54'h30CC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.763 leaf=1
        rom[1322] = 54'h1CCA9952BFFD8E;  // feat=14 thr= -0.1566 L=1323 R=1330 cls=1 pur=0.448 leaf=0
        rom[1323] = 54'h21CA97D2C00804;  // feat= 4 thr=  0.5001 L=1324 R=1327 cls=1 pur=0.526 leaf=0
        rom[1324] = 54'h19E29752D00CEB;  // feat=11 thr=  0.8061 L=1325 R=1326 cls=4 pur=0.404 leaf=0
        rom[1325] = 54'h1C8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.444 leaf=1
        rom[1326] = 54'h2F24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.736 leaf=1
        rom[1327] = 54'h2C4A98D30FFD0E;  // feat=14 thr= -0.1871 L=1328 R=1329 cls=1 pur=0.691 leaf=0
        rom[1328] = 54'h295C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.644 leaf=1
        rom[1329] = 54'h378C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.866 leaf=1
        rom[1330] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[1331] = 54'h2CC29AD3401B2C;  // feat=12 thr=  1.6945 L=1332 R=1333 cls=0 pur=0.701 leaf=0
        rom[1332] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1333] = 54'h188A9CD3601F24;  // feat= 4 thr=  1.9454 L=1334 R=1337 cls=1 pur=0.382 leaf=0
        rom[1334] = 54'h3A4A9C53700CCB;  // feat=11 thr=  0.7978 L=1335 R=1336 cls=1 pur=0.910 leaf=0
        rom[1335] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1336] = 54'h324C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.787 leaf=1
        rom[1337] = 54'h1E5A9DD3A00015;  // feat= 5 thr=  0.0027 L=1338 R=1339 cls=3 pur=0.473 leaf=0
        rom[1338] = 54'h389C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.884 leaf=1
        rom[1339] = 54'h20529ED3CFFF69;  // feat= 9 thr= -0.0396 L=1340 R=1341 cls=2 pur=0.505 leaf=0
        rom[1340] = 54'h25DC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.591 leaf=1
        rom[1341] = 54'h3194000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=2 pur=0.772 leaf=1
        rom[1342] = 54'h2F8AB753FFFFE4;  // feat= 4 thr= -0.0075 L=1343 R=1390 cls=1 pur=0.744 leaf=0
        rom[1343] = 54'h2422A9D400000C;  // feat=12 thr=  0.0019 L=1344 R=1363 cls=4 pur=0.561 leaf=0
        rom[1344] = 54'h2CCAA8541FFFE4;  // feat= 4 thr= -0.0076 L=1345 R=1360 cls=1 pur=0.698 leaf=0
        rom[1345] = 54'h34CAA4D4200015;  // feat= 5 thr=  0.0027 L=1346 R=1353 cls=1 pur=0.825 leaf=0
        rom[1346] = 54'h380AA2543FFFE4;  // feat= 4 thr= -0.0078 L=1347 R=1348 cls=1 pur=0.876 leaf=0
        rom[1347] = 54'h2B4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.674 leaf=1
        rom[1348] = 54'h3A4AA45450467E;  // feat=14 thr=  4.4041 L=1349 R=1352 cls=1 pur=0.911 leaf=0
        rom[1349] = 54'h3D8AA3D46FFFE4;  // feat= 4 thr= -0.0078 L=1350 R=1351 cls=1 pur=0.961 leaf=0
        rom[1350] = 54'h364C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.847 leaf=1
        rom[1351] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1352] = 54'h2B4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.674 leaf=1
        rom[1353] = 54'h308AA7D4A01D0E;  // feat=14 thr=  1.8111 L=1354 R=1359 cls=1 pur=0.760 leaf=0
        rom[1354] = 54'h37CAA654BFFFE4;  // feat= 4 thr= -0.0078 L=1355 R=1356 cls=1 pur=0.871 leaf=0
        rom[1355] = 54'h254C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.580 leaf=1
        rom[1356] = 54'h3C8AA754DFFC5B;  // feat=11 thr= -0.2289 L=1357 R=1358 cls=1 pur=0.946 leaf=0
        rom[1357] = 54'h324C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.787 leaf=1
        rom[1358] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1359] = 54'h2BDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.684 leaf=1
        rom[1360] = 54'h3FDAA9551FFFE4;  // feat= 4 thr= -0.0075 L=1361 R=1362 cls=3 pur=1.000 leaf=0
        rom[1361] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[1362] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[1363] = 54'h3062ABD54FFFE1;  // feat= 1 thr= -0.0059 L=1364 R=1367 cls=4 pur=0.754 leaf=0
        rom[1364] = 54'h20CAAB555FFFE4;  // feat= 4 thr= -0.0077 L=1365 R=1366 cls=1 pur=0.513 leaf=0
        rom[1365] = 54'h2F0C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.734 leaf=1
        rom[1366] = 54'h2EDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.731 leaf=1
        rom[1367] = 54'h33E2B0D580004C;  // feat=12 thr=  0.0138 L=1368 R=1377 cls=4 pur=0.810 leaf=0
        rom[1368] = 54'h25E2AF55900015;  // feat= 5 thr=  0.0027 L=1369 R=1374 cls=4 pur=0.591 leaf=0
        rom[1369] = 54'h345AAED5A044AE;  // feat=14 thr=  4.2871 L=1370 R=1373 cls=3 pur=0.815 leaf=0
        rom[1370] = 54'h3B1AAE55BFFF69;  // feat= 9 thr= -0.0396 L=1371 R=1372 cls=3 pur=0.923 leaf=0
        rom[1371] = 54'h341C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.813 leaf=1
        rom[1372] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[1373] = 54'h1FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.496 leaf=1
        rom[1374] = 54'h3B22B055F01B8E;  // feat=14 thr=  1.7195 L=1375 R=1376 cls=4 pur=0.921 leaf=0
        rom[1375] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[1376] = 54'h2FA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.744 leaf=1
        rom[1377] = 54'h3762B5D62FFFE4;  // feat= 4 thr= -0.0075 L=1378 R=1387 cls=4 pur=0.865 leaf=0
        rom[1378] = 54'h3922B256300015;  // feat= 5 thr=  0.0026 L=1379 R=1380 cls=4 pur=0.890 leaf=0
        rom[1379] = 54'h1E8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.476 leaf=1
        rom[1380] = 54'h39E2B456501C61;  // feat= 1 thr=  1.7734 L=1381 R=1384 cls=4 pur=0.902 leaf=0
        rom[1381] = 54'h3B62B3D66061EE;  // feat=14 thr=  6.1175 L=1382 R=1383 cls=4 pur=0.925 leaf=0
        rom[1382] = 54'h3CA4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.945 leaf=1
        rom[1383] = 54'h3324000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.797 leaf=1
        rom[1384] = 54'h33A2B5569FFF69;  // feat= 9 thr= -0.0396 L=1385 R=1386 cls=4 pur=0.804 leaf=0
        rom[1385] = 54'h208C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.508 leaf=1
        rom[1386] = 54'h3B24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.920 leaf=1
        rom[1387] = 54'h2162B6D6C02341;  // feat= 1 thr=  2.2012 L=1388 R=1389 cls=4 pur=0.518 leaf=0
        rom[1388] = 54'h2B4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.674 leaf=1
        rom[1389] = 54'h2F24000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.734 leaf=1
        rom[1390] = 54'h32CACC56FFFFE4;  // feat= 4 thr= -0.0068 L=1391 R=1432 cls=1 pur=0.793 leaf=0
        rom[1391] = 54'h374AC2D7001DF1;  // feat= 1 thr=  1.8707 L=1392 R=1413 cls=1 pur=0.864 leaf=0
        rom[1392] = 54'h398AC2571FFAE8;  // feat= 8 thr= -0.3222 L=1393 R=1412 cls=1 pur=0.900 leaf=0
        rom[1393] = 54'h3A4AC0D72FFF69;  // feat= 9 thr= -0.0396 L=1394 R=1409 cls=1 pur=0.909 leaf=0
        rom[1394] = 54'h3A8ABD57302D8E;  // feat=14 thr=  2.8432 L=1395 R=1402 cls=1 pur=0.913 leaf=0
        rom[1395] = 54'h364ABBD7400211;  // feat= 1 thr=  0.1279 L=1396 R=1399 cls=1 pur=0.849 leaf=0
        rom[1396] = 54'h384ABB575000C1;  // feat= 1 thr=  0.0481 L=1397 R=1398 cls=1 pur=0.880 leaf=0
        rom[1397] = 54'h36CC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.856 leaf=1
        rom[1398] = 54'h3D8C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.961 leaf=1
        rom[1399] = 54'h22DABCD780293E;  // feat=14 thr=  2.5737 L=1400 R=1401 cls=3 pur=0.543 leaf=0
        rom[1400] = 54'h331C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.797 leaf=1
        rom[1401] = 54'h324C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.787 leaf=1
        rom[1402] = 54'h3E4ABF57B00015;  // feat= 5 thr=  0.0026 L=1403 R=1406 cls=1 pur=0.972 leaf=0
        rom[1403] = 54'h3C4ABED7CFFFE4;  // feat= 4 thr= -0.0071 L=1404 R=1405 cls=1 pur=0.942 leaf=0
        rom[1404] = 54'h3B0C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.920 leaf=1
        rom[1405] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.999 leaf=1
        rom[1406] = 54'h3F4AC057FFFFE4;  // feat= 4 thr= -0.0074 L=1407 R=1408 cls=1 pur=0.987 leaf=0
        rom[1407] = 54'h2CCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.697 leaf=1
        rom[1408] = 54'h3F4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.990 leaf=1
        rom[1409] = 54'h3942C1D82FFF69;  // feat= 9 thr= -0.0396 L=1410 R=1411 cls=0 pur=0.893 leaf=0
        rom[1410] = 54'h2ADC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.667 leaf=1
        rom[1411] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1412] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[1413] = 54'h181AC6D86FFB8B;  // feat=11 thr= -0.2823 L=1414 R=1421 cls=3 pur=0.373 leaf=0
        rom[1414] = 54'h1F1AC558700015;  // feat= 5 thr=  0.0026 L=1415 R=1418 cls=3 pur=0.486 leaf=0
        rom[1415] = 54'h3F9AC4D8802AF1;  // feat= 1 thr=  2.6828 L=1416 R=1417 cls=3 pur=0.991 leaf=0
        rom[1416] = 54'h3E9C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.976 leaf=1
        rom[1417] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[1418] = 54'h3662C658B02BE1;  // feat= 1 thr=  2.7403 L=1419 R=1420 cls=4 pur=0.849 leaf=0
        rom[1419] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[1420] = 54'h27A4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.617 leaf=1
        rom[1421] = 54'h1ACACBD8E05B5E;  // feat=14 thr=  5.7082 L=1422 R=1431 cls=1 pur=0.418 leaf=0
        rom[1422] = 54'h188ACA58F00015;  // feat= 5 thr=  0.0027 L=1423 R=1428 cls=1 pur=0.382 leaf=0
        rom[1423] = 54'h18DAC8D90FFAE8;  // feat= 8 thr= -0.3222 L=1424 R=1425 cls=3 pur=0.386 leaf=0
        rom[1424] = 54'h19DC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.403 leaf=1
        rom[1425] = 54'h181AC9D9200015;  // feat= 5 thr=  0.0027 L=1426 R=1427 cls=3 pur=0.376 leaf=0
        rom[1426] = 54'h184C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.379 leaf=1
        rom[1427] = 54'h191C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.391 leaf=1
        rom[1428] = 54'h210ACB595FFAE8;  // feat= 8 thr= -0.3222 L=1429 R=1430 cls=1 pur=0.514 leaf=0
        rom[1429] = 54'h200C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.500 leaf=1
        rom[1430] = 54'h254C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.580 leaf=1
        rom[1431] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1432] = 54'h268AD8599FFFE4;  // feat= 4 thr= -0.0065 L=1433 R=1456 cls=1 pur=0.602 leaf=0
        rom[1433] = 54'h2102D3D9A0009C;  // feat=12 thr=  0.0352 L=1434 R=1447 cls=0 pur=0.515 leaf=0
        rom[1434] = 54'h2CC2D059BFFC6B;  // feat=11 thr= -0.2268 L=1435 R=1440 cls=0 pur=0.697 leaf=0
        rom[1435] = 54'h3F82CFD9CFFFE4;  // feat= 4 thr= -0.0068 L=1436 R=1439 cls=0 pur=0.992 leaf=0
        rom[1436] = 54'h3602CF59D00011;  // feat= 1 thr=  0.0053 L=1437 R=1438 cls=0 pur=0.846 leaf=0
        rom[1437] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1438] = 54'h2ADC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.667 leaf=1
        rom[1439] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1440] = 54'h2E8AD15A10047E;  // feat=14 thr=  0.2781 L=1441 R=1442 cls=1 pur=0.728 leaf=0
        rom[1441] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[1442] = 54'h368AD35A3021CE;  // feat=14 thr=  2.1085 L=1443 R=1446 cls=1 pur=0.851 leaf=0
        rom[1443] = 54'h39CAD2DA400015;  // feat= 5 thr=  0.0027 L=1444 R=1445 cls=1 pur=0.904 leaf=0
        rom[1444] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.996 leaf=1
        rom[1445] = 54'h298C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.648 leaf=1
        rom[1446] = 54'h27DC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.619 leaf=1
        rom[1447] = 54'h374AD6DA805BAE;  // feat=14 thr=  5.7260 L=1448 R=1453 cls=1 pur=0.864 leaf=0
        rom[1448] = 54'h2C4AD65A901FE1;  // feat= 1 thr=  1.9938 L=1449 R=1452 cls=1 pur=0.691 leaf=0
        rom[1449] = 54'h3C0AD5DAAFFF69;  // feat= 9 thr= -0.0396 L=1450 R=1451 cls=1 pur=0.937 leaf=0
        rom[1450] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1451] = 54'h324C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.787 leaf=1
        rom[1452] = 54'h379C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.867 leaf=1
        rom[1453] = 54'h3D0AD7DAEFFB8B;  // feat=11 thr= -0.2806 L=1454 R=1455 cls=1 pur=0.954 leaf=0
        rom[1454] = 54'h254C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.580 leaf=1
        rom[1455] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1456] = 54'h2DCADE5B1FFB7B;  // feat=11 thr= -0.2856 L=1457 R=1468 cls=1 pur=0.714 leaf=0
        rom[1457] = 54'h2B5ADBDB2238F1;  // feat= 1 thr= 35.5579 L=1458 R=1463 cls=3 pur=0.675 leaf=0
        rom[1458] = 54'h385ADA5B300015;  // feat= 5 thr=  0.0026 L=1459 R=1460 cls=3 pur=0.880 leaf=0
        rom[1459] = 54'h1E5C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.471 leaf=1
        rom[1460] = 54'h3FDADB5B500015;  // feat= 5 thr=  0.0027 L=1461 R=1462 cls=3 pur=1.000 leaf=0
        rom[1461] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[1462] = 54'h3FDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=1.000 leaf=1
        rom[1463] = 54'h2F0ADCDB8FFAE8;  // feat= 8 thr= -0.3222 L=1464 R=1465 cls=1 pur=0.734 leaf=0
        rom[1464] = 54'h2BDC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.684 leaf=1
        rom[1465] = 54'h3B0ADDDBA00054;  // feat= 4 thr=  0.0207 L=1466 R=1467 cls=1 pur=0.923 leaf=0
        rom[1466] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1467] = 54'h324C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.787 leaf=1
        rom[1468] = 54'h318AE65BD00114;  // feat= 4 thr=  0.0648 L=1469 R=1484 cls=1 pur=0.774 leaf=0
        rom[1469] = 54'h33CAE2DBEFFCAB;  // feat=11 thr= -0.2097 L=1470 R=1477 cls=1 pur=0.810 leaf=0
        rom[1470] = 54'h398AE15BF00034;  // feat= 4 thr=  0.0134 L=1471 R=1474 cls=1 pur=0.899 leaf=0
        rom[1471] = 54'h3B4AE0DC0FFFE4;  // feat= 4 thr= -0.0065 L=1472 R=1473 cls=1 pur=0.924 leaf=0
        rom[1472] = 54'h2D4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.709 leaf=1
        rom[1473] = 54'h3D4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.956 leaf=1
        rom[1474] = 54'h2DDAE25C300015;  // feat= 5 thr=  0.0026 L=1475 R=1476 cls=3 pur=0.717 leaf=0
        rom[1475] = 54'h341C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.813 leaf=1
        rom[1476] = 54'h27DC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.619 leaf=1
        rom[1477] = 54'h2B8AE4DC600004;  // feat= 4 thr= -0.0011 L=1478 R=1481 cls=1 pur=0.678 leaf=0
        rom[1478] = 54'h230AE45C7FFFF4;  // feat= 4 thr= -0.0033 L=1479 R=1480 cls=1 pur=0.545 leaf=0
        rom[1479] = 54'h2C4C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.691 leaf=1
        rom[1480] = 54'h161C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.342 leaf=1
        rom[1481] = 54'h388AE5DCA0403E;  // feat=14 thr=  4.0100 L=1482 R=1483 cls=1 pur=0.881 leaf=0
        rom[1482] = 54'h3BCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.933 leaf=1
        rom[1483] = 54'h2964000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.644 leaf=1
        rom[1484] = 54'h3262E75CDFFF69;  // feat= 9 thr= -0.0396 L=1485 R=1486 cls=4 pur=0.784 leaf=0
        rom[1485] = 54'h2F9C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=3 pur=0.741 leaf=1
        rom[1486] = 54'h3EA2E85CFFFF69;  // feat= 9 thr= -0.0396 L=1487 R=1488 cls=4 pur=0.977 leaf=0
        rom[1487] = 54'h3CE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=0.950 leaf=1
        rom[1488] = 54'h3FE4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=4 pur=1.000 leaf=1
        rom[1489] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1490] = 54'h3FC2FC5D3013C1;  // feat= 1 thr=  1.2348 L=1491 R=1528 cls=0 pur=0.999 leaf=0
        rom[1491] = 54'h3FC2F4DD4FFFF1;  // feat= 1 thr= -0.0022 L=1492 R=1513 cls=0 pur=0.999 leaf=0
        rom[1492] = 54'h3FC2F05D5FFE07;  // feat= 7 thr= -0.1262 L=1493 R=1504 cls=0 pur=1.000 leaf=0
        rom[1493] = 54'h3FC2EFDD6FFFCC;  // feat=12 thr= -0.0154 L=1494 R=1503 cls=0 pur=1.000 leaf=0
        rom[1494] = 54'h3FC2EE5D700015;  // feat= 5 thr=  0.0026 L=1495 R=1500 cls=0 pur=1.000 leaf=0
        rom[1495] = 54'h3FC2ECDD8FF983;  // feat= 3 thr= -0.4058 L=1496 R=1497 cls=0 pur=0.999 leaf=0
        rom[1496] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1497] = 54'h3FC2EDDDAFF983;  // feat= 3 thr= -0.4053 L=1498 R=1499 cls=0 pur=0.996 leaf=0
        rom[1498] = 54'h298C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.649 leaf=1
        rom[1499] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1500] = 54'h3FC2EF5DDFFF81;  // feat= 1 thr= -0.0329 L=1501 R=1502 cls=0 pur=1.000 leaf=0
        rom[1501] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1502] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1503] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1504] = 54'h3FC2F15E1FFE07;  // feat= 7 thr= -0.1262 L=1505 R=1506 cls=0 pur=0.999 leaf=0
        rom[1505] = 54'h298C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.649 leaf=1
        rom[1506] = 54'h3FC2F25E3FFA50;  // feat= 0 thr= -0.3558 L=1507 R=1508 cls=0 pur=0.999 leaf=0
        rom[1507] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1508] = 54'h3F42F45E5FFA50;  // feat= 0 thr= -0.3557 L=1509 R=1512 cls=0 pur=0.987 leaf=0
        rom[1509] = 54'h24C2F3DE6FFAE8;  // feat= 8 thr= -0.3222 L=1510 R=1511 cls=0 pur=0.575 leaf=0
        rom[1510] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1511] = 54'h354C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.832 leaf=1
        rom[1512] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1513] = 54'h3DC2F9DEA02D8D;  // feat=13 thr=  2.8440 L=1514 R=1523 cls=0 pur=0.964 leaf=0
        rom[1514] = 54'h3F82F95EB0037A;  // feat=10 thr=  0.2158 L=1515 R=1522 cls=0 pur=0.994 leaf=0
        rom[1515] = 54'h3802F7DEC00F96;  // feat= 6 thr=  0.9720 L=1516 R=1519 cls=0 pur=0.874 leaf=0
        rom[1516] = 54'h3FC2F75EDFFDB6;  // feat= 6 thr= -0.1460 L=1517 R=1518 cls=0 pur=1.000 leaf=0
        rom[1517] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1518] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1519] = 54'h27CAF8DF00004C;  // feat=12 thr=  0.0162 L=1520 R=1521 cls=1 pur=0.622 leaf=0
        rom[1520] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1521] = 54'h354C000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.832 leaf=1
        rom[1522] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1523] = 54'h2382FBDF4FFFE4;  // feat= 4 thr= -0.0081 L=1524 R=1527 cls=0 pur=0.554 leaf=0
        rom[1524] = 54'h3E8AFB5F5FFF69;  // feat= 9 thr= -0.0396 L=1525 R=1526 cls=1 pur=0.976 leaf=0
        rom[1525] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
        rom[1526] = 54'h3ACC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=0.917 leaf=1
        rom[1527] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1528] = 54'h2FCAFE5F900002;  // feat= 2 thr= -0.0015 L=1529 R=1532 cls=1 pur=0.748 leaf=0
        rom[1529] = 54'h3FC2FDDFAFFF79;  // feat= 9 thr= -0.0360 L=1530 R=1531 cls=0 pur=1.000 leaf=0
        rom[1530] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1531] = 54'h3FC4000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=0 pur=1.000 leaf=1
        rom[1532] = 54'h3FCC000000000F;  // feat=15 thr=  0.0000 L=   0 R=   0 cls=1 pur=1.000 leaf=1
end

// ── State machine ─────────────────────────────────────────────
localparam IDLE     = 2'd0;
localparam TRAVERSE = 2'd1;
localparam DONE     = 2'd2;

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
                    state    <= TRAVERSE;
                end
            end
            TRAVERSE: begin
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
