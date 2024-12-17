/*

    outputs q[i]

*/


module q_mux
   #(   
        parameter L        = 30, // number of primes
        parameter W        = 64, // word size
    )
    (
        input                  clk              ,
        input                  rst              ,
        input  [$clog(L)-1:0]  i                ,
        output [W-1:0]         q
    );


endmodule