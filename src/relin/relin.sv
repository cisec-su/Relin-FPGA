`include "relin_if.svh"

module relin
   #(   
        parameter L        = 30       , // number of primes
        parameter LOGQ     = 64       ,
        parameter LOGQH    = 17       ,
        parameter LOGN     = 16       ,
        parameter LOGTP    = 5        , // coefficient throughput
        parameter FIFO_M   = 2        , // fifo depth = FIFO_M * (N / TP)
        parameter EN_ADD   = 1        , // perform the final addition
        parameter PSI_CC   = (1 << (LOGN - LOGTP)),

        parameter Q_MUX__NTT__DELAY         = 3 ,
        parameter Q_MUX__HAD__DELAY         = 3 ,
        parameter Q_MUX__ACC__DELAY         = 3 ,
        parameter Q_MUX__FN__DELAY          = 3 ,

        parameter CU_ACC__CU_P0_NTT__DELAY  = 3 ,
        parameter ACC0_REN__ACC1_REN__DELAY = 160*(1 << (LOGN-12)),

        parameter MAIN_FSM__CU_ACC__DELAY   = 3 ,
        parameter MAIN_FSM__FN__DELAY       = 3 ,
        parameter MAIN_FSM__CU_OUT___DELAY  = 3 ,

        parameter NTT_I__ACC_O__DELAY       = 3 ,
        parameter NTT_O__FIFO_I__DELAY      = 4
    )
    (
        input              clk   ,
        input              rst   ,
        input              start ,
        output         reg done  ,
        output         reg [10:0] relin_dbg_state,
        output          [4:0] accum_dbg_state_main,
        output          [2:0] accum_dbg_state_st12,
        output          [LOGK-1:0] read_addr0,
        output          [LOGK-1:0] write_addr0,
        output          [LOGL-1:0] accum_ctr0,
        output          [LOGL-1:0] accum_ctr1,
        output          [LOGL-1:0] cu_out_ctr,
        output          [10:0] cu_out_state,
        output      [15:0] cu_p0_state,
        output     [LOGL-1:0] ctr_L_out_cu_p0,
        output     [LOGL-1:0] ctr_L__out_cu_p0,
        output     [LOGL-1:0] ctr_poly_out_cu_p0,
        output      [10:0] state_p1_p2_out,
        output     [LOGL-1:0] ctr_L_out_p1_p2,
        output     [LOGL-1:0] ctr_L__out_p1_p2,
        output     [LOGL-1:0] ctr_out_p1_p2,
        output reg [LOGL-1:0] ctr_relin,
        output reg [LOGQ-1:0] ntt_valid_out_dbg,
        output reg [LOGQ-1:0] fifo_0_dbg_reg,
        output reg [LOGQ-1:0] fifo_1_dbg_reg,
        output reg [LOGQ-1:0] i_p1_data_d5_reg,
        output reg [LOGQ-1:0] i_p2_data_d5_reg,
        output reg [LOGQ-1:0] had_0_dbg_data,
        output reg [LOGQ-1:0] had_1_dbg_data,
        output reg [LOGQ-1:0] ntt_i_data_dbg,
        output reg [LOGQ-1:0] ntt_o_data_last_dbg,
        output reg [LOGQ-1:0] psi_i_data_dbg,
        output reg [LOGQ-1:0] fifo_0_i_data_dbg,
        output reg [LOGQ-1:0] fifo_1_i_data_dbg,
        output reg [LOGQ-1:0] had_0_i_poly_A_dbg,
        output reg [LOGQ-1:0] had_0_i_poly_B_dbg,
        output reg [LOGQ-1:0] had_1_i_poly_A_dbg,
        output reg [LOGQ-1:0] had_1_i_poly_B_dbg,
        output reg [LOGQ-1:0] acc_i_poly_0_dbg,
        output reg [LOGQ-1:0] acc_i_poly_1_dbg,
        output reg [LOGQ-1:0] acc_o_data_dbg,
        output reg [LOGQ-1:0] intt_i_poly_dbg,
        output reg [LOGQ-1:0] fn_i_poly_dbg,
        output reg [LOGQ-1:0] fn_o_poly_dbg,
        output reg [LOGQ-1:0] ntt_i_data_last_dbg,
        output reg [LOGQ-1:0] had_0_i_poly_last,
        output reg [LOGQ-1:0] had_1_i_poly_last,
        output reg [LOGQ-1:0] had_0_o_poly_last,
        output reg [LOGQ-1:0] had_1_o_poly_last,
        output reg [LOGQ-1:0] acc_i_0_poly_last,
        output reg [LOGQ-1:0] acc_i_1_poly_last,
        output reg [LOGQ-1:0] acc_o_poly_last,
        output reg [LOGQ-1:0] intt_i_poly_last,
        output reg [LOGQ-1:0] fn_i_poly_last,
        output reg [LOGQ-1:0] fn_o_poly_last,
        output reg [LOGQ-1:0] acc_i_poly_0_dbg_4,
        output reg [LOGQ-1:0] acc_i_0_poly_last_4,
        output reg [LOGQ-1:0] acc_i_poly_0_dbg_8,
        output reg [LOGQ-1:0] acc_i_0_poly_last_8,
        output reg [LOGQ-1:0] acc_i_poly_0_dbg_16,
        output reg [LOGQ-1:0] acc_i_0_poly_last_16,
        output reg [LOGQ-1:0] acc_i_poly_0_dbg_20,
        output reg [LOGQ-1:0] acc_i_0_poly_last_20,
        output reg [LOGQ-1:0] acc_i_poly_0_dbg_27,
        output reg [LOGQ-1:0] acc_i_0_poly_last_27,
        output reg [LOGQ-1:0] had_0_i_poly_last_B,
        output reg [2:0] ctr_start_sig,
        relin_t.master     relin_t
    );


/////////////////////////////////////////////////////////////////////////////////////////

`include "relin_mem.svh"

localparam LOGK = LOGN - LOGTP;
localparam K = 1 << LOGK;
localparam LOGL = $rtoi($ceil($clog2(L + 1)));
localparam TP = 1 << LOGTP;
localparam ID_WIDTH = $rtoi($ceil($clog2(`NUM_MEM_OBJ)));

localparam FORCE_ACC_DONE = 1'b1;

/////////////////////////////////////////////////////////////////////////////////////////

always @(posedge clk) begin
    ctr_relin <= ctr;
end


wire [LOGQH-1:0] qH_ntt, qH_had, qH_acc, qH_fn;
wire [LOGQ-1:0] half_fn;
wire [LOGQ-1:0] q_inv_fn;
// fsm <-> ntt, hadamard, accumulator, final_op
reg load_q_g1;
reg load_q_g2;
wire load_q_ntt, load_q_had, load_q_acc, load_q_fn, fn_load_q_start;
wire load_q_g1_d;
// mem
wire i_p0_en, i_p0_valid, i_p0_done;
wire [LOGQ-1:0] i_p0_data [TP-1:0];
wire [ID_WIDTH-1:0] i_p0_id;
wire [LOGL-1:0] i_p0_idx;
wire i_p1_en, i_p1_valid, i_p1_done;
wire [LOGQ-1:0] i_p1_data [TP-1:0];
wire [LOGQ-1:0] i_p1_data_d [TP-1:0];
wire [ID_WIDTH-1:0] i_p1_id;
wire [LOGL-1:0] i_p1_idx;
wire [LOGL-1:0] i_p1_idy;
wire i_p2_en, i_p2_valid, i_p2_done;
wire [LOGQ-1:0] i_p2_data [TP-1:0];
wire [LOGQ-1:0] i_p2_data_d [TP-1:0];
wire [LOGL-1:0] i_p2_idx;
wire [LOGL-1:0] i_p2_idy;
wire o_p3_en, o_p3_done;
wire [LOGQ-1:0] o_p3_data [TP-1:0];
wire [ID_WIDTH-1:0] o_p3_id;
wire [LOGL-1:0] o_p3_idx;
// delayed mem
wire i_p1_valid_d, i_p2_valid_d;
wire i_p1_valid_d1, i_p2_valid_d1;
wire [LOGQ-1:0] i_p2_data_d8 [TP-1:0];
// ntt control path
wire intt;
wire ntt_i_valid, intt_i_valid, psi_i_valid, psi_inv_i_valid, feed_psi, psi_r_done;
wire ntt_o_valid, intt_o_valid;
// ntt data path
wire [LOGQ-1:0] ntt_i_poly [TP-1:0];
wire [LOGQ-1:0] intt_i_poly [TP-1:0];
wire [LOGQ-1:0] ntt_i_psi [TP-1:0];
wire [LOGQ-1:0] ntt_o_poly [TP-1:0];
// fifo control path
wire fifo_0_ren, fifo_0_wen;
wire fifo_1_ren, fifo_1_wen;
// wire p1_dis;
// fifo data path
wire [LOGQ-1:0] fifo_0_i_data [TP-1:0];
wire [LOGQ-1:0] fifo_0_o_data [TP-1:0];
wire [LOGQ-1:0] fifo_1_i_data [TP-1:0];
wire [LOGQ-1:0] fifo_1_o_data [TP-1:0];
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
wire acc_i_valid_0, acc_i_valid_1;
wire acc_o_valid;
// accumulator data path
wire [LOGQ-1:0] acc_i_poly_0 [TP-1:0];
wire [LOGQ-1:0] acc_i_poly_1 [TP-1:0];
wire [LOGQ-1:0] acc_o_poly   [TP-1:0];
// final op control path
wire fn_i_valid;
wire fn_o_valid;
wire fn_i_done;
// final op data path
wire [LOGQ-1:0] fn_i_poly_A [TP-1:0];
wire [LOGQ-1:0] fn_i_poly_B [TP-1:0];
wire [LOGQ-1:0] fn_o_poly   [TP-1:0];
// cu_p0_ntt <-> cu_p1_p2
// wire acc_write_done;
wire acc_start_read;

wire i_p1_valid_d1, i_p2_valid_d1;


wire o_valid;
reg cu_p0_start;
reg cu_out_start;

wire cu_p0_load_intt, cu_p0_intt_ready;

wire done_write;


wire [LOGQ-1:0] ntt_o_poly_d [TP-1:0];
wire [LOGQ-1:0] ntt_o_poly_d_0 [TP-1:0];
wire [LOGQ-1:0] ntt_o_poly_d_1 [TP-1:0];
wire intt_o_valid_d, intt_o_valid_d1, intt_o_valid_d2;
wire ntt_o_valid_d;

reg p1_sel;

relin_q_loader #(
    .LOGN    (LOGN   ),
    .L       (L      ),
    .LOGQ    (LOGQ   ),
    .LOGQH   (LOGQH  ),
    .DELAY_G1_A (Q_MUX__NTT__DELAY),
    .DELAY_G1_B (Q_MUX__HAD__DELAY),
    .DELAY_G1_C (Q_MUX__ACC__DELAY),
    .DELAY_G2_A (Q_MUX__FN__DELAY )
) relin_q_loader_inst (
    .clk     (clk    ),
    .rst     (rst    ),
    .load_q_g1(load_q_g1),
    .load_q_g2(load_q_g2),//fn_load_q_start),
    .qH_g1_A (qH_ntt ),
    .qH_g1_B (qH_had ),
    .qH_g1_C (qH_acc ),
    .qH_g2_A (qH_fn  ),
    .half_g2_A (half_fn),
    .q_inv_g2_A(q_inv_fn),
    .load_q_g1_A(load_q_ntt),
    .load_q_g1_B(load_q_had),
    .load_q_g1_C(load_q_acc),
    .load_q_g2_A(load_q_fn) ,
    .done_g1(load_q_g1_d)
);


relin_mem #(
    .LOGQ    (LOGQ    ),
    .LOGN    (LOGN    ),
    .LOGL    (LOGL    ),
    .ID_WIDTH(ID_WIDTH),
    .TP      (TP      )
) relin_mem_inst (
    .clk        (clk        ),
    .rst        (rst        ),
    .i_p0_en    (i_p0_en    ),
    .i_p0_id   (i_p0_id   ),
    .i_p0_idx   (i_p0_idx   ),
    .i_p0_valid (i_p0_valid ),
    .i_p0_done  (i_p0_done  ),
    .i_p0_data  (i_p0_data  ),
    .i_p1_en    (i_p1_en    ),
    .i_p1_id    (i_p1_id    ),
    .i_p1_idx   (i_p1_idx   ),
    .i_p1_idy   (i_p1_idy   ),
    .i_p1_valid (i_p1_valid ),
    .i_p1_done  (i_p1_done  ),
    .i_p1_data  (i_p1_data  ),
    .i_p2_en    (i_p2_en    ),
    .i_p2_idx   (i_p2_idx   ),
    .i_p2_idy   (i_p2_idy   ),
    .i_p2_valid (i_p2_valid ),
    .i_p2_done  (i_p2_done  ),
    .i_p2_data  (i_p2_data  ),
    .o_p3_en    (o_p3_en    ),
    .o_p3_id    (o_p3_id    ),
    .o_p3_idx   (o_p3_idx   ),
    .o_p3_done  (o_p3_done  ),
    .o_p3_data  (o_p3_data  ),
    .relin_t    (relin_t    )
);


relin_cu_p0_ntt #(
    .L              (L       ),
    .ID_WIDTH       (ID_WIDTH),
    .DEPTH          (K       )
) relin_cu_p0_ntt_inst (
    .clk        (clk           ),
    .rst        (rst           ),
    .start      (cu_p0_start   ),
    // .load_intt  (cu_p0_load_intt),
    .i_p0_en    (i_p0_en       ),
    .i_p0_valid (i_p0_valid    ),
    .i_p0_id    (i_p0_id       ),
    .i_p0_idx   (i_p0_idx      ),
    .i_p0_done  (i_p0_done     ),
    .ntt_i_valid(ntt_i_valid   ),
    .psi_i_valid(psi_i_valid   ),
    .psi_inv_i_valid(psi_inv_i_valid   ),
    .intt_ready (cu_p0_intt_ready),
    .relin_cu_p0_state(cu_p0_state),
    .ctr_L_out  (ctr_L_out_cu_p0 ),
    .ctr_L__out (ctr_L__out_cu_p0 ),
    .ctr_poly_out(ctr_poly_out_cu_p0  )

);

relin_ntt_mux #(
    .LOGQ (LOGQ ),
    .LOGQH(LOGQH),
    .LOGN (LOGN ),
    .LOGTP(LOGTP),
    .INTT_DELAY(NTT_I__ACC_O__DELAY),
    .PSI_CC(PSI_CC)
) relin_ntt_mux_inst (
    .clk           (clk           ),
    .rst           (rst           ),
    .load_q        (load_q_ntt    ),
    .psi_valid     (psi_i_valid   ),
    .psi_inv_valid     (psi_inv_i_valid   ),
    .qH            (qH_ntt        ),
    .i_valid_ntt   (ntt_i_valid   ),
    .i_valid_intt  (intt_i_valid  ),
    .i_poly_ntt    (ntt_i_poly    ),
    .i_poly_intt   (intt_i_poly   ),
    .psi           (ntt_i_psi     ),
    .o_poly        (ntt_o_poly    ),
    .o_valid_ntt   (ntt_o_valid   ),
    .o_valid_intt  (intt_o_valid  )
);


relin_cu_p1_p2 #(
    .L(L),
    .ID_WIDTH(ID_WIDTH),
    .EN_ADD(EN_ADD)
) relin_cu_p1_p2_inst (
    .clk       (clk        ),
    .rst       (rst        ),
    .en_rlk    (ntt_o_valid_d ),
    .en_poly   (intt_o_valid_d && (ctr != 0)),
    .i_p1_en   (i_p1_en    ),
    .i_p1_id   (i_p1_id    ),
    .i_p1_idx  (i_p1_idx   ),
    .i_p1_idy  (i_p1_idy   ),
    .i_p1_valid(i_p1_valid ),
    .i_p1_done (i_p1_done  ),
    .i_p2_en   (i_p2_en    ),
    .i_p2_idx  (i_p2_idx   ),
    .i_p2_idy  (i_p2_idy   ),
    .i_p2_done (i_p2_done  ),
    .state_p1_p2_out(state_p1_p2_out),
    .ctr_L_out(ctr_L_out_p1_p2),
    .ctr_L__out(ctr_L__out_p1_p2),
    .ctr_out(ctr_out_p1_p2)  
);


relin_fifo #(
    .K   (K     ),
    .M   (FIFO_M),
    .TP  (TP    ),
    .LOGQ(LOGQ  )
) relin_fifo_inst_0 (
    .clk(clk),
    .rst(rst),
    .ren(fifo_0_ren),
    .wen(fifo_0_wen),
    .i_data(fifo_0_i_data),
    .o_data(fifo_0_o_data)
);


relin_fifo #(
    .K   (K     ),
    .M   (FIFO_M),
    .TP  (TP    ),
    .LOGQ(LOGQ  )
) relin_fifo_inst_1 (
    .clk(clk),
    .rst(rst),
    .ren(fifo_1_ren),
    .wen(fifo_1_wen),
    .i_data(fifo_1_i_data),
    .o_data(fifo_1_o_data)
);


relin_hadamard #(
    .LOGQ (LOGQ ),
    .LOGQH(LOGQH),
    .TP   (TP   )
) relin_hadamard_inst_0 (
    .clk    (clk           ),
    .rst    (rst           ),
    .qH     (qH_had        ),
    .load_q (load_q_had    ),
    .i_valid(had_0_i_valid ),
    .o_valid(had_0_o_valid ),
    .A      (had_0_i_poly_A),
    .B      (had_0_i_poly_B),
    .C      (had_0_o_poly  )
);


relin_hadamard #(
    .LOGQ (LOGQ ),
    .LOGQH(LOGQH),
    .TP   (TP   )
) relin_hadamard_inst_1  (
    .clk    (clk           ),
    .rst    (rst           ),
    .qH     (qH_had        ),
    .load_q (load_q_had    ),
    .i_valid(had_1_i_valid ),
    .o_valid(had_1_o_valid ),
    .A      (had_1_i_poly_A),
    .B      (had_1_i_poly_B),
    .C      (had_1_o_poly  )
);


relin_accum_wrapper #(
    .L          (L),
    .START_DELAY(CU_ACC__CU_P0_NTT__DELAY),
    .READ_DELAY (ACC0_REN__ACC1_REN__DELAY),
    .LOGK  (LOGN-LOGTP),
    .LOGQ  (LOGQ      ),
    .LOGQH (LOGQH     ),
    .LOGTP (LOGTP     )
) relin_accum_wrapper_inst (
    .clk     (clk          ),
    .rst     (rst          ),
    .start_read (acc_start_read),
    .accum_dbg_state_st12 (accum_dbg_state_st12),
    .accum_dbg_state_main  (accum_dbg_state_main),
    .ctr_0_out(accum_ctr0),
    .ctr_1_out(accum_ctr1),
    // .write_done (acc_write_done),
    .load_q  (load_q_acc   ),
    .qH      (qH_acc       ),
    .i_valid_0 (acc_i_valid_0),
    .i_poly_0  (acc_i_poly_0 ),
    .i_valid_1 (acc_i_valid_1),
    .i_poly_1  (acc_i_poly_1 ),
    .o_valid (acc_o_valid),
    .o_poly  (acc_o_poly ),
    .read_addr0(read_addr0),
    .write_addr0(write_addr0)
);


relin_final_op_wrapper #(
    .LOGQ  (LOGQ      ),
    .LOGQH (LOGQH     ),
    .LOGK  (LOGN-LOGTP),
    .LOGTP (LOGTP     ),
    .FIFO_M(FIFO_M    ),
    .EN_ADD(EN_ADD    ),
    .L     (L         )
) relin_final_op_inst (
    .clk    (clk          ),
    .rst    (rst          ),
    .load_q (load_q_fn    ),
    .qH     (qH_fn        ),
    .i_valid(fn_i_valid   ),
    .halfmod(half_fn      ),
    .q_inv  (q_inv_fn     ),
    .A      (fn_i_poly_A  ),
    .B      (fn_i_poly_B  ),
    .o_valid(fn_o_valid   ),
    .i_done (fn_i_done    ),
    .C      (fn_o_poly    )
);


relin_cu_out #(
    .L           (L       ),
    .ID_WIDTH    (ID_WIDTH)
) relin_cu_out_inst (
    .clk         (clk           ),
    .rst         (rst           ),
    .o_valid     (o_valid       ),
    .o_p3_done   (o_p3_done     ),
    .o_p3_id     (o_p3_id       ),
    .o_p3_idx    (o_p3_idx      ),
    .o_p3_en     (o_p3_en       ),
    .done        (done_write    ),
    .ctr_out     (cu_out_ctr),
    .state_out   (cu_out_state)
); 


shift_reg #(
    .LAT   (NTT_O__FIFO_I__DELAY),
    .WIDTH (1)
)
intt_o_valid_shift_reg
(
    .clk    (clk         ),
    .rst    (rst         ),
    .i_data (intt_o_valid  ),
    .o_data (intt_o_valid_d)
);

shift_reg #(
    .LAT   (1),
    .WIDTH (1)
)
intt_o_valid_shift_reg1
(
    .clk    (clk         ),
    .rst    (rst         ),
    .i_data (intt_o_valid_d ),
    .o_data (intt_o_valid_d1)
);

shift_reg #(
    .LAT   (1),
    .WIDTH (1)
)
intt_o_valid_shift_reg2
(
    .clk    (clk         ),
    .rst    (rst         ),
    .i_data (intt_o_valid_d1),
    .o_data (intt_o_valid_d2)
);


shift_reg #(
    .LAT   (NTT_O__FIFO_I__DELAY),
    .WIDTH (1)
)
ntt_o_valid_shift_regd4
(
    .clk    (clk         ),
    .rst    (rst         ),
    .i_data (ntt_o_valid  ),
    .o_data (ntt_o_valid_d)
);


shift_reg_arr #(
    .LAT    (NTT_O__FIFO_I__DELAY),
    .WIDTH  (LOGQ          ),
    .LENGTH (TP            ),
    .RST_EN (0             )
) ntt_o_poly_shift_reg_d4_1 (
    .clk    (clk         ),
    .i_data (ntt_o_poly  ),
    .o_data (ntt_o_poly_d_0)
);

shift_reg_arr #(
    .LAT    (NTT_O__FIFO_I__DELAY),
    .WIDTH  (LOGQ          ),
    .LENGTH (TP            ),
    .RST_EN (0             )
) ntt_o_poly_shift_reg_d4_2 (
    .clk    (clk         ),
    .i_data (ntt_o_poly  ),
    .o_data (ntt_o_poly_d_1)
);

shift_reg_arr #(
    .LAT    (NTT_O__FIFO_I__DELAY + 1),
    .WIDTH  (LOGQ          ),
    .LENGTH (TP            ),
    .RST_EN (0             )
) had_0_poly_data_b_delay (
    .clk    (clk         ),
    .i_data (i_p1_data   ),
    .o_data (i_p1_data_d )
);

shift_reg_arr #(
    .LAT    (NTT_O__FIFO_I__DELAY + 1),
    .WIDTH  (LOGQ          ),
    .LENGTH (TP            ),
    .RST_EN (0             )
) had_1_poly_data_b_delay (
    .clk    (clk         ),
    .i_data (i_p2_data   ),
    .o_data (i_p2_data_d )
);

// shift_reg #(
//     .LAT   (3),
//     .WIDTH (1)
// )
// i_p1_valid_shift_reg
// (
//     .clk    (clk         ),
//     .rst    (rst         ),
//     .i_data (i_p1_valid  ),
//     .o_data (i_p1_valid_d3)
// );

// shift_reg #(
//     .LAT   (3),
//     .WIDTH (1)
// )
// i_p2_valid_shift_reg
// (
//     .clk    (clk         ),
//     .rst    (rst         ),
//     .i_data (i_p2_valid  ),
//     .o_data (i_p2_valid_d3)
// );

shift_reg #(
    .LAT   (NTT_O__FIFO_I__DELAY),
    .WIDTH (1)
)
i_p2_valid_shift_regd4
(
    .clk    (clk         ),
    .rst    (rst         ),
    .i_data (i_p2_valid  ),
    .o_data (i_p2_valid_d)
);

shift_reg #(
    .LAT   (1),
    .WIDTH (1)
)
i_p2_valid_shift_regd5
(
    .clk    (clk         ),
    .rst    (rst         ),
    .i_data (i_p2_valid_d ),
    .o_data (i_p2_valid_d1)
);

shift_reg #(
    .LAT   (NTT_O__FIFO_I__DELAY),
    .WIDTH (1)
)
i_p1_valid_shift_regd4
(
    .clk    (clk        ),
    .rst    (rst        ),
    .i_data (i_p1_valid ),
    .o_data (i_p1_valid_d)
);

shift_reg #(
    .LAT   (1),
    .WIDTH (1)
)
i_p1_valid_shift_regd3
(
    .clk    (clk         ),
    .rst    (rst         ),
    .i_data (i_p1_valid_d ),
    .o_data (i_p1_valid_d1)
);

reg ntt_o_valid_d5, ntt_o_valid_d6;

reg fifo_1_ren_reg, fifo_1_ren_reg_d2;
reg fifo_0_ren_reg, fifo_0_ren_reg_d2;

reg had_0_o_valid_reg, had_0_o_valid_regd2;
reg had_1_o_valid_reg, had_1_o_valid_regd2;

always @(posedge clk) begin
    if (rst) begin
        ntt_o_valid_d5 <= 1'b0;
        ntt_o_valid_d6 <= 1'b0;
        fifo_0_ren_reg <= 'b0;
        fifo_0_ren_reg_d2 <= 'b0;
        fifo_1_ren_reg <= 'b0;
        fifo_1_ren_reg_d2 <= 'b0;
        had_0_o_valid_reg <= 'b0;
        had_0_o_valid_regd2 <= 'b0;
        had_1_o_valid_reg <= 'b0;
        had_1_o_valid_regd2 <= 'b0;

    end
    else begin
        ntt_o_valid_d5 <= ntt_o_valid_d;
        ntt_o_valid_d6 <= ntt_o_valid_d5;
        fifo_0_ren_reg <= fifo_0_ren;
        fifo_0_ren_reg_d2 <= fifo_0_ren_reg;
        fifo_1_ren_reg <= fifo_1_ren;
        fifo_1_ren_reg_d2 <= fifo_1_ren_reg;
        had_0_o_valid_reg <= had_0_o_valid;
        had_0_o_valid_regd2 <= had_0_o_valid_reg;
        had_1_o_valid_reg <= had_1_o_valid;
        had_1_o_valid_regd2 <= had_1_o_valid_reg;
    end
end

wire ntt_i_valid_d2, psi_i_valid_d2, fifo_0_i_valid_d2, fifo_1_i_valid_d2;

shift_reg #(
    .LAT   (2),
    .WIDTH (1)
)
ntt_i_valid_shift
(
    .clk    (clk         ),
    .rst    (rst         ),
    .i_data (ntt_i_valid  ),
    .o_data (ntt_i_valid_d2)
);

shift_reg #(
    .LAT   (2),
    .WIDTH (1)
)
psi_i_valid_shift
(
    .clk    (clk         ),
    .rst    (rst         ),
    .i_data (psi_i_valid  ),
    .o_data (psi_i_valid_d2)
);

shift_reg #(
    .LAT   (2),
    .WIDTH (1)
)
fifo_0_i_valid_shift
(
    .clk    (clk         ),
    .rst    (rst         ),
    .i_data (fifo_0_wen  ),
    .o_data (fifo_0_i_valid_d2)
);

shift_reg #(
    .LAT   (2),
    .WIDTH (1)
)
fifo_1_i_valid_shift
(
    .clk    (clk         ),
    .rst    (rst         ),
    .i_data (fifo_1_wen  ),
    .o_data (fifo_1_i_valid_d2)
);

shift_reg #(
    .LAT   (2),
    .WIDTH (1)
)
had_0_i_valid_shift
(
    .clk    (clk           ),
    .rst    (rst           ),
    .i_data (had_0_i_valid ),
    .o_data (had_0_i_valid_d2)
);

shift_reg #(
    .LAT   (2),
    .WIDTH (1)
)
had_1_i_valid_shift
(
    .clk    (clk           ),
    .rst    (rst           ),
    .i_data (had_1_i_valid ),
    .o_data (had_1_i_valid_d2)
);

shift_reg #(
    .LAT   (2),
    .WIDTH (1)
)
acc_i_valid_0_shift
(
    .clk    (clk             ),
    .rst    (rst             ),
    .i_data (acc_i_valid_0   ),
    .o_data (acc_i_valid_0_d2)
);

shift_reg #(
    .LAT   (2),
    .WIDTH (1)
)
acc_i_valid_1_shift
(
    .clk    (clk             ),
    .rst    (rst             ),
    .i_data (acc_i_valid_1   ),
    .o_data (acc_i_valid_1_d2)
);

shift_reg #(
    .LAT   (2),
    .WIDTH (1)
)
acc_o_valid_shift
(
    .clk    (clk          ),
    .rst    (rst          ),
    .i_data (acc_o_valid  ),
    .o_data (acc_o_valid_d2)
);

shift_reg #(
    .LAT   (2),
    .WIDTH (1)
)
intt_i_valid_shift
(
    .clk    (clk           ),
    .rst    (rst           ),
    .i_data (intt_i_valid  ),
    .o_data (intt_i_valid_d2)
);

shift_reg #(
    .LAT   (2),
    .WIDTH (1)
)
fn_i_valid_shift
(
    .clk    (clk         ),
    .rst    (rst         ),
    .i_data (fn_i_valid  ),
    .o_data (fn_i_valid_d2)
);

shift_reg #(
    .LAT   (2),
    .WIDTH (1)
)
fn_o_valid_shift
(
    .clk    (clk         ),
    .rst    (rst         ),
    .i_data (fn_o_valid  ),
    .o_data (fn_o_valid_d2)
);






reg [1:0] ctr_ntt_i_valid      = 2'b00;
reg [1:0] ctr_psi_i_valid      = 2'b00;
reg [1:0] ctr_fifo_0_i_valid   = 2'b00;
reg [1:0] ctr_fifo_1_i_valid   = 2'b00;
reg [1:0] ctr_had_0_i_valid    = 2'b00;
reg [1:0] ctr_had_1_i_valid    = 2'b00;

reg [1:0] ctr_accum_1_i_valid  = 2'b00;
reg [1:0] ctr_acc_o_valid      = 2'b00;
reg [1:0] ctr_intt_i_valid     = 2'b00;
reg [1:0] ctr_fn_i_valid       = 2'b00;
reg [1:0] ctr_fn_o_valid       = 2'b00;

reg [4:0] ctr_accum_0_i_valid       = 5'b00000;
reg [4:0] ctr_accum_0_i_valid_4     = 5'b00000;
reg [4:0] ctr_accum_0_i_valid_8     = 5'b00000;
reg [4:0] ctr_accum_0_i_valid_16    = 5'b00000;
reg [4:0] ctr_accum_0_i_valid_20    = 5'b00000;
reg [4:0] ctr_accum_0_i_valid_27    = 5'b00000;

reg [10:0] ctr_to_last, ctr_to_last_ntt_o, ctr_to_had_0_o_poly_last, ctr_to_had_1_o_poly_last, ctr_to_had_0_i_poly_last, ctr_to_had_1_i_poly_last, ctr_to_accum_i_0_last, ctr_to_accum_i_1_last, ctr_to_accum_o_last, ctr_to_intt_i_last, ctr_to_fn_i_last, ctr_to_fn_o_last;

reg [1:0] count, count_ntt_o_data, count_had_0_o_poly, count_had_1_o_poly, count_had_0_i_poly, count_had_1_i_poly, count_accum_0, count_accum_i_1, count_accum_o_last, count_intt_i_poly_last, count_fn_i_poly_last, count_fn_o_poly_last, count_accum_0_4, count_accum_0_8, count_accum_0_16, count_accum_0_20, count_accum_0_27;

reg [10:0] ctr_to_accum_i_0_last_4, ctr_to_accum_i_0_last_8, ctr_to_accum_i_0_last_16, ctr_to_accum_i_0_last_20, ctr_to_accum_i_0_last_27;


reg [4:0] ctr_acc_in;

always @(posedge clk) begin
    if (rst) begin
        ctr_acc_in <= 'b0;
    end
    else begin
        if (acc_i_valid_0_d2) begin
            ctr_acc_in <= ctr_acc_in + 1;
        end
    end
end

always @(posedge clk) begin
    if (rst) begin
        ntt_valid_out_dbg <= 'b0;
        fifo_0_dbg_reg <= 'b0;
        fifo_1_dbg_reg <= 'b0;
        i_p1_data_d5_reg <= 'b0;
        i_p2_data_d5_reg <= 'b0;
        had_0_dbg_data <= 'b0;
        had_1_dbg_data <= 'b0;
        ctr_start_sig <= 'b0;
        ctr_to_last <= 'b0;
        count       <= 'b0;
        count_ntt_o_data  <= 'b0;
        ctr_to_last_ntt_o <= 'b0;
        count_had_0_o_poly <= 'b0;
        count_had_1_o_poly <= 'b0;
        count_had_0_i_poly <= 'b0;
        count_had_1_i_poly <= 'b0;
        ctr_to_had_0_o_poly_last <= 'b0;
        ctr_to_had_1_o_poly_last <= 'b0;
        ctr_to_had_0_i_poly_last <= 'b0;
        ctr_to_had_1_i_poly_last <= 'b0;
        count_accum_0 <= 'b0;
        ctr_to_accum_i_0_last <= 'b0;
        ctr_to_accum_i_0_last_4 <= 'b0;
        ctr_to_accum_i_0_last_8 <= 'b0;
        ctr_to_accum_i_0_last_16 <= 'b0;
        ctr_to_accum_i_0_last_20 <= 'b0;
        ctr_to_accum_i_0_last_27 <= 'b0;
        count_accum_0_4 <= 'b0;
        count_accum_0_8 <= 'b0;
        count_accum_0_16 <= 'b0;
        count_accum_0_20 <= 'b0;
        count_accum_0_27 <= 'b0;
        count_accum_i_1 <= 'b0;
        ctr_to_accum_i_1_last <= 'b0;
        count_accum_o_last <= 'b0;
        ctr_to_accum_o_last <= 'b0;
        count_intt_i_poly_last <= 'b0;
        ctr_to_intt_i_last <= 'b0;
        count_fn_i_poly_last <= 'b0;
        ctr_to_fn_i_last <= 'b0;
        ctr_to_fn_o_last <= 'b0;
        count_fn_o_poly_last <= 'b0;
    end
    else begin
        if (ntt_o_valid_d6 && ntt_valid_out_dbg == 'b0) begin
            ntt_valid_out_dbg <= ntt_o_poly_d_0[0];
            count_ntt_o_data <= count_ntt_o_data == 2'b00 ? 2'b01: count_ntt_o_data;
        end
         if (count_ntt_o_data == 2'b01) begin
            ctr_to_last_ntt_o <= ctr_to_last_ntt_o + 1;
        end
        if (ctr_to_last_ntt_o == K - 4) begin
            ntt_o_data_last_dbg <= ntt_o_poly_d_0[0];
            count_ntt_o_data <= 2'b10;
        end
        if (fifo_0_ren_reg_d2 && fifo_0_dbg_reg == 'b0) begin
            i_p1_data_d5_reg <= i_p1_data_d[0];
            fifo_0_dbg_reg <= fifo_0_o_data[0];
        end
        if (fifo_1_ren_reg_d2 && fifo_1_dbg_reg == 'b0) begin
            i_p2_data_d5_reg <= i_p2_data_d[0];
            fifo_1_dbg_reg <= fifo_1_o_data[0];
        end
        if (had_0_o_valid_regd2 && had_0_dbg_data == 'b0) begin
            had_0_dbg_data <= had_0_o_poly[0];
            count_had_0_o_poly <= count_had_0_o_poly == 2'b00 ? 2'b01: count_had_0_o_poly;
        end
        if (count_had_0_o_poly == 2'b01) begin
            ctr_to_had_0_o_poly_last <= ctr_to_had_0_o_poly_last + 1;
        end
        if (ctr_to_had_0_o_poly_last == K - 4) begin
            had_0_o_poly_last <= had_0_o_poly[0];
            count_had_0_o_poly <= 2'b10;
        end
        if (had_1_o_valid_regd2 && had_1_dbg_data == 'b0) begin
            had_1_dbg_data <= had_1_o_poly[0];
            count_had_1_o_poly <= count_had_1_o_poly == 2'b00 ? 2'b01: count_had_1_o_poly;
        end
        if (count_had_1_o_poly == 2'b01) begin
            ctr_to_had_1_o_poly_last <= ctr_to_had_1_o_poly_last + 1;
        end
        if (ctr_to_had_1_o_poly_last == K - 4) begin
            had_1_o_poly_last <= had_1_o_poly[0];
            count_had_1_o_poly <= 2'b10;
        end
        if (ntt_i_valid_d2 && ctr_ntt_i_valid == 'b0) begin
            ctr_ntt_i_valid <= 2'd2;
            ntt_i_data_dbg <= ntt_i_poly[0];
            count <= count == 2'b00 ? 2'b01: count;
        end
        if (ntt_i_valid_d2 == 1'b1) begin
            ctr_start_sig <= ctr_start_sig + 1;
        end
        if (count == 2'b01) begin
            ctr_to_last <= ctr_to_last + 1;
        end
        if (ctr_to_last == K - 4) begin
            ntt_i_data_last_dbg <= ntt_i_poly[0];
            count <= 2'b10;
        end
        if (psi_i_valid_d2 && ctr_psi_i_valid == 'b0) begin
            ctr_psi_i_valid <= 2'd2;
            psi_i_data_dbg <= ntt_i_psi[0];
        end
        if (fifo_0_i_valid_d2 && ctr_fifo_0_i_valid == 'b0) begin
            ctr_fifo_0_i_valid <= 2'd2;
            fifo_0_i_data_dbg <= ntt_o_poly_d_0[0];
        end
        if (fifo_1_i_valid_d2 && ctr_fifo_1_i_valid == 'b0) begin
            ctr_fifo_1_i_valid <= 2'd2;
            fifo_1_i_data_dbg <= ntt_o_poly_d_1[0];
        end
        if (had_0_i_valid_d2 && ctr_had_0_i_valid == 'b0 && ctr_acc_in == 8'd15) begin
            ctr_had_0_i_valid <= 2'd2;
            had_0_i_poly_A_dbg <= had_0_i_poly_A[0];
            had_0_i_poly_B_dbg <= had_0_i_poly_B[0];
            count_had_0_i_poly <= count_had_0_i_poly == 2'b00 ? 2'b01: count_had_0_i_poly;
        end
        if (count_had_0_i_poly == 2'b01) begin
            ctr_to_had_0_i_poly_last <= ctr_to_had_0_i_poly_last + 1;
        end
        if (ctr_to_had_0_i_poly_last == K - 4) begin
            had_0_i_poly_last <= had_0_i_poly_A[0];
            had_0_i_poly_last_B <= had_0_i_poly_B[0];
            count_had_0_i_poly <= 2'b10;
        end
        if (had_1_i_valid_d2 && ctr_had_1_i_valid == 'b0) begin
            ctr_had_1_i_valid <= 2'd2;
            had_1_i_poly_A_dbg <= had_1_i_poly_A[0];
            had_1_i_poly_B_dbg <= had_1_i_poly_B[0];
            count_had_1_i_poly <= count_had_1_i_poly == 2'b00 ? 2'b01: count_had_1_i_poly;
        end
        if (count_had_1_i_poly == 2'b01) begin
            ctr_to_had_1_i_poly_last <= ctr_to_had_1_i_poly_last + 1;
        end
        if (ctr_to_had_1_i_poly_last == K - 4) begin
            had_1_i_poly_last <= had_1_i_poly_A[0];
            count_had_1_i_poly <= 2'b10;
        end
        if (acc_i_valid_0_d2 && ctr_accum_0_i_valid == 'b0 && ctr_acc_in == 5'd0) begin
            ctr_accum_0_i_valid <= 2'd2;
            acc_i_poly_0_dbg <= acc_i_poly_0[0];
            count_accum_0 <= count_accum_0 == 2'b00 ? 2'b01: count_accum_0;
        end
        if (count_accum_0 == 2'b01) begin
            ctr_to_accum_i_0_last <= ctr_to_accum_i_0_last + 1;
        end
        if (ctr_to_accum_i_0_last == K - 4) begin
            acc_i_0_poly_last <= acc_i_poly_0[0];
            count_accum_0 <= 2'b10;
        end
        if (acc_i_valid_1_d2 && ctr_accum_1_i_valid == 'b0) begin
            ctr_accum_1_i_valid <= 2'd2;
            acc_i_poly_1_dbg <= acc_i_poly_1[0];
            count_accum_i_1 <= count_accum_i_1 == 2'b00 ? 2'b01: count_accum_i_1;
        end
        if (count_accum_i_1 == 2'b01) begin
            ctr_to_accum_i_1_last <= ctr_to_accum_i_1_last + 1;
        end
        if (ctr_to_accum_i_1_last == K - 4) begin
            acc_i_1_poly_last <= acc_i_poly_1[0];
            count_accum_i_1 <= 2'b10;
        end
        if (acc_o_valid_d2 &&  ctr_acc_o_valid == 'b0) begin
            ctr_acc_o_valid <= 2'd2;
            acc_o_data_dbg <= acc_o_poly[0];
            count_accum_o_last <= count_accum_o_last == 2'b00 ? 2'b01: count_accum_o_last;
        end
        if (count_accum_o_last == 2'b01) begin
            ctr_to_accum_o_last <= ctr_to_accum_o_last + 1;
        end
        if (ctr_to_accum_o_last == K - 4) begin
            acc_o_poly_last <= acc_o_poly[0];
            count_accum_o_last <= 2'b10;
        end
         if (intt_i_valid_d2 && ctr_intt_i_valid == 'b0) begin
            ctr_intt_i_valid <= 2'd2;
            intt_i_poly_dbg <= intt_i_poly[0];
            count_intt_i_poly_last <= count_intt_i_poly_last == 2'b00 ? 2'b01: count_intt_i_poly_last;
        end
        if (count_intt_i_poly_last == 2'b01) begin
            ctr_to_intt_i_last <= ctr_to_intt_i_last + 1;
        end
        if (ctr_to_intt_i_last == K - 4) begin
            intt_i_poly_last <= intt_i_poly[0];
            count_intt_i_poly_last <= 2'b10;
        end
        if (fn_i_valid_d2 && ctr_fn_i_valid == 'b0) begin
            ctr_fn_i_valid <= 2'd2;
            fn_i_poly_dbg <= fn_i_poly_A[0];
            count_fn_i_poly_last <= count_fn_i_poly_last == 2'b00 ? 2'b01: count_fn_i_poly_last;
        end
        if (count_fn_i_poly_last == 2'b01) begin
            ctr_to_fn_i_last <= ctr_to_fn_i_last + 1;
        end
        if (ctr_to_fn_i_last == K - 4) begin
            fn_i_poly_last <= fn_i_poly_A[0];
            count_fn_i_poly_last <= 2'b10;
        end
        if (fn_o_valid_d2 && ctr_fn_o_valid == 'b0) begin
            ctr_fn_o_valid <= 2'd2;
            fn_o_poly_dbg <= fn_o_poly[0];
            count_fn_o_poly_last <= count_fn_o_poly_last == 2'b00 ? 2'b01: count_fn_o_poly_last;
        end
        if (count_fn_o_poly_last == 2'b01) begin
            ctr_to_fn_o_last <= ctr_to_fn_o_last + 1;
        end
        if (ctr_to_fn_o_last == K - 4) begin
            fn_o_poly_last <= fn_o_poly[0];
            count_fn_o_poly_last <= 2'b10;
        end

        if (acc_i_valid_0_d2 && ctr_accum_0_i_valid_4 == 'b0 && ctr_acc_in == 5'd10) begin
            ctr_accum_0_i_valid_4 <= 2'd2;
            acc_i_poly_0_dbg_4 <= acc_i_poly_0[0];
            count_accum_0_4 <= count_accum_0_4 == 2'b00 ? 2'b01: count_accum_0_4;
        end
        if (count_accum_0_4 == 2'b01) begin
            ctr_to_accum_i_0_last_4 <= ctr_to_accum_i_0_last_4 + 1;
        end
        if (ctr_to_accum_i_0_last_4 == K - 4) begin
            acc_i_0_poly_last_4 <= acc_i_poly_0[0];
            count_accum_0_4 <= 2'b10;
        end

        if (acc_i_valid_0_d2 && ctr_accum_0_i_valid_8 == 'b0 && ctr_acc_in == 5'd12) begin
            ctr_accum_0_i_valid_8 <= 2'd2;
            acc_i_poly_0_dbg_8 <= acc_i_poly_0[0];
            count_accum_0_8 <= count_accum_0_8 == 2'b00 ? 2'b01: count_accum_0_8;
        end
        if (count_accum_0_8 == 2'b01) begin
            ctr_to_accum_i_0_last_8 <= ctr_to_accum_i_0_last_8 + 1;
        end
        if (ctr_to_accum_i_0_last_8 == K - 4) begin
            acc_i_0_poly_last_8 <= acc_i_poly_0[0];
            count_accum_0_8 <= 2'b10;
        end

        if (acc_i_valid_0_d2 && ctr_accum_0_i_valid_16 == 'b0 && ctr_acc_in == 5'd14) begin
            ctr_accum_0_i_valid_16 <= 2'd2;
            acc_i_poly_0_dbg_16 <= acc_i_poly_0[0];
            count_accum_0_16 <= count_accum_0_16 == 2'b00 ? 2'b01: count_accum_0_16;
        end
        if (count_accum_0_16 == 2'b01) begin
            ctr_to_accum_i_0_last_16 <= ctr_to_accum_i_0_last_16 + 1;
        end
        if (ctr_to_accum_i_0_last_16 == K - 4) begin
            acc_i_0_poly_last_16 <= acc_i_poly_0[0];
            count_accum_0_16 <= 2'b10;
        end

        if (acc_i_valid_0_d2 && ctr_accum_0_i_valid_20 == 'b0 && ctr_acc_in == 5'd16) begin
            ctr_accum_0_i_valid_20 <= 2'd2;
            acc_i_poly_0_dbg_20 <= acc_i_poly_0[0];
            count_accum_0_20 <= count_accum_0_20 == 2'b00 ? 2'b01: count_accum_0_20;
        end
        if (count_accum_0_20 == 2'b01) begin
            ctr_to_accum_i_0_last_20 <= ctr_to_accum_i_0_last_20 + 1;
        end
        if (ctr_to_accum_i_0_last_20 == K - 4) begin
            acc_i_0_poly_last_20 <= acc_i_poly_0[0];
            count_accum_0_20 <= 2'b10;
        end

        if (acc_i_valid_0_d2 && ctr_accum_0_i_valid_27 == 'b0 && ctr_acc_in == 5'd27) begin
            ctr_accum_0_i_valid_27 <= 2'd2;
            acc_i_poly_0_dbg_27 <= acc_i_poly_0[0];
            count_accum_0_27 <= count_accum_0_27 == 2'b00 ? 2'b01: count_accum_0_27;
        end
        if (count_accum_0_27 == 2'b01) begin
            ctr_to_accum_i_0_last_27 <= ctr_to_accum_i_0_last_27 + 1;
        end
        if (ctr_to_accum_i_0_last_27 == K - 4) begin
            acc_i_0_poly_last_27 <= acc_i_poly_0[0];
            count_accum_0_27 <= 2'b10;
        end
        
    end
end


// data path connections
for (genvar i = 0; i < TP; i = i + 1) begin
    assign ntt_i_psi      [i] = i_p0_data      [i];
    assign ntt_i_poly     [i] = i_p0_data      [i]; 
    assign intt_i_poly    [i] = acc_o_poly     [i];
    assign fifo_0_i_data  [i] = ntt_o_poly_d_0 [i];
    assign fifo_1_i_data  [i] = ntt_o_poly_d_1 [i];
    assign had_0_i_poly_A [i] = fifo_0_o_data  [i];
    assign had_0_i_poly_B [i] = i_p1_data_d    [i];
    assign had_1_i_poly_A [i] = fifo_1_o_data  [i];
    assign had_1_i_poly_B [i] = i_p2_data_d    [i];
    assign acc_i_poly_0   [i] = had_0_o_poly   [i];
    assign acc_i_poly_1   [i] = had_1_o_poly   [i];
    assign fn_i_poly_A    [i] = (EN_ADD) ? fifo_0_o_data[i] : ntt_o_poly_d_0[i];
    assign fn_i_poly_B    [i] = (EN_ADD) ? i_p1_data_d  [i] : {LOGQ{1'b0}};
    assign o_p3_data      [i] = fn_o_poly      [i];
end

// control path connections
assign intt_i_valid = acc_o_valid;

assign fifo_0_wen = ntt_o_valid_d || (EN_ADD && intt_o_valid_d);
assign fifo_1_wen = ntt_o_valid_d;
assign fifo_0_ren = i_p1_valid_d || (EN_ADD && intt_o_valid_d1 && ctr == 0);
assign fifo_1_ren = i_p2_valid_d;

assign had_0_i_valid = i_p1_valid_d1 & ~p1_sel;
assign had_1_i_valid = i_p2_valid_d1;

assign acc_i_valid_0 = had_0_o_valid;
assign acc_i_valid_1 = had_1_o_valid;

assign fn_i_valid = (EN_ADD) ? ((i_p1_valid_d1 & p1_sel)  || (intt_o_valid_d2 && ctr == 0)) : intt_o_valid_d;

assign o_valid = fn_o_valid;


assign acc_start_read  = cu_p0_intt_ready;


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                  //    //    //       //    //  //      //  //  ////// /////  //  //  ///// //  // //   //            //
//                 / //   //    //      / //   //////      ////    //  // //  // //  //  //    //  // //// //            //
//                //////  //    //     //////  //  //      // ///  //  // ////   //  //    //  //  // // ////            //
//               //    // ///// ///// /     // //  //      //   // ////// // /// ////// /////  ////// //  ///            //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////     ///////////////////////////////////////////////////////////////
////////////////////////////////////////////////////            ///////////////////////////////////////////////////////////
//            ////////////////////////////////////    MAIN FSM    //////////////////////////////////////                 //
////////////////////////////////////////////////////            ///////////////////////////////////////////////////////////
///////////////////////////////////////////////////////     ///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                      /////  ///// //     // //   //         ////// //  // /////                                       //
//                      //  // //    //     // //// //         //     ////// //                                          //
//                      ////   ///// //     // // ////         /////  //  // /////                                       //
//                      // /// ///// ////// // //  ///         //     //  // /////                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


typedef enum reg[10:0] {
    ST_IDLE                = 11'b00000000001,
    ST_OP                  = 11'b00000000100,
    ST_WAIT_FN_DONE        = 11'b00000010000,
    ST_WAIT_W_DONE         = 11'b00000100000,
    ST_DONE                = 11'b00001000000,
    ST_LOAD_Q_G1           = 11'b00010000000,
    ST_LOAD_Q_G1_WAIT_DONE = 11'b00100000000,
    ST_LOAD_Q_G2           = 11'b01000000000,
    ST_WAIT_ACC_O_VALID    = 11'b10000000000
} t_state;


(* fsm_encoding = "none" *) t_state state;
t_state next_state;

wire [LOGL-1:0] ctr;
reg  ctr_inc;
reg  ctr_rst;
wire acc_o_valid_d;
wire fn_i_done_d;
wire done_write_d;


counter #(
    .WIDTH   (LOGL),
    .AUTO_INC(0   )
) ctr_L_inst (
    .clk(clk),
    .rst(rst | ctr_rst),
    .inc(ctr_inc),
    .ctr(ctr)
);


always @(posedge clk) begin
    if (rst) begin
        state <= ST_IDLE;
    end
    else begin
        state <= next_state;
    end
end


shift_reg #(
    .LAT   (MAIN_FSM__CU_ACC__DELAY),
    .WIDTH (1)
) acc_o_valid_sr (
    .clk    (clk    ),
    .rst    (rst    ),
    .i_data (acc_o_valid),
    .o_data (acc_o_valid_d)
);


shift_reg #(
    .LAT   (MAIN_FSM__FN__DELAY),
    .WIDTH (1)
) fn_i_done_sr (
    .clk    (clk    ),
    .rst    (rst    ),
    .i_data (fn_i_done),
    .o_data (fn_i_done_d)
);


shift_reg #(
    .LAT   (MAIN_FSM__CU_OUT___DELAY),
    .WIDTH (1)
) write_done_sr (
    .clk    (clk    ),
    .rst    (rst    ),
    .i_data (done_write),
    .o_data (done_write_d)
);


always @(*) begin

    load_q_g1 = 0;
    load_q_g2 = 0;

    next_state = state;

    cu_p0_start  = 0;

    ctr_rst = 0;
    ctr_inc = 0;

    done = 0;
    p1_sel = 0;

    case (state)
        ST_IDLE: begin
            ctr_rst = 1;
            if (start) begin
                next_state = ST_LOAD_Q_G1;
            end
        end
        ST_LOAD_Q_G1: begin
            load_q_g1 = 1;
            next_state = ST_OP;
        end
        ST_LOAD_Q_G1_WAIT_DONE: begin
            if (load_q_g1_d) begin
                next_state = ST_OP;
            end
            else begin
                next_state = ST_LOAD_Q_G1_WAIT_DONE;
            end
        end
        ST_OP: begin
            cu_p0_start = 1;
            next_state = ST_WAIT_ACC_O_VALID;
        end        
        ST_WAIT_ACC_O_VALID: begin
            if (acc_o_valid_d) begin
                next_state = ST_LOAD_Q_G2;
            end
        end
        ST_LOAD_Q_G2: begin
            p1_sel = 1;
            load_q_g2 = 1;
            if (ctr == 0) begin
                next_state = ST_WAIT_FN_DONE;                
            end
            else begin
                next_state = ST_WAIT_W_DONE;
            end
        end
        ST_WAIT_FN_DONE: begin
            p1_sel = 1;
            if (fn_i_done_d) begin
                ctr_inc = 1;
                next_state = ST_LOAD_Q_G1;
            end
        end
        ST_WAIT_W_DONE: begin
            p1_sel = 1;
            if (done_write_d) begin
                if (ctr == L) begin
                    next_state = ST_DONE;
                end
                else begin
                    ctr_inc = 1;
                    next_state = ST_LOAD_Q_G1;
                end
            end
        end
        ST_DONE: begin
            done = 1;
            next_state = ST_IDLE;
        end
    endcase
end

always @(posedge clk) begin
    if (rst)
        relin_dbg_state <= ST_IDLE;
    else
        relin_dbg_state <= state;
end


endmodule