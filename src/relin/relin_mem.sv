`include "relin_if.svh"
`include "relin_mem.svh"

// For now, we assume that valid input data is received sequentially starting from clock cycle when i_valid signal = 1.

module relin_mem
   #(   
        parameter LOGQ     = 64,
        parameter LOGN     = 16,
        parameter LOGL     = 5 ,
        parameter ID_WIDTH = 4 ,
        parameter TP       = 32,
        parameter NUM_PSI  = 1 << LOGN
    )
    (
        input                 clk                  ,
        input                 rst                  ,
        // internal memory signals          
        // input port 0
        input                 i_p0_en              ,
        input  [ID_WIDTH-1:0] i_p0_id              ,
        input  [LOGL-1:0]     i_p0_idx             ,
        output reg            i_p0_ready           , // indicates that the module is ready to accept new command (i_xx_en)
        output                i_p0_valid           ,
        output                i_p0_done            , // indicates the cc for last valid output.
        output [LOGQ-1:0]     i_p0_data    [0:TP-1],
        // input port 1
        input                 i_p1_en              ,
        input  [ID_WIDTH-1:0] i_p1_id              ,
        input  [LOGL-1:0]     i_p1_idx             ,
        input  [LOGL-1:0]     i_p1_idy             ,
        output reg            i_p1_ready           ,
        output                i_p1_valid           ,
        output                i_p1_done            ,
        output [LOGQ-1:0]     i_p1_data    [0:TP-1],
        // input port 2
        input                 i_p2_en              ,
        // ID is always RLK_1
        input  [LOGL-1:0]     i_p2_idx             ,
        input  [LOGL-1:0]     i_p2_idy             ,
        output reg            i_p2_ready           ,
        output                i_p2_valid           ,
        output                i_p2_done            ,
        output [LOGQ-1:0]     i_p2_data    [0:TP-1],
        // output port 0
        input                 o_p3_en              ,
        // ID is always RLK_1
        input  [ID_WIDTH-1:0] o_p3_id              ,
        input  [LOGL-1:0]     o_p3_idx             ,
        output reg            o_p3_ready           ,
        output                o_p3_done            ,
        input  [LOGQ-1:0]     o_p3_data    [0:TP-1],
        // memory interface
        relin_t.master     relin_t
    );

// ========== Interface P0 ==========
assign relin_t.i_p0_en  = i_p0_en;
assign relin_t.i_p0_id = i_p0_id;
assign relin_t.i_p0_idx = i_p0_idx;
assign i_p0_data        = relin_t.i_p0_data;
assign i_p0_ready       = relin_t.i_p0_ready;
assign i_p0_valid       = relin_t.i_p0_valid;
assign i_p0_done        = relin_t.i_p0_done;

// ========== Interface P1 ==========
assign relin_t.i_p1_en  = i_p1_en;
assign relin_t.i_p1_id  = i_p1_id;
assign relin_t.i_p1_idx = i_p1_idx;
assign relin_t.i_p1_idy = i_p1_idy;
assign i_p1_data        = relin_t.i_p1_data;
assign i_p1_ready       = relin_t.i_p1_ready;
assign i_p1_valid       = relin_t.i_p1_valid;
assign i_p1_done        = relin_t.i_p1_done;

// ========== Interface P2 ==========
assign relin_t.i_p2_en  = i_p2_en;
assign relin_t.i_p2_idx = i_p2_idx;
assign relin_t.i_p2_idy = i_p2_idy;
assign i_p2_data        = relin_t.i_p2_data;
assign i_p2_ready       = relin_t.i_p2_ready;
assign i_p2_valid       = relin_t.i_p2_valid;
assign i_p2_done        = relin_t.i_p2_done;

// ========== Interface P3 ==========
assign relin_t.o_p3_en   = o_p3_en;
assign relin_t.o_p3_id   = o_p3_id;
assign relin_t.o_p3_idx  = o_p3_idx;
assign relin_t.o_p3_data = o_p3_data;
assign o_p3_done         = relin_t.o_p3_done;
assign o_p3_ready        = relin_t.o_p3_ready;



endmodule