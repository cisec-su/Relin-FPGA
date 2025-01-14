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


reg [LOGQH-1:0] qH_int;

always @(*) begin
    case (i)
        // will be extended
        default: qH_int = 64'h000000000000;
    endcase
end

assign qH = qH_int;

endmodule