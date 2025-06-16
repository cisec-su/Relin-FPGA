module relin_half_mux
   #(   
        parameter LOGL     = 30, // number of primes
        parameter LOGQ     = 64
    )
    (
        input                 clk,
        input                 rst,
        input      [LOGL-1:0] i  ,
        output reg [LOGQ-1:0] half
    );


always @(*) begin
    case (i)
        default: half = 60'h401900000000000;
    endcase
end


endmodule