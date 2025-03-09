/*
    if (load_q)
        ths.q <= q
    else if (load_tw)
        ths.tw <= 
    else computes NTT or iNTT

    - We assume that the input is always valid after the start / load signals.
    - qH is received at the same clock cycle as the load_q signal.
    - psi are received starting from the clock cycle load_psi = 1.
    - i_poly are received starting from the clock cycle i_valid = 1.
    

*/
module ntt_wrapper
   #(   
        parameter LOGQ     = 64,
        parameter LOGQH    = 17,
        parameter LOGN     = 16,
        parameter LOGTP    = 5
    )
    (
        input              clk                ,
        input              rst                ,
        input              load_q             ,
        input              load_psi           ,
        input              intt               ,
        input  [LOGQH-1:0] qH                 ,
        input              i_valid            ,
        input  [LOGQ -1:0] i_poly     [0:TP-1],
        input  [LOGQ -1:0] psi        [0:TP-1],
        output             o_valid            ,
        output [LOGQ -1:0] o_poly     [0:TP-1]
    );

localparam TP  = 1 << LOGTP;
localparam BTF_LAT = 12;
localparam LAT = (BTF_LAT * LOGN) + (1 << (LOGN - LOGTP)); // todo


wire ntt_op;
wire [(TP*LOGQ)-1:0] psi_flat;
wire [(TP*LOGQ)-1:0] i_poly_flat;
wire [(TP*LOGQ)-1:0] o_poly_flat;


shift_reg #(
    .SHIFT (LAT),
    .WIDTH (1),
    .RST_EN(1)
)
o_valid_shift_reg
(
    .clk    (clk),
    .rst    (rst),
    .i_data (i_valid),
    .o_data (o_valid)
);


assign ntt_op = load_q ? 2'd1 : (load_psi ? 2'd3 : 2'd0);


generate
    for (genvar i = 0; i < TP; i++) begin : GEN_FLATTEN
        assign psi_flat[(i+1)*LOGQ-1:i*LOGQ] = psi[i];
        assign i_poly_flat[(i+1)*LOGQ-1:i*LOGQ] = i_poly[i];
        assign o_poly[i] = o_poly_flat[(i+1)*LOGQ-1:i*LOGQ];
    end
endgenerate


// tp_ntt_top #(
//     .LOGN   (LOGN        ),
//     .LOGN1  (LOGTP       ),
//     .LOGN2  (LOGN-2*LOGTP),
//     .LOGN3  (LOGTP       ),
//     .LOGTP  (LOGTP       ),
//     .LOGQ   (LOGQ        ),
//     .LOGQH  (LOGQH       )
// ) tp_ntt_top_inst (
//     .clk            (clk        ),
//     .rst            (rst        ),
//     .START_NTT_ALL  (i_valid    ),
//     .OP_TYPE_INPUT  (ntt_op     ),
//     .Q_in           (qH         ),
//     .NTT_INPUT      (i_poly_flat),
//     .TWIDDLE_INPUT  (psi_flat   ),
//     .NTT_OUTPUT     (o_poly_flat)
// );



endmodule