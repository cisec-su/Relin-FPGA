`include "tp_ntt.svh"

module ntt_wrapper
#(
    parameter LOGQ     = 64,
    parameter LOGQH    = 17,
    parameter LOGN     = 16,
    parameter LOGTP    = 5
)
(
    input              clk                  ,
    input              rst                  ,
    input              load_q               ,
    input              load_psi             ,
    input              intt                 ,
    input  [LOGQH-1:0] qH                   , 
    input              i_valid              ,
    input  [LOGQ -1:0] i_poly       [0:TP-1],   //[0:(1<<LOGTP)-1],
    input  [LOGQ -1:0] psi          [0:TP-1],   //[0:(1<<LOGTP)-2], 
    output             o_valid              ,     
    output [LOGQ -1:0] o_poly       [0:TP-1]    //[0:(1<<LOGTP)-1]
);

localparam TP            = 1 << LOGTP;
localparam LAT           = 6000;

// ----------------------------------------------
// 1. Control logic for start/op
// ----------------------------------------------
logic start;
tp_ntt_op_t op;

always @(posedge clk) begin
    if (rst) begin
        start <= 0;
        op    <= OP_LOAD_Q; // OP_RFU
    end else begin
        if (load_q) begin
            //start <= 1;
            op    <= OP_LOAD_Q; // OP_LOAD_Q
        end else if (load_psi) begin
            //start <= 1;
            op    <= OP_LOAD_TWIDDLE; // OP_LOAD_TWIDDLE
        end else if (i_valid) begin
            start <= 1;
            op    <= OP_NTT; // OP_NTT
        end else begin
            start <= 0;
            op    <= OP_NTT; // OP_NTT
        end
    end
end

// ----------------------------------------------
// 2. Delay i_valid to generate o_valid
// ----------------------------------------------
shift_reg #(
    .LAT    (LAT),
    .WIDTH  (1),
    .RST_EN (1)
) o_valid_shift_reg (
    .clk    (clk),
    .rst    (rst),
    .i_data (i_valid),
    .o_data (o_valid)
);

// ----------------------------------------------
// 3. Delay i_poly, psi, and qH by 1 cycle
// ----------------------------------------------
logic [LOGQ-1:0]  i_poly_d [0:TP-1];
logic [LOGQ-1:0]  psi_d    [0:TP-1];
logic [LOGQH-1:0] qH_d;

shift_reg_arr #(
    .LAT    (1),
    .WIDTH  (LOGQ),
    .LENGTH (TP)
) i_poly_delay (
    .clk    (clk),
    .rst    (rst),
    .i_data (i_poly),
    .o_data (i_poly_d)
);

shift_reg_arr #(
    .LAT    (1),
    .WIDTH  (LOGQ),
    .LENGTH (TP)
) psi_delay (
    .clk    (clk),
    .rst    (rst),
    .i_data (psi),
    .o_data (psi_d)
);

shift_reg #(
    .LAT    (1),
    .WIDTH  (LOGQH),
    .RST_EN (1)
) qH_delay (
    .clk    (clk),
    .rst    (rst),
    .i_data (qH),
    .o_data (qH_d)
);

// ----------------------------------------------
// 4. Flatten i_poly_d and psi_d
// ----------------------------------------------
logic [TP*LOGQ-1:0] flat_i_poly;
logic [(TP-1)*LOGQ-1:0] flat_psi;

genvar i;
generate
    for (i = 0; i < TP; i = i + 1) begin
        assign flat_i_poly[(TP - 1 - i)*LOGQ +: LOGQ] = i_poly_d[i];
    end
    for (i = 0; i < (8-1)*4; i = i + 1) begin
        assign flat_psi[(TP - 2 - i)*LOGQ +: LOGQ] = 1;//psi_d[i];
    end
    assign flat_psi[3*LOGQ-1 : 0] = 1;//0;
endgenerate

/*
TP=32   0 1 2 3 4 27 x x x x

TP-1=31 [01234..27xxx] 

*/


// ----------------------------------------------
// 5. Output: connect o_poly by unpacking
// ----------------------------------------------
wire [TP*LOGQ-1:0] flat_o_poly;

generate
    for (i = 0; i < TP; i = i + 1) begin
        assign o_poly[i] = flat_o_poly[(TP - 1 - i)*LOGQ +: LOGQ];
    end
endgenerate

// ----------------------------------------------
// 6. Instantiate tp_ntt_top
// ----------------------------------------------
localparam LOGN1 = 3;
localparam LOGN2 = 3;
localparam LOGN3 = 3;

tp_ntt_top #(
    .LOGN     (LOGN),
    .LOGN1    (LOGN1),
    .LOGN2    (LOGN2),
    .LOGN3    (LOGN3),
    .LOGTP    (LOGTP),
    .LOGQ     (LOGQ),
    .LOGQH    (LOGQH),
    .NON_STD  (1),
    .MORE_DSP (0)
) tp_ntt_top_inst (
    .clk     (clk),
    .rst     (rst),
    .start   (start),
    .op      (op),
    .intt    (intt),
    .qH      (qH_d),
    .i_poly  (flat_i_poly),
    .psi     (flat_psi),
    .o_poly  (flat_o_poly)
);

endmodule
