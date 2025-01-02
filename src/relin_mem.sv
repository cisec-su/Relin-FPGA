`include "relin_if.svh"

// For now, we assume that valid input data is received sequentially starting from clock cycle when i_valid signal = 1.

module relin_mem
   #(   
        parameter LOGQ = 64,
        parameter LOGL = 5 ,
        parameter TP   = 32
    )
    (
        input              clk                   ,
        input              rst                   ,
        // internal memory signals          
        input              i_psi_en              ,
        output             i_psi_ready           ,
        output             i_psi_valid           ,
        output             i_psi_done            ,
        input              i_psi_inv             ,
        input  [LOGL-1:0]  i_psi_id              ,
        output [LOGQ-1:0]  i_psi_data    [0:TP-1],
        // port for input polynomial
        input              i_poly_en             ,
        output             i_poly_ready          ,
        output             i_poly_valid          ,
        output             i_poly_done           ,
        input  [LOGL-1:0]  i_poly_id             ,
        output [LOGQ-1:0]  i_poly_data   [0:TP-1],
        // port for input rlk0
        input              i_rlk0_en             ,
        output             i_rlk0_ready          ,
        output             i_rlk0_valid          ,
        output             i_rlk0_done           ,
        input  [LOGL-1:0]  i_rlk0_id             ,
        output [LOGQ-1:0]  i_rlk0_data   [0:TP-1],
        // port for input rlk0
        input              i_rlk1_en             ,
        output             i_rlk1_ready          ,
        output             i_rlk1_valid          ,
        output             i_rlk1_done           ,
        input  [LOGL-1:0]  i_rlk1_id             ,
        output [LOGQ-1:0]  i_rlk1_data   [0:TP-1],
        // port for output polynomial
        input              o_poly_en             ,
        output             o_poly_ready          ,
        output             o_poly_done           ,
        input  [LOGL-1:0]  o_poly_id             ,
        input  [LOGQ-1:0]  o_poly_data   [0:TP-1],
        // memory interface
        relin_t.master     relin_t
    );

assign i_psi_ready = 1;
assign i_poly_ready = 1;
assign i_rlk0_ready = 1;
assign i_rlk1_ready = 1;
assign o_poly_ready = 1;

shift_reg #(
    .LAT   (4),
    .WIDTH (1)
)
i_psi_valid_shift_reg
(
    .clk    (clk),
    .i_data (i_psi_en),
    .o_data (i_psi_valid)
);

shift_reg #(
    .LAT   (1020),
    .WIDTH (1)
)
i_psi_valid_shift_reg
(
    .clk    (clk),
    .i_data (i_psi_en),
    .o_data (i_psi_done)
);

shift_reg #(
    .LAT   (4),
    .WIDTH (1)
)
i_poly_valid_shift_reg
(
    .clk    (clk),
    .i_data (i_poly_en),
    .o_data (i_poly_valid)
);

shift_reg #(
    .LAT   (1020),
    .WIDTH (1)
)
i_poly_valid_shift_reg
(
    .clk    (clk),
    .i_data (i_poly_en),
    .o_data (i_poly_done)
);

shift_reg #(
    .LAT   (4),
    .WIDTH (1)
)
i_rlk0_valid_shift_reg
(
    .clk    (clk),
    .i_data (i_rlk0_en),
    .o_data (i_rlk0_valid)
);

shift_reg #(
    .LAT   (1020),
    .WIDTH (1)
)
i_rlk0_valid_shift_reg
(
    .clk    (clk),
    .i_data (i_rlk0_en),
    .o_data (i_rlk0_done)
);

shift_reg #(
    .LAT   (4),
    .WIDTH (1)
)
i_rlk1_valid_shift_reg
(
    .clk    (clk),
    .i_data (i_rlk1_en),
    .o_data (i_rlk1_valid)
);

shift_reg #(
    .LAT   (1020),
    .WIDTH (1)
)
i_rlk1_valid_shift_reg
(
    .clk    (clk),
    .i_data (i_rlk1_en),
    .o_data (i_rlk1_done)
);

shift_reg #(
    .LAT   (1020),
    .WIDTH (1)
)
o_poly_valid_shift_reg
(
    .clk    (clk),
    .i_data (o_poly_en),
    .o_data (o_poly_done)
);

endmodule