/*
    if (load_q)
        ths.q <= q
    else if (load_tw)
        ths.tw <= 
    else computes NTT or iNTT

    - We assume that the input is always valid after the start / load signals.
    - qH is received at the same clock cycle as the load_q signal.
    - psi are received starting from the clock cycle load_psi = 1.
    - i_poly are received starting from the clock cycle i_valid = 1.
    

*/
module ntt_wrapper
   #(   
        parameter LOGQ     = 64,
        parameter LOGQH    = 17,
        parameter LOGN     = 16,
        parameter LOGTP    = 5
    )
    (
        input              clk                ,
        input              rst                ,
        input              load_q             ,
        input              load_psi           ,
        input              intt               ,
        input  [LOGQH-1:0] q                  ,
        input              i_valid            ,
        input  [LOGQ -1:0] i_poly     [0:TP-1],
        input  [LOGQ -1:0] psi        [0:TP-1],
        output             o_valid            ,
        output [LOGQ -1:0] o_poly     [0:TP-1]
    );

localparam TP  = 1 << LOGTP;
localparam LAT = 8000; // todo


shift_reg #(
    .LAT   (LAT),
    .WIDTH (1)
)
o_valid_shift_reg
(
    .clk    (clk),
    .i_data (i_valid),
    .o_data (o_valid)
);



endmodule