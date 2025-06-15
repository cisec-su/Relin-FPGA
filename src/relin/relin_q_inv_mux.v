module relin_q_inv_mux
   #(   
        parameter LOGL     = 30, // number of primes
        parameter LOGQ     = 64
    )
    (
        input                 clk,
        input                 rst,
        input      [LOGL-1:0] i  ,
        output reg [LOGQ-1:0] q_inv
    );


always @(*) begin
    case (i)
        0      : q_inv = 60'h0fd2a84508a1703;
        1      : q_inv = 60'h67a4f3cf3cf430d;
        2      : q_inv = 60'h6792b3bea3682ba;
        3      : q_inv = 60'h764989d89d8b13c;
        4      : q_inv = 60'h67a4f3cf3cf430d;
        5      : q_inv = 60'h6792b3bea3682ba;
        6      : q_inv = 60'h764989d89d8b13c;
        7      : q_inv = 60'h67a4f3cf3cf430d;
        default: q_inv = 60'h000000000000000;
    endcase
end


endmodule