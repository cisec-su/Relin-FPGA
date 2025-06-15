/*

    outputs q[i]

*/


module relin_q_mux
   #(   
        parameter LOGL     = 30, // number of primes
        parameter LOGQ     = 64,
        parameter LOGQH    = 17
    )
    (
        input                  clk,
        input                  rst,
        input  [LOGL -1:0]     i  ,
        output [LOGQH-1:0]     qH
    );


reg [ LOGQ-1:0] qH_int;

always @(*) begin
    case (i)
        0      : qH_int = 60'h800580000000001;
        1      : qH_int = 60'h800800000000001;
        2      : qH_int = 60'h801a80000000001;
        3      : qH_int = 60'h802500000000001;
        4      : qH_int = 60'h803200000000001;
        5      : qH_int = 60'h800800000000001;
        6      : qH_int = 60'h801a80000000001;
        7      : qH_int = 60'h802500000000001;
        8      : qH_int = 60'h803200000000001;
        default: qH_int = 60'h800580000000001; // default to first prime
    endcase
end

assign qH = qH_int[LOGQ-1 : LOGQ - LOGQH];  // take MSB LOGQH bits

endmodule