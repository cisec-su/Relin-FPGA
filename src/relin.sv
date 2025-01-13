`include "relin_if.svh"

module relin
   #(   
        parameter L        = 30  , // Number of primes
        parameter LOGQ     = 64  ,
        parameter LOGQH    = 64  ,
        parameter LOGN     = 16  ,
        parameter LOGTP    = 5  , // polyicient throughput
        parameter NUMPSI   = 1 << LOGN // Number of twiddles that must be loaded
    )
    (
        input              clk   ,
        input              rst   ,
        input              start ,
        output             done  ,
        relin_t.master     relin_t
    );


localparam LOGL = $rtoi($ceil($clog2(L)));
localparam TP = 1 << LOGTP;
localparam CU1_CU2_LAT = 4;
localparam CU1_CU4_LAT = 2;
localparam CU2_CU3_LAT = 2;
localparam CU1_CU3_LAT = 6;
localparam NTT_ACC_LAT   = 2;




wire [LOGQH-1:0] qH, qH_d1, qH_d2, qH_d3;
// fsm <-> ntt, hadamard, accumulator, final_op
wire load_q, load_q_d1, load_q_d2, load_q_d3;
// mem <-> fsm
reg i_psi_en, i_psi_inv;
wire i_psi_ready, i_psi_valid, i_psi_done;
wire [LOGL-1:0] i_psi_id;
reg i_poly_en;
wire i_poly_ready, i_poly_valid, i_poly_done;
wire [LOGL-1:0] i_poly_id;
wire i_rlk0_en, i_rlk0_ready, i_rlk0_valid, i_rlk0_done;
wire [LOGL-1:0] i_rlk0_id;
wire [LOGL-1:0] i_rlk1_id;
wire i_rlk1_en, i_rlk1_ready, i_rlk1_valid, i_rlk1_done;
wire o_poly_en, o_poly_ready, o_poly_done;
wire [LOGL-1:0] o_poly_id;
// mem -> ntt
wire [LOGQ-1:0] i_psi_data [0:TP-1];
wire [LOGQ-1:0] i_poly_data [0:TP-1];
// mem -> hadamard
wire [LOGQ-1:0] i_rlk0_data [0:TP-1];
wire [LOGQ-1:0] i_rlk1_data [0:TP-1];
// mem <- final_op
wire [LOGQ-1:0] o_poly_data [0:TP-1];
// ntt control path
wire load_psi;
reg intt;
wire ntt_i_valid;
wire ntt_o_valid;
// ntt data path
wire [LOGQ-1:0] ntt_i_poly [TP-1:0];
wire [LOGQ-1:0] ntt_o_poly [TP-1:0];
// fifo control path
wire fifo_ren, fifo_wen;
// fifo data path
wire [LOGQ-1:0] fifo_i_data [TP-1:0];
wire [LOGQ-1:0] fifo_o_data [TP-1:0];
// hadamard control path
wire had_0_i_valid, had_1_i_valid;
wire had_0_o_valid, had_1_o_valid;
// hadamard data path
wire [LOGQ-1:0] had_0_i_poly_A [TP-1:0];
wire [LOGQ-1:0] had_1_i_poly_A [TP-1:0];
wire [LOGQ-1:0] had_0_i_poly_B [TP-1:0];
wire [LOGQ-1:0] had_1_i_poly_B [TP-1:0];
wire [LOGQ-1:0] had_0_o_poly   [TP-1:0];
wire [LOGQ-1:0] had_1_o_poly   [TP-1:0];
// accumulator control path
wire acc_0_wen, acc_1_wen;
reg acc_sel, acc_sel_d, acc_0_ren;
wire acc_1_ren, acc_0_o_valid, acc_1_o_valid, acc_0_done, acc_1_done;
wire acc_0_o_valid_d, acc_1_o_valid_d;
// accumulator data path
wire [LOGQ-1:0] acc_0_i_poly [TP-1:0];
wire [LOGQ-1:0] acc_1_i_poly [TP-1:0];
wire [LOGQ-1:0] acc_0_o_poly [TP-1:0];
wire [LOGQ-1:0] acc_1_o_poly [TP-1:0];
wire [LOGQ-1:0] acc_0_o_poly_d [TP-1:0];
wire [LOGQ-1:0] acc_1_o_poly_d [TP-1:0];
// final op control path
wire fn_i_valid;
wire fn_o_valid;
wire fn_rst;
// final op data path
wire [LOGQ-1:0] fn_i_poly [TP-1:0];
wire [LOGQ-1:0] fn_o_poly [TP-1:0];
// fsm1 inputs
wire load_intt, load_intt_d1, load_intt_d2;
wire feed_intt, feed_intt_d1;


q_mux #(
    .LOGL (LOGL),
    .LOGQ (LOGQ),
    .LOGQH(LOGQH)
) q_mux_inst (
    .clk(clk),
    .rst(rst),
    .i(ctr_L),
    .qH(qH)
);


relin_mem #(
    .LOGQ(LOGQ),
    .LOGL(LOGL),
    .LOGN(LOGN),
    .TP(TP)
) relin_mem_inst (
    .clk(clk),
    .rst(rst),
    .i_psi_en(i_psi_en),
    .i_psi_ready(i_psi_ready),
    .i_psi_valid(i_psi_valid),
    .i_psi_done(i_psi_done),
    .i_psi_id(i_psi_id),
    .i_psi_data(i_psi_data),
    .i_poly_en(i_poly_en),
    .i_poly_ready(i_poly_ready),
    .i_poly_valid(i_poly_valid),
    .i_poly_done(i_poly_done),
    .i_poly_id(i_poly_id),
    .i_poly_data(i_poly_data),
    .i_rlk0_en(i_rlk0_en),
    .i_rlk0_ready(i_rlk0_ready),
    .i_rlk0_valid(i_rlk0_valid),
    .i_rlk0_done(i_rlk0_done),
    .i_rlk0_id(i_rlk0_id),
    .i_rlk0_data(i_rlk0_data),
    .i_rlk1_en(i_rlk1_en),
    .i_rlk1_ready(i_rlk1_ready),
    .i_rlk1_valid(i_rlk1_valid),
    .i_rlk1_done(i_rlk1_done),
    .i_rlk1_id(i_rlk1_id),
    .i_rlk1_data(i_rlk1_data),
    .o_poly_en(o_poly_en),
    .o_poly_ready(o_poly_ready),
    .o_poly_done(o_poly_done),
    .o_poly_id(o_poly_id),
    .o_poly_data(o_poly_data),
    .relin_t(relin_t)
);


relin_cu_1 #(
    .L(L)
) relin_cu_1_inst (
    .clk(clk),
    .rst(rst),
    .start(start),
    .load_ntt(done_base),
    .load_intt(load_intt_d1),
    .i_psi_ready(i_psi_ready),
    .i_psi_done(i_psi_done),
    .i_poly_ready(i_poly_ready),
    .i_poly_done(i_poly_done),
    .i_psi_en(i_psi_en),
    .i_psi_inv(i_psi_inv),
    .i_poly_en(i_poly_en),
    .intt(intt),
    .load_q(load_q),
    .feed_intt(feed_intt),
    .busy()
);


ntt_wrapper #(
    .LOGQ (LOGQ ),
    .LOGQH(LOGQH),
    .LOGN (LOGN ),
    .LOGTP(LOGTP)
) ntt_wrapper_inst (
    .clk     (clk        ),
    .rst     (rst        ),
    .load_q  (load_q     ),
    .load_psi(i_psi_valid),
    .qH      (qH         ),
    .intt    (intt       ),
    .i_valid (ntt_i_valid),
    .i_poly  (ntt_i_poly),
    .psi     (i_psi_data ),
    .o_poly  (ntt_o_poly),
    .o_valid (ntt_o_valid)
);


relin_cu_3 #(
    .L(L)
) relin_cu_3_inst (
    .clk(clk),
    .rst(rst),
    .start(load_q_d1),
    .i_rlk0_ready(i_rlk0_ready),
    .i_rlk1_ready(i_rlk1_ready),
    .ntt_o_valid(ntt_o_valid),
    .i_rlk0_en(i_rlk0_en),
    .i_rlk1_en(i_rlk1_en),
    .i_rlk0_id(i_rlk0_id)
);


relin_fifo #(
    .K   (1 << (LOGN - LOGTP)),
    .TP  (TP                 ),
    .LOGQ(LOGQ               )
) relin_fifo_inst (
    .clk(clk),
    .rst(rst),
    .ren(fifo_ren),
    .wen(fifo_wen),
    .i_data(fifo_i_data),
    .o_data(fifo_o_data)
);

hadamard #(
    .LOGQ (LOGQ ),
    .LOGQH(LOGQH),
    .TP   (TP   )
) hadamard_inst_0 (
    .clk(clk),
    .rst(rst),
    .qH(qH_d1),
    .load_q(load_q_d1),
    .i_valid(had_0_i_valid),
    .o_valid(had_0_o_valid),
    .A(had_0_i_poly_A),
    .B(had_0_i_poly_B),
    .C(had_0_o_poly)
);


hadamard #(
    .LOGQ (LOGQ ),
    .LOGQH(LOGQH),
    .TP   (TP   )
) hadamard_inst_1 (
    .clk(clk),
    .rst(rst),
    .qH(qH_d1),
    .load_q(load_q_d1),
    .i_valid(had_1_i_valid),
    .o_valid(had_1_o_valid),
    .A(had_1_i_poly_A),
    .B(had_1_i_poly_B),
    .C(had_1_o_poly)
);


accumulator #(
    .LOGK (LOGN-LOGTP),
    .LOGQ (LOGQ      ),
    .LOGQH(LOGQH     ),
    .TP   (TP        )
) accumulator_inst_0 (
    .clk(clk),
    .rst(rst | acc_rst),
    .ren(acc_0_ren),
    .wen(had_0_o_valid),
    .done(acc_0_done),
    .load_q(load_q_d2),
    .qH(qH_d2),
    .A(acc_0_i_poly),
    .o_valid(acc_0_o_valid),
    .C(acc_0_o_poly)
);


accumulator #(
    .LOGK (LOGN-LOGTP),
    .LOGQ (LOGQ      ),
    .LOGQH(LOGQH     ),
    .TP   (TP        )
) accumulator_inst_1 (
    .clk(clk),
    .rst(rst | acc_rst),
    .ren(acc_1_ren),
    .wen(had_1_o_valid),
    .done(acc_1_done),
    .load_q(load_q_d2),
    .qH(qH_d2),
    .A(acc_1_i_poly),
    .o_valid(acc_1_o_valid),
    .C(acc_1_o_poly)
);


relin_cu_2 #(
    .L(L)
) relin_cu_2_inst (
    .clk        (clk        ),
    .rst        (rst        ),
    .acc_0_done (acc_0_done ),
    .acc_1_done (acc_1_done ),
    .acc_0_ren  (acc_0_ren  ),
    .acc_1_ren  (acc_1_ren  ),
    .feed_intt  (feed_intt_d1),
    .load_intt  (load_intt  )
);

final_op #(
    .LOGQ(LOGQ),
    .LOGQH(LOGQH),
    .LOGN(LOGN),
    .TP(TP)
) final_op_inst (
    .clk(clk),
    .rst(rst | fn_rst),
    .load_q(load_q_d3),
    .qH(qH_d3),
    .i_valid(fn_i_valid),
    .A(fn_i_poly),
    .B(      ),
    .o_valid(fn_o_valid),
    .C(fn_o_poly)
);


relin_cu_4 #(
    .L(L)
) relin_cu_4_inst (
    .clk(clk),
    .rst(rst),
    .start(load_intt_d2),
    .o_poly_done(o_poly_done),
    .fn_o_valid(fn_o_valid),
    .o_poly_ready(o_poly_ready),
    .o_poly_id(o_poly_id),
    .o_poly_en(o_poly_en),
    .done_base(done_base),
    .done_all(done)
);



for (genvar i = 0; i < TP; i = i + 1) begin
    shift_reg #(
        .LAT   (NTT_ACC_LAT),
        .WIDTH (LOGQ)
    )
    acc_d_shift_reg_0
    (
        .clk    (clk),
        .rst    (rst),
        .i_data (acc_0_o_poly[i]),
        .o_data (acc_0_o_poly_d[i])
    );

    shift_reg #(
        .LAT   (NTT_ACC_LAT),
        .WIDTH (LOGQ)
    )
    acc_d_shift_reg_1
    (
        .clk    (clk),
        .rst    (rst),
        .i_data (acc_1_o_poly[i]),
        .o_data (acc_1_o_poly_d[i])
    );
end    

shift_reg #(
    .LAT   (CU1_CU2_LAT),
    .WIDTH (1)
)
acc_c_shift_reg_0
(
    .clk    (clk),
    .rst    (rst),
    .i_data (acc_0_o_valid),
    .o_data (acc_0_o_valid_d)
);

shift_reg #(
    .LAT   (CU1_CU2_LAT),
    .WIDTH (1)
)
acc_c_shift_reg_1
(
    .clk    (clk),
    .rst    (rst),
    .i_data (acc_1_o_valid),
    .o_data (acc_1_o_valid_d)
);

shift_reg #(
    .LAT   (CU1_CU2_LAT),
    .WIDTH (1)
)
load_intt_shift_reg_1
(
    .clk    (clk),
    .rst    (rst),
    .i_data (load_intt),
    .o_data (load_intt_d1)
);

shift_reg #(
    .LAT   (CU2_CU3_LAT),
    .WIDTH (1)
)
load_intt_shift_reg_2
(
    .clk    (clk),
    .rst    (rst),
    .i_data (load_intt),
    .o_data (load_intt_d2)
);


shift_reg #(
    .LAT   (CU1_CU2_LAT),
    .WIDTH (1)
)
feed_intt_shift_reg_1
(
    .clk    (clk),
    .rst    (rst),
    .i_data (feed_intt),
    .o_data (feed_intt_d1)
);


shift_reg #(
    .LAT   (CU1_CU4_LAT),
    .WIDTH (1)
)
load_q_shift_reg_1
(
    .clk    (clk),
    .rst    (rst),
    .i_data (load_q),
    .o_data (load_q_d1)
);

shift_reg #(
    .LAT   (CU1_CU4_LAT),
    .WIDTH (LOGQH)
)
qH_shift_reg_1
(
    .clk    (clk),
    .rst    (rst),
    .i_data (qH),
    .o_data (qH_d1)
);

shift_reg #(
    .LAT   (CU1_CU2_LAT),
    .WIDTH (1)
)
load_q_shift_reg_2
(
    .clk    (clk),
    .rst    (rst),
    .i_data (load_q),
    .o_data (load_q_d2)
);

shift_reg #(
    .LAT   (CU1_CU2_LAT),
    .WIDTH (LOGQH)
)
qH_shift_reg_2
(
    .clk    (clk),
    .rst    (rst),
    .i_data (qH),
    .o_data (qH_d2)
);

shift_reg #(
    .LAT   (CU1_CU3_LAT),
    .WIDTH (1)
)
load_q_shift_reg_3
(
    .clk    (clk),
    .rst    (rst),
    .i_data (load_q),
    .o_data (load_q_d3)
);

shift_reg #(
    .LAT   (CU1_CU3_LAT),
    .WIDTH (LOGQH)
)
qH_shift_reg_3
(
    .clk    (clk),
    .rst    (rst),
    .i_data (qH),
    .o_data (qH_d3)
);

shift_reg #(
    .LAT   (CU2_CU3_LAT),
    .WIDTH (1)
)
i_psi_valid_shift_reg
(
    .clk    (clk),
    .rst    (rst),
    .i_data (done_base),
    .o_data (acc_rst)
);


// data path connections
generate
    for (genvar i = 0; i < TP; i = i + 1) begin
        assign ntt_i_poly     [i] = (intt)? ((acc_0_o_valid_d) ? acc_0_o_poly_d[TP] : acc_1_o_poly_d[TP]) : i_poly_data[i];
        assign fifo_i_data    [i] = ntt_o_poly    [i];
        assign had_0_i_poly_A [i] = fifo_o_data   [i];
        assign had_1_i_poly_A [i] = fifo_o_data   [i];
        assign had_0_i_poly_B [i] = i_rlk0_data   [i];
        assign had_1_i_poly_B [i] = i_rlk1_data   [i];
        assign acc_0_i_poly   [i] = had_0_o_poly  [i];
        assign acc_1_i_poly   [i] = had_1_o_poly  [i];
        assign fn_i_poly      [i] = ntt_o_poly    [i];
        assign o_poly_data    [i] = fn_o_poly     [i];
    end
endgenerate


// control path connections
assign ntt_i_valid = i_poly_valid | acc_0_o_valid_d | acc_1_o_valid_d;

assign fifo_wen = ntt_o_valid;
assign fifo_ren = i_rlk0_valid;

assign had_0_i_valid = i_rlk0_valid;
assign had_1_i_valid = i_rlk1_valid;

assign acc_0_wen = had_0_o_valid;
assign acc_1_wen = had_1_o_valid;

assign fn_rst = load_intt_d2;
assign fn_i_valid = ntt_o_valid;



endmodule