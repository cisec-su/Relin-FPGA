module relin_ntt_mux
   #(   
        parameter LOGQ           = 64,
        parameter LOGQH          = 17,
        parameter LOGN           = 16,
        parameter LOGTP          = 5 ,
        parameter INTT_A_DELAY   = 2 ,
        parameter INTT_B_DELAY   = INTT_A_DELAY
    )
    (
        input              clk                  ,
        input              rst                  ,
        input              load_q               ,
        input              load_psi             ,
        input              intt                 ,
        input  [LOGQH-1:0] qH                   ,
        input              i_valid_ntt          ,
        input              i_valid_intt_A       ,
        input              i_valid_intt_B       ,
        input  [LOGQ -1:0] i_poly_ntt   [0:TP-1],
        input  [LOGQ -1:0] i_poly_intt_A[0:TP-1],
        input  [LOGQ -1:0] i_poly_intt_B[0:TP-1],
        input  [LOGQ -1:0] psi          [0:TP-1],
        output             o_valid              ,
        output [LOGQ -1:0] o_poly       [0:TP-1]
    );

localparam  TP = 1 << LOGTP;


wire [LOGQ-1:0] i_poly [0:TP-1];
wire [LOGQ-1:0] i_poly_intt_A_d [0:TP-1];
wire [LOGQ-1:0] i_poly_intt_B_d [0:TP-1];
wire [LOGQ-1:0] i_poly_intt [0:TP-1];
wire i_valid_intt_A_d;
wire i_valid_intt_B_d;
wire i_valid_intt;
wire i_valid;



shift_reg_arr #(
    .LAT    (INTT_A_DELAY),
    .WIDTH  (LOGQ        ),
    .LENGTH (TP          )
) i_poly_intt_A_shift_reg (
    .clk    (clk            ),
    .rst    (rst            ),
    .i_data (i_poly_intt_A  ),
    .o_data (i_poly_intt_A_d)
);

shift_reg_arr #(
    .LAT    (INTT_B_DELAY),
    .WIDTH  (LOGQ        ),
    .LENGTH (TP          )
) i_poly_intt_B_shift_reg (
    .clk    (clk            ),
    .rst    (rst            ),
    .i_data (i_poly_intt_B  ),
    .o_data (i_poly_intt_B_d)
);

shift_reg #(
    .LAT   (INTT_A_DELAY),
    .WIDTH (1           )
) i_valid_intt_A_shift_reg (
    .clk    (clk            ),
    .rst    (rst            ),
    .i_data (i_valid_intt_A ),
    .o_data (i_valid_intt_A_d)
);

shift_reg #(
    .LAT   (INTT_B_DELAY),
    .WIDTH (1           )
) i_valid_intt_B_shift_reg (
    .clk    (clk            ),
    .rst    (rst            ),
    .i_data (i_valid_intt_B ),
    .o_data (i_valid_intt_B_d)
);


assign i_poly_intt  = i_valid_intt_B_d ? i_poly_intt_B_d : i_poly_intt_A_d;
assign i_valid_intt = i_valid_intt_A_d | i_valid_intt_B_d;


assign i_poly  = intt ? i_poly_intt  : i_poly_ntt;
assign i_valid = intt ? i_valid_intt : i_valid_ntt;


ntt_wrapper #(
    .LOGQ (LOGQ ),
    .LOGQH(LOGQH),
    .LOGN (LOGN ),
    .LOGTP(LOGTP)
) ntt_wrapper_inst (
    .clk     (clk     ),
    .rst     (rst     ),
    .load_q  (load_q  ),
    .load_psi(load_psi),
    .intt    (intt    ),
    .qH      (qH      ),
    .i_valid (i_valid ),
    .i_poly  (i_poly  ),
    .psi     (psi     ),
    .o_valid (o_valid ),
    .o_poly  (o_poly  )
);

endmodule