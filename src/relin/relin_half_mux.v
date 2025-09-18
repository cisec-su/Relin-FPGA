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
        0      : half = 60'h401900000000000;
        1      : half = 60'h401900000000000;
        2      : half = 60'h401900000000000;
        3      : half = 60'h401900000000000;
        4      : half = 60'h401900000000000;
        default: half = 60'h401900000000000;
    endcase
end


endmodule