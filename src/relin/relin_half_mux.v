// module relin_half_mux
//    #(   
//         parameter LOGN     = 16,
//         parameter LOGL     = 30, // number of primes
//         parameter LOGQ     = 64
//     )
//     (
//         input                 clk,
//         input                 rst,
//         input      [LOGL-1:0] i  ,
//         output reg [LOGQ-1:0] half
//     );



// if(LOGN == 12) begin
//     always @(*) begin
//         half = 60'h400d40000000000;
//     end
// end else if(LOGN == 13) begin
//     always @(*) begin
//         half = 60'h401900000000000;
//     end
// end
// else begin
//     always @(*) begin
//         half = 60'h400d40000000000;
//     end
// end



// endmodule

module relin_half_mux #(
    parameter LOGN = 16,
    parameter LOGL     = 30, // number of primes
    parameter LOGQ = 64
)(
    input                 clk,
    input                 rst,
    input      [LOGL-1:0] i  ,
    output     [LOGQ-1:0] half
);

localparam [LOGQ-1:0] HALF_VAL =
    (LOGN == 12) ? 64'h0400d40000000000 :
    (LOGN == 13) ? 64'h0401900000000000 :
    (LOGN == 14) ? 64'h0402e40000000000 :
    (LOGN == 15) ? 64'h0405d40000000000 :
    (LOGN == 16) ? 64'h040a000000000000 :
                   64'h0400d40000000000;

assign half = HALF_VAL;



endmodule
