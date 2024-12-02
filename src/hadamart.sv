/*

    Computes C[i] = A[i] * B[i] mod q for i = 0 to TP-1

*/
module hadamart
   #(   
        parameter W        = 64, // word size
        parameter TP       = 32, // coefficient throughput
    )
    (
        input              clk           ,
        input              rst           ,
        input              load_q        , // check whether we need this
        input     [W-1:0]  q             ,
        input     [W-1:0]  A  [TP-1:0]   ,
        input     [W-1:0]  B  [TP-1:0]   ,
        output    [W-1:0]  C  [TP-1:0]
    );


for (genvar i = 0; i < TP; i++) begin
    modmul #(
        .W(W)
    ) modmul_inst (
        .clk(clk),
        .rst(rst),
        .q(q),
        .A(A[i]),
        .B(B[i]),
        .C(C[i])
    );
end



endmodule