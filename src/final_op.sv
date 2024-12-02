/*

    Finalizes the relin computation

*/

module final_op
   #(   
        parameter W        = 64, // word size
        parameter TP       = 32, // coefficient throughput
    )
    (
        input              clk         ,
        input              rst         ,
        input     [W-1:0]  A   [TP-1:0],
        output    [W-1:0]  C   [TP-1:0]
    );





endmodule