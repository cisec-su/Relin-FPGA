/*

    Computes C[i] += A[i] for i = 0 to TP-1

*/
module accumulator
   #(   
        parameter W        = 64, // word size
        parameter TP       = 32, // coefficient throughput
    )
    (
        input              clk         ,
        input              rst         ,
        input              en          ,
        input              load_q      ,
        input     [W-1:0]  q           , // check whether we need this
        input     [W-1:0]  A   [TP-1:0],
        output    [W-1:0]  C   [TP-1:0]
    );





endmodule