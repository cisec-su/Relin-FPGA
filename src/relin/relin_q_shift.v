module relin_q_shift
   #(   
        parameter LOGL     = 30, // number of primes
        parameter LOGQ     = 64,
        parameter LOGQH    = 17,
        parameter DELAY_A  = 2,
        parameter DELAY_B  = 2,
        parameter DELAY_C  = 2,
        parameter DELAY_D  = 2
    )
    (
        input                  clk     ,
        input                  rst     ,
        input                  load_q_ABC,
        input                  load_q_D_i,
        input  [LOGL -1:0]     i_ABC   ,
        input  [LOGL -1:0]     i_D     ,
        output [LOGQH-1:0]     qH_A    ,
        output [LOGQH-1:0]     qH_B    ,
        output [LOGQH-1:0]     qH_C    ,
        output [LOGQH-1:0]     qH_D    ,
        output [LOGQ -1:0]     half_D  ,
        output [LOGQ -1:0]     q_inv_D ,
        output                 load_q_A,
        output                 load_q_B,
        output                 load_q_C,
        output                 load_q_D
    );


wire [LOGQH-1:0] qH;
wire [LOGQH-1:0] qH_D_int;
wire [LOGQ -1:0] half;
wire [LOGQ -1:0] q_inv;

relin_q_mux #(
    .LOGL(LOGL),
    .LOGQ(LOGQ),
    .LOGQH(LOGQH)
) relin_q_mux_ABC_inst (
    .clk(clk),
    .rst(rst),
    .i(i_ABC),
    .qH(qH)
);


relin_q_mux #(
    .LOGL(LOGL),
    .LOGQ(LOGQ),
    .LOGQH(LOGQH)
) relin_q_mux_D_inst (
    .clk(clk),
    .rst(rst),
    .i(i_D),
    .qH(qH_D_int)
);



relin_half_mux #(
    .LOGL(LOGL),
    .LOGQ(LOGQ)
) relin_half_mux_inst (
    .clk(clk),
    .rst(rst),
    .i(i_D),
    .half(half)
);


relin_q_inv_mux #(
    .LOGL(LOGL),
    .LOGQ(LOGQ)
) relin_q_inv_mux_inst (
    .clk(clk),
    .rst(rst),
    .i(i_D),
    .q_inv(q_inv)
);


shift_reg #(
    .LAT   (DELAY_A),
    .WIDTH (1)
) load_q_shift_reg_0 (
    .clk    (clk),
    .rst    (rst),
    .i_data (load_q_ABC),
    .o_data (load_q_A)
);


shift_reg #(
    .LAT   (DELAY_A),
    .WIDTH (LOGQH),
    .RST_EN(0)
) qH_shift_reg_0 (
    .clk    (clk),
    .i_data (qH),
    .o_data (qH_A)
);


shift_reg #(
    .LAT   (DELAY_B),
    .WIDTH (1)
) load_q_shift_reg_1 (
    .clk    (clk),
    .rst    (rst),
    .i_data (load_q_ABC),
    .o_data (load_q_B)
);


shift_reg #(
    .LAT   (DELAY_B),
    .WIDTH (LOGQH),
    .RST_EN(0)
) qH_shift_reg_1 (
    .clk    (clk),
    .i_data (qH),
    .o_data (qH_B)
);


shift_reg #(
    .LAT   (DELAY_C),
    .WIDTH (1)
) load_q_shift_reg_2 (
    .clk    (clk),
    .rst    (rst),
    .i_data (load_q_ABC),
    .o_data (load_q_C)
);


shift_reg #(
    .LAT   (DELAY_C),
    .WIDTH (LOGQH),
    .RST_EN(0)
) qH_shift_reg_2 (
    .clk    (clk),
    .i_data (qH),
    .o_data (qH_C)
);


shift_reg #(
    .LAT   (DELAY_D),
    .WIDTH (1)
) load_q_shift_reg_3 (
    .clk    (clk),
    .rst    (rst),
    .i_data (load_q_D_i),
    .o_data (load_q_D  )
);


shift_reg #(
    .LAT   (DELAY_D),
    .WIDTH (LOGQH),
    .RST_EN(0)
) qH_shift_reg_3 (
    .clk    (clk),
    .i_data (qH_D_int),
    .o_data (qH_D)
);


shift_reg #(
    .LAT   (DELAY_D),
    .WIDTH (LOGQ),
    .RST_EN(0)
) half_shift_reg (
    .clk    (clk),
    .i_data (half),
    .o_data (half_D)
);


shift_reg #(
    .LAT   (DELAY_D),
    .WIDTH (LOGQ),
    .RST_EN(0)
) q_inv_shift_reg (
    .clk    (clk),
    .i_data (q_inv),
    .o_data (q_inv_D)
);





endmodule