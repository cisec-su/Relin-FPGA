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
        input                  load_q  ,
        input  [LOGL -1:0]     i       ,
        output [LOGQH-1:0]     qH_A    ,
        output [LOGQH-1:0]     qH_B    ,
        output [LOGQH-1:0]     qH_C    ,
        output [LOGQH-1:0]     qH_D    ,
        output                 load_q_A,
        output                 load_q_B,
        output                 load_q_C,
        output                 load_q_D
    );


wire [LOGQH-1:0] qH;


relin_q_mux #(
    .LOGL(LOGL),
    .LOGQ(LOGQ),
    .LOGQH(LOGQH)
) relin_q_mux_A (
    .clk(clk),
    .rst(rst),
    .i(i),
    .qH(qH)
);


shift_reg #(
    .LAT   (DELAY_A),
    .WIDTH (1)
) load_q_shift_reg_0 (
    .clk    (clk),
    .rst    (rst),
    .i_data (load_q),
    .o_data (load_q_A)
);


shift_reg #(
    .LAT   (DELAY_A),
    .WIDTH (LOGQH)
) qH_shift_reg_0 (
    .clk    (clk),
    .rst    (rst),
    .i_data (qH),
    .o_data (qH_A)
);


shift_reg #(
    .LAT   (DELAY_B),
    .WIDTH (1)
) load_q_shift_reg_1 (
    .clk    (clk),
    .rst    (rst),
    .i_data (load_q),
    .o_data (load_q_B)
);


shift_reg #(
    .LAT   (DELAY_B),
    .WIDTH (LOGQH)
) qH_shift_reg_1 (
    .clk    (clk),
    .rst    (rst),
    .i_data (qH),
    .o_data (qH_B)
);


shift_reg #(
    .LAT   (DELAY_C),
    .WIDTH (1)
) load_q_shift_reg_2 (
    .clk    (clk),
    .rst    (rst),
    .i_data (load_q),
    .o_data (load_q_C)
);


shift_reg #(
    .LAT   (DELAY_C),
    .WIDTH (LOGQH)
) qH_shift_reg_2 (
    .clk    (clk),
    .rst    (rst),
    .i_data (qH),
    .o_data (qH_C)
);


shift_reg #(
    .LAT   (DELAY_D),
    .WIDTH (1)
) load_q_shift_reg_3 (
    .clk    (clk),
    .rst    (rst),
    .i_data (load_q),
    .o_data (load_q_D)
);


shift_reg #(
    .LAT   (DELAY_D),
    .WIDTH (LOGQH)
) qH_shift_reg_3 (
    .clk    (clk),
    .rst    (rst),
    .i_data (qH),
    .o_data (qH_D)
);




endmodule