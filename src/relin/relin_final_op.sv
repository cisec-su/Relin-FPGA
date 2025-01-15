/*

    Finalizes the relin computation

*/

module relin_final_op
   #(   
        parameter LOGQ     = 64,
        parameter LOGQH    = 17,
        parameter LOGN     = 16, 
        parameter TP       = 5
    )
    (
        input                   clk         ,
        input                   rst         ,
        input                   last        ,
        input                   load_q      ,
        input     [LOGQH -1:0]  qH          ,
        input     [LOGQ  -1:0]  q_inv       ,
        input                   i_valid     ,
        input     [LOGQ  -1:0]  A   [0:TP-1],
        input     [LOGQ  -1:0]  B   [0:TP-1],
        output                  o_valid     ,
        output    [LOGQ  -1:0]  C   [0:TP-1]
    );

localparam LAT = 10;

shift_reg #(
    .SHIFT (LAT),
    .WIDTH (1  )
)
o_valid_shift_reg
(
    .clk    (clk),
    .rst    (rst),
    .i_data (i_valid),
    .o_data (o_valid)
);

// reg [LOGQ  -1:0] poly_last [0:N-1];
// reg [LOGQH -1:0] qH_int; 
// reg [LOGQ  -1:0] half;

// always @(posedge clk) 
// begin
//     if (rst) 
//     begin
//     end
// end





endmodule