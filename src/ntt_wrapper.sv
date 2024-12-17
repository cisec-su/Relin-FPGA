/*

    if (load_q)
        ths.q <= q
    else if (load_tw)
        ths.tw <= A_tw
    else computes C = NTT(A_tw) or C = iNTT(A) depending on intt

*/
module ntt_wrapper
   #(   
        parameter W        = 64, // word size
        parameter LOGN     = 16, // ring size
        parameter TP       = 32, // coefficient throughput
    )
    (
        input              clk              ,
        input              rst              ,
        input              load_q           ,
        input              load_tw          ,
        input              intt             ,
        input     [W-1:0]  q                ,
        input     [W-1:0]  A_tw   [TP-1:0]  , // twiddles are loaded through A_tw
        // input              i_valid          , not sure whether we need this
        output    [W-1:0]  C      [TP-1:0]
    );




endmodule