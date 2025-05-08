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
        // will be extended
        default: qH_int = 60'h800580000000001; // NTT Q 
    endcase
end

assign qH = qH_int[LOGQ-1 : LOGQ - LOGQH];  // take MSB LOGQH bits

endmodule